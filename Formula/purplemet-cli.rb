class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.17"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.17/purplemet-cli-darwin-arm64"
      sha256 "30d740940ffe21fe7695522b61b6677f8bb8f971c070bce69d816758a74c7ca4"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.17/purplemet-cli-darwin-amd64"
      sha256 "1cfe4285be4fa0af1477a2f96940edde05dc202f2f94572d15f0c516a84df594"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.17/purplemet-cli-linux-arm64"
      sha256 "35d8548d0b03e30985a655a1c17b7ba714cf3c9ff1aa371fbd95f1634284cf1f"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.17/purplemet-cli-linux-amd64"
      sha256 "1be4eaa1c08b008d86c48f628b0bae147db66c55d5df1371e2dbb4ee5340440f"
    end
  end

  resource "completions" do
    url "https://github.com/Purplemet/cli/releases/download/v1.1.17/completions.tar"
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
