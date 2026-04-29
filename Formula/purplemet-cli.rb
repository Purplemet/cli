class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.20"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.20/purplemet-cli-darwin-arm64"
      sha256 "1339dbf1cb6b223c382dc0d08cbc0e28421a7a8d8fce2bf1046ebbb11fd5915c"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.20/purplemet-cli-darwin-amd64"
      sha256 "1277e60a834b471c1736cde37948363e65102aea7ab10c95f72aff6704002008"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.20/purplemet-cli-linux-arm64"
      sha256 "79e9aedc811fd64444bdc2c1b3b7f668c893bbcaf7b20168e0de2ea153464a05"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.20/purplemet-cli-linux-amd64"
      sha256 "7f162c6e17947e0109a5df83e810c10e6586dc28ba155cbbf378ad89a64d08f1"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.20/completions.tar"
    sha256 "97e220c6b30f36c937444929d91227a09228e30841beb8c09008921b6b8618c3"
  end

  resource "man" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.20/man.tar"
    sha256 "c81b5737d74ef8a03e6bc6098c8f93a4f1ab6839d46c0635eb1480035e309b96"
  end

  def install
    binary = Dir["purplemet-cli-*"].first || "purplemet-cli"
    bin.install binary => "purplemet-cli"

    resource("completions").stage do
      bash_completion.install "purplemet-cli.bash"
      zsh_completion.install  "_purplemet-cli"
      fish_completion.install "purplemet-cli.fish"
    end

    resource("man").stage do
      man1.install Dir["*.1"]
    end
  end

  test do
    assert_match "purplemet-cli", shell_output("#{bin}/purplemet-cli version")
  end
end
