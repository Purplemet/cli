class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.21"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.21/purplemet-cli-darwin-arm64"
      sha256 "2c122f9f51b2664576efc5929df2f1369e143c83ce34c0aee529b74099dd85ef"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.21/purplemet-cli-darwin-amd64"
      sha256 "14ba3195404229d8ab017c2e22bf49e6428b017b5f040f897c04270d7ac3bb0e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.21/purplemet-cli-linux-arm64"
      sha256 "a6aafa4f0df7242ed3606e91edebbcddddb90dba253fae33cede1608e6c5ae75"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.21/purplemet-cli-linux-amd64"
      sha256 "d15ae7037f01dea6d2c48c7c3c7679e5646220f0763c50eea4e34663b35be9bd"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.21/completions.tar"
    sha256 "97e220c6b30f36c937444929d91227a09228e30841beb8c09008921b6b8618c3"
  end

  resource "man" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.21/man.tar"
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
