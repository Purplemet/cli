class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.22"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.22/purplemet-cli-darwin-arm64"
      sha256 "e168e61f7dea5f40a6af75e4db962afbf04454ff7cddbc8e1b3837fa1d3e7d7c"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.22/purplemet-cli-darwin-amd64"
      sha256 "ab2ce5b8836f366f946958454fd07db0346342f37d27867f09284ca3b8f7cfe8"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.22/purplemet-cli-linux-arm64"
      sha256 "6d5da5b05bfb7f7cb6cd13b0eafaa603a85d2fc7f33227d65d1ea988ad95a3c9"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.22/purplemet-cli-linux-amd64"
      sha256 "18d3ecfb55f99fb505ae19a3a168ee9f8b0829e5c6571a44435881085c57c162"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.22/completions.tar"
    sha256 "97e220c6b30f36c937444929d91227a09228e30841beb8c09008921b6b8618c3"
  end

  resource "man" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.22/man.tar"
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
