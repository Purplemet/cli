# Purplemet CLI

This repository hosts the public release binaries, installation script, and Homebrew formula for **Purplemet CLI**, a command-line tool for running web application security analyses via the [Purplemet](https://purplemet.com) platform.

The source code is maintained on a separate GitLab repository and will be made public soon.

> 🛡️ **New to Purplemet?** It's an Attack Surface Management platform — discover your web assets, scan them for vulnerabilities, and track your security posture over time. Dive into the [official documentation](https://cloud.purplemet.com/docs/) to learn more, or explore the [API reference](https://api.purplemet.com/).

## Installation

### Binary (Linux / macOS / Windows)

```bash
curl -sSL https://github.com/Purplemet/cli/releases/latest/download/install.sh | sh
```

Or download the binary directly from [Releases](https://github.com/Purplemet/cli/releases).

### Homebrew (macOS / Linux)

```bash
brew tap purplemet/cli https://github.com/Purplemet/cli.git
brew install purplemet-cli
```

### Docker

```bash
docker run --rm -e PURPLEMET_API_TOKEN=<token> ppmsupport/purplemet-cli analyze https://your-app.com
```

## Documentation

- **CLI documentation:** [Wiki](https://github.com/Purplemet/cli/wiki) — full guides, configuration, exit codes, CI/CD integrations
- **Platform documentation:** [cloud.purplemet.com/docs](https://cloud.purplemet.com/docs/)
- **API reference:** [api.purplemet.com](https://api.purplemet.com/)
- Run `purplemet-cli --help` for command usage.
