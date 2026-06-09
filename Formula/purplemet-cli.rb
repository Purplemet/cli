class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.0.0"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.0.0/purplemet-cli-darwin-arm64"
      sha256 "7e73e0b517ac98ed69d4e9cf97a10a05adf7ba92c5cc89295741c20fed3ff4fc"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.0.0/purplemet-cli-darwin-amd64"
      sha256 "f331d712a51a447039af6c2c1fc07c3c3cbece262d83f7b08450dff16da2a769"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.0.0/purplemet-cli-linux-arm64"
      sha256 "e547bf95f4f6df1a6745646fa491f0f85389c08a4018e128562d3bd1ea642880"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.0.0/purplemet-cli-linux-amd64"
      sha256 "550b565968d8c6d6586f8aa2499a85f08b95c04cb6f39997661ea7d4834b37df"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.0.0/completions.tar"
    sha256 "97e220c6b30f36c937444929d91227a09228e30841beb8c09008921b6b8618c3"
  end

  resource "man" do
    url "https://github.com/Purplemet/cli/releases/download/v1.0.0/man.tar"
    sha256 "9f6b661a7b43009ca947f91d0c3bc224f9c68aefad06e7360abe35cb23ce01d2"
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
