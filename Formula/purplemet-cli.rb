class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.15"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.15/purplemet-cli-darwin-arm64"
      sha256 "9982cf3b3ee4b5f016787806a80093c6a025bca9faf1f0c7213d75e0cdbaf897"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.15/purplemet-cli-darwin-amd64"
      sha256 "230602f69b8164dc267678805c4e314a193f811e568bf79a59dfee134774fdc3"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.15/purplemet-cli-linux-arm64"
      sha256 "b0a783169206d97d8336fd453918470a887a00c6eae74f9d432b5ff5b87d0bab"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.15/purplemet-cli-linux-amd64"
      sha256 "2dc236497ba7e2bbed526c10beede78ea789fdb2dcf45e01a91f42b894453183"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.15/completions.tar"
    sha256 "97e220c6b30f36c937444929d91227a09228e30841beb8c09008921b6b8618c3"
  end

  def install
    binary = Dir["purplemet-cli-*"].first || "purplemet-cli"
    bin.install binary => "purplemet-cli"

    resource("completions").stage do
      bash_completion.install "purplemet-cli.bash"
      zsh_completion.install  "_purplemet-cli"
      fish_completion.install "purplemet-cli.fish"
    end
  end

  test do
    assert_match "purplemet-cli", shell_output("#{bin}/purplemet-cli version")
  end
end
