# Homebrew Formula for pybinary
# We need a customer downloader to use github release assets from our private repos
require_relative 'repo.rb'

class Pybinary < Formula
  include Language::Python::Virtualenv

  desc "Epic CLI tool"
  homepage ""
  url "https://github.com/my_org_name/pybinary_repo.git",
    branch: "main",
    tag: "v1.0"

  license ""

  depends_on "python@3.12"
  depends_on "rust" => :build
  depends_on "python-setuptools" => :build

  bottle do
    root_url "https://github.com/my_org_name/pybinary_repo/releases/download",
      using: GitHubPrivateRepositoryReleaseDownloadStrategy
    sha256 cellar: :any, arm64_sonoma: "4a922d718e7e616ab4f59eb4615ec78d2b70c96d4b737d4c2a1d8e5df716d675"
  end

  eval(IO.read(File.join(File.expand_path(File.dirname(__FILE__)), 'resources.rb')))

  def install
    # Handle changes to clang / xcode paths in most recent xcode update.
    # Without this, grpcio fails to build due to missing cstddef inclue.
    ENV.append_to_cflags "-I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/c++/v1"
    virtualenv_install_with_resources
  end

  test do
    # Not needed
    system "false"
  end
end

