
ORG = "my_org_name"
REPO = "pybinary_repo"

cask "pybinary" do

  # Update version and sha256 to release a new Cask
  version "1.0"
  sha256 "cbeafe76301d2f814487ee6631bc0cbf0708d90034c8a3ab3b8be7a0840aa029"

  depends_on formula: "gh"

  url do
    assets = GitHub.get_release(ORG, REPO, "v#{version}").fetch("assets")
    zip_url = assets.find{|a| a["name"] == "pybinary-#{version}.zip"}.fetch("url")
    [zip_url, header: [
      "Accept: application/octet-stream",
      "Authorization: bearer #{GitHub::API.credentials}"
    ]]
  end
  name "pybinary"
  desc "Epic CLI tool"
  homepage ""

  # Documentation: https://docs.brew.sh/Brew-Livecheck
  livecheck do
    url "https://github.com/#{ORG}/#{REPO}/releases"
  end


  binary "pybinary-#{version}/pybinary"

  caveats do
    "Please run 'xattr -r -d com.apple.quarantine #{staged_path}' to remove the quarantine flag"
  end

  postflight do
    ohai "Removing quarantine flag"
    system_command "/usr/bin/xattr", args: ["-r", "-d", "com.apple.quarantine", staged_path]
    ohai "Unpacking the PyBinary CLI tool"
    system_command "#{staged_path}/pybinary-#{version}/pybinary", args: ["--version"]
  end
  # Documentation: https://docs.brew.sh/Cask-Cookbook#stanza-zap
  zap trash: ""
end
