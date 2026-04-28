class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.16"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.16/purplemet-cli-darwin-arm64"
      sha256 "1cfc3113b37cddd992a5c1f4fe86decdd1a64a82b03c4117365d6c97c72c3da8"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.16/purplemet-cli-darwin-amd64"
      sha256 "5ac0309c2b5207b941bf169c0c51cf849100b358bca63273bade3196473e2a8a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.16/purplemet-cli-linux-arm64"
      sha256 "c50f2d9109eacc7a986560f864a2c4f4d7ab80010338886fe180b035a2c7d8bd"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.16/purplemet-cli-linux-amd64"
      sha256 "33a8f6daaffa0732c11ffbde90af37e2d04d2bd3da97f297ede47579be9c2c80"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.16/completions.tar"
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
