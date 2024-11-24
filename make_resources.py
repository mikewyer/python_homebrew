from pathlib import Path
from subprocess import run
from rich.console import Console
import typer

app = typer.Typer()
console = Console()

@app.command()
def brew_resources(file: Optional[Path] = None, output: Optional[Path] = None) -> None:
    """Outputs brew resource stanzas from requirements.txt."""
    if file is None:
        subprocess.run(["make", "requirements.txt"], check=True)
        file = Path("requirements.txt")
    if output is None:
        output = FORMULA_DIR / "resources.rb"
    pypi_base_url = "https://pypi.org/pypi"
    seen = set()
    resource_blocks = []
    with open(file, "r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()
            if line.startswith("-e") or line.startswith("#") or line == "":
                continue
            while line.endswith("\\"):
                line += next(file).strip()
            if ";" in line:
                pkg_spec, constraints = line.split(" ; ", 1)
            else:
                pkg_spec, constraints = line, ""
            try:
                pkg_name, pkg_version = pkg_spec.split("==")
            except ValueError:
                errs.print(f"Skipping invalid line: {line}")
                continue
            # Ignore package extras
            if "[" in pkg_name:
                pkg_name, *_ = pkg_name.split("[")
            if pkg_name in seen:
                continue
            seen.add(pkg_name)

            pkg_info_url = f"{pypi_base_url}/{pkg_name}/{pkg_version}/json"
            response = requests.get(pkg_info_url, timeout=10)

            if response.status_code != 200:
                errs.print(f"Failed to fetch package info for {pkg_name}=={pkg_version} using {pkg_info_url}")
                continue

            pkg_info = response.json()
            selected_url = ""
            # I prefer the pre-built wheels, especially for google client code.
            # The sdist tar.gz files can be huge, and I'm trying for a quick, simple, repeatable build.
            for suffix in ["-none-any.whl", ".tar.gz"]:
                selected_url = next(
                    (
                        url_info
                        for url_info in pkg_info["urls"]
                        if url_info["url"].endswith(suffix) and url_info["digests"]["sha256"] in constraints
                    ),
                    None,
                )
                if selected_url:
                    break
            if not selected_url:
                errs.print(f"No distribution found for {pkg_name}=={pkg_version}")
                continue

            download_url = selected_url["url"]
            sha256 = selected_url["digests"]["sha256"]

            resource_block = (
                f'resource "{pkg_name}" do\n' f'  url "{download_url}"\n' f'  sha256 "{sha256}"\n' "end\n\n"
            )

            resource_blocks.append(resource_block)
    with open(output, "w", encoding="utf-8") as outfh:
        outfh.writelines(resource_blocks)
    console.print(f"{len(resource_blocks)} resources written to {output}")
