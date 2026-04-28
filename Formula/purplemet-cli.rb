class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.14"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.14/purplemet-cli-darwin-arm64"
      sha256 "ed1c5c80e6625b0e52cd9969712724ddf91c4d97e7b43e29cf970bf601650c25"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.14/purplemet-cli-darwin-amd64"
      sha256 "3a1ba2cdb6e6f9dd65f05f760ee6908281ec1a1fd6f09d431518c24407f9f959"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.14/purplemet-cli-linux-arm64"
      sha256 "15de1912e498439a5821f4765814111901fb332fb0c054c8d441ebc715ac3c59"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.14/purplemet-cli-linux-amd64"
      sha256 "4c8121b3dd71117629f3b579ab553a1854fc581678503400880270cd40a98e86"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.14/completions.tar"
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
