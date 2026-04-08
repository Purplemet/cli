# Purplemet CLI

This repository hosts the public release binaries and installation script for **Purplemet CLI**, a command-line tool for running web application security analyses via the [Purplemet](https://purplemet.com) platform.

> The source code is maintained on a separate GitLab repository and will be made public soon.

## Installation

### Binary

Download the latest binary for your platform from [Releases](https://github.com/purplemet/cli/releases).

### Docker

```bash
docker run --rm -e PURPLEMET_API_TOKEN=<token> ppmsupport/purplemet-cli analyze https://your-app.com
```

## Documentation

See [purplemet.com](https://purplemet.com) for full documentation.
