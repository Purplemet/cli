class PurplemetCli < Formula
  desc "CLI for Purplemet web application security analysis"
  homepage "https://purplemet.com"
  version "1.1.12"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.12/purplemet-cli-darwin-arm64"
      sha256 "92cc0d8173f677f768903ffcc1129e3d49d9fb900feae6034925a014f87b0408"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.12/purplemet-cli-darwin-amd64"
      sha256 "fd4660248e6116fdd929c3eef7d9f04e1a09650ba35dd6f3432499f5fb4356c7"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Purplemet/cli/releases/download/v1.1.12/purplemet-cli-linux-arm64"
      sha256 "210322c5579598ce78eeff4fda4601a5eda229bd4e934520b37ecda2be67e9ca"
    else
      url "https://github.com/Purplemet/cli/releases/download/v1.1.12/purplemet-cli-linux-amd64"
      sha256 "69eed1e598f3c65dab488db65729f39d615d946797f21666e460d650dc052171"
    end
  end

  def install
    binary = Dir["purplemet-cli-*"].first || "purplemet-cli"
    bin.install binary => "purplemet-cli"

    generate_completions_from_executable(bin/"purplemet-cli", "completion")
  end

  test do
    assert_match "purplemet-cli", shell_output("#{bin}/purplemet-cli version")
  end
end
