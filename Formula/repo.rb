# Custom downloader for private repo.
class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    parse_url_pattern(url)
    super
  end
  def parse_url_pattern(url)
    url_pattern = %r{https://github.com/([^/]+)/([^/]+)/releases/download/([^-]+)-([0-9.]+)(\.arm\S+)}
    unless url =~ url_pattern
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub Release."
    end
    _, @owner, @repo, pkg, version, filename = *url.match(url_pattern)
    @tag = "v#{version}"
    @filename = "#{pkg}--#{version}#{filename}"
  end
  def download_url
    "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}"
  end
  private
  def _fetch(url:, resolved_url:, timeout:)
    # HTTP request header `Accept: application/octet-stream` is required.
    # Without this, the GitHub API will respond with metadata, not binary.
    curl_download download_url, "--header", "Accept: application/octet-stream", "--header", "Authorization: Bearer #{GitHub::API.credentials}", to: temporary_path, timeout: timeout
  end
  def asset_id
    @asset_id ||= resolve_asset_id
  end
  def resolve_asset_id
    release_assets = fetch_release_assets
    assets = release_assets.select { |a| a["name"] == @filename }
    raise CurlDownloadStrategyError, "Asset file not found." if assets.empty?
    assets.first["id"]
  end
  def fetch_release_assets
    GitHub.get_release(@owner, @repo, @tag).fetch("assets")
  end
end

