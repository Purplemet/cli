# Purplemet Jenkins Integration

Purplemet: Proactive Web Attack Surface Management. Discover real-time security insights with Purplemet's Web ASM platform.

Shared library providing `purplemetAnalyze` and `purplemetInstall` pipeline steps for Jenkins.

## Quick Start

```groovy
@Library('purplemet') _

pipeline {
    agent any
    stages {
        stage('Security Analysis') {
            steps {
                purplemetAnalyze(
                    url: 'https://your-app.example.com',
                    token: 'PURPLEMET_API_TOKEN',
                    failSeverity: 'high'
                )
            }
        }
    }
}
```

## Prerequisites

1. **Create a Purplemet API token** at [cloud.purplemet.com](https://cloud.purplemet.com/#/tokens/create)
2. **Add a Jenkins credential:**
   - Go to **Manage Jenkins** → **Credentials**
   - Add a **Secret text** credential
   - ID: `PURPLEMET_API_TOKEN`
3. **Install the shared library** (see below)

## Installation

1. Go to **Manage Jenkins** → **System** → scroll to **Global Trusted Pipeline Libraries**
2. Click **Add** and configure:
   - **Name**: `purplemet`
   - **Default version**: `main`
   - **Retrieval method**: Modern SCM → Git
   - **Project Repository**: `https://github.com/Purplemet/cli.git`
   - **Library Path**: `integrations/jenkins`
3. Optionally check **Load implicitly** for automatic availability

## Usage

### Declarative Pipeline

```groovy
@Library('purplemet') _

pipeline {
    agent any
    stages {
        stage('Security Analysis') {
            steps {
                purplemetAnalyze(
                    url: 'https://your-app.example.com',
                    token: 'PURPLEMET_API_TOKEN',
                    failSeverity: 'high'
                )
            }
        }
    }
}
```

### Scripted Pipeline

```groovy
@Library('purplemet') _

node {
    stage('Security Analysis') {
        purplemetAnalyze(
            url: 'https://your-app.example.com',
            token: 'PURPLEMET_API_TOKEN',
            failSeverity: 'medium',
            timeout: '600000'
        )
    }
}
```

### Without Shared Library (Direct CLI)

Uses the shared `install.sh` and `analyze.sh` scripts for consistent behavior across all platforms:

```groovy
pipeline {
    agent any
    stages {
        stage('Security Analysis') {
            environment {
                PURPLEMET_TARGET_URL = 'https://your-app.com'
                PURPLEMET_FAIL_SEVERITY = 'high'
            }
            steps {
                withCredentials([string(credentialsId: 'PURPLEMET_API_TOKEN', variable: 'PURPLEMET_API_TOKEN')]) {
                    sh '''
                        curl -sSLf https://github.com/purplemet/cli/releases/latest/download/install.sh -o /tmp/install.sh
                        curl -sSLf https://github.com/purplemet/cli/releases/latest/download/analyze.sh -o /tmp/analyze.sh
                        chmod +x /tmp/install.sh /tmp/analyze.sh
                        source /tmp/install.sh && purplemet_install
                        /tmp/analyze.sh
                    '''
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'purplemet-report.json', allowEmptyArchive: true
        }
    }
}
```

> **Note:** When using the CLI directly (without the shared library), exit code 1 (threshold exceeded) will cause the build to **FAIL** instead of **UNSTABLE**. To get `UNSTABLE` behavior, use `returnStatus: true` and handle the exit code manually, or use the shared library.

All `PURPLEMET_*` variables from the [CONVENTIONS](https://dev.purplemet.com/purplemet/integrations/cli/-/blob/main/integrations/CONVENTIONS.md) are supported in the `environment` block.

## Parameters

All parameters are passed as named arguments to `purplemetAnalyze(...)`.

### Core configuration

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `url` | **Yes** | — | URL of the web application to analyze |
| `token` | No | `PURPLEMET_API_TOKEN` | Jenkins credential ID for the API token |
| `baseUrl` | No | — | API base URL override (e.g. `https://api.dev.purplemet.com`) |
| `version` | No | `latest` | CLI version to install (e.g. `v1.0.10`, `latest`) |
| `timeout` | No | `'300000'` | Polling timeout in milliseconds (0 = unlimited) |
| `format` | No | `'json'` | Output format: `json`, `human`, `sarif`, `html` |
| `noCreate` | No | `false` | Do not auto-create site if URL not found |

### Severity gates

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failSeverity` | `'high'` | Fail if issues at or above this severity: `critical`, `high`, `medium`, `low`, `info` |
| `failRating` | — | Fail if rating is at or below this grade (`A`-`F`) |
| `failOnIssueCount` | `'0'` | Fail if total issue count >= this value |
| `excludeIgnored` | `false` | Exclude ignored issues from gate evaluation |

### CVE / exploitability gates

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failCvss` | `'0'` | Fail if any CVE has CVSS score >= this value (e.g. `'9.0'`) |
| `failOnKev` | `false` | Fail if CISA Known Exploited Vulnerabilities are detected |
| `failOnEpss` | `'0'` | Fail if any issue has EPSS score >= this value (`0.0`-`1.0`) |
| `failOnActiveExploits` | `false` | Fail if actively exploited vulnerabilities are detected |

### Component / technology gates

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failOnEol` | `false` | Fail if end-of-life components are detected |
| `failOnUnsafe` | `false` | Fail if unsafe component issues are detected |
| `failOnOssfScore` | `'0'` | Fail if any technology has OpenSSF Scorecard score below this value (`0`-`10`) |
| `excludeTech` | — | Fail if specified technologies are detected (comma-separated) |

### SSL / certificate gates

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failOnSsl` | `false` | Fail if SSL/TLS protocol issues are detected |
| `failOnCert` | `false` | Fail if certificate issues are detected |
| `failOnCertExpiry` | `'0'` | Fail if certificate expires within N days |

### HTTP / web configuration gates

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failOnHeaders` | `false` | Fail if HTTP security header issues are detected (CSP, HSTS, X-Frame-Options) |
| `failOnCookies` | `false` | Fail if insecure cookie issues are detected (HttpOnly, Secure, SameSite) |
| `requireWaf` | `false` | Fail if no WAF is detected |
| `failOnSensitiveServices` | `false` | Fail if sensitive services are exposed on the site IP |

> **Note:** When using the shared library, pass security gates as `purplemetAnalyze()` parameters (not `environment` variables). The `environment` block approach only works with the "Without Shared Library" method, where you set the equivalent `PURPLEMET_*` env vars instead.

## Exit Codes

| Code | Meaning | Jenkins Build Status |
|------|---------|---------------------|
| 0 | No issues above threshold | **SUCCESS** |
| 1 | Issues found above threshold | **UNSTABLE** |
| 2 | Analysis error | **FAILURE** |
| 3 | Timeout | **FAILURE** |
| 4 | Network/API error | **FAILURE** |
| 5 | Usage error (bad arguments) | **FAILURE** |
| 6 | API contract error | **FAILURE** |

## Artifacts

The analysis report is saved as `purplemet-report.json` and archived as a build artifact.

## Complete Example

```groovy
@Library('purplemet') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps { sh 'make build' }
        }
        stage('Deploy Staging') {
            steps { sh './deploy.sh staging' }
        }
        stage('Security Analysis') {
            steps {
                purplemetAnalyze(
                    url: 'https://staging.example.com',
                    failSeverity: 'high',
                    timeout: '600000',
                    failOnEol: true,
                    failOnKev: true,
                    failOnSsl: true,
                    requireWaf: true
                )
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'purplemet-report.json', allowEmptyArchive: true
        }
    }
}
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| `PURPLEMET_API_TOKEN is not set` | Add a Secret text credential with ID `PURPLEMET_API_TOKEN` |
| `curl: command not found` | Install curl on the agent, or use a Docker agent |
| `Library 'purplemet' not found` | Configure the shared library in Manage Jenkins → Configure System |
| `Rating: N/A` in summary | Install `jq` on the agent (`apt-get install jq`) for full result parsing |
| Timeout (exit code 3) | Increase `timeout` parameter (e.g. `'600000'` for 10 min) |
| Network error (exit code 4) | Check agent can reach `api.purplemet.com` on port 443 |

## Documentation

See the full [Jenkins integration guide](https://dev.purplemet.com/purplemet/integrations/cli/-/blob/main/docs/integrations/jenkins.md) for advanced examples, security gates, and detailed troubleshooting.

## License

Proprietary — Purplemet SAS
