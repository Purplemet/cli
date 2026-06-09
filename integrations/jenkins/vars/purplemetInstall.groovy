/**
 * Install Purplemet CLI binary.
 *
 * Loads install.sh from the shared library resources/ directory
 * and runs purplemet_install().
 *
 * Usage:
 *   purplemetInstall(version: 'latest')
 *   purplemetInstall(version: 'v1.0.0')
 */
def call(Map config = [:]) {
    def version = config.get('version', 'latest')

    // Validate version format to prevent shell injection
    if (version != 'latest' && !(version ==~ /^v?\d+\.\d+\.\d+$/)) {
        error("Invalid version format '${version}': expected 'latest' or 'vX.Y.Z'")
    }

    // Skip install when the binary is already on PATH (e.g. Docker agent
    // using ppmsupport/purplemet-cli image, or host agent with CLI pre-installed).
    // Also check ~/.local/bin where a previous run may have fallen back to.
    def alreadyInstalled = sh(
        script: 'command -v purplemet-cli >/dev/null 2>&1 || [ -x "$HOME/.local/bin/purplemet-cli" ]',
        returnStatus: true
    ) == 0
    if (alreadyInstalled) {
        echo "purplemet-cli already installed, skipping install"
        return
    }

    def installScript = libraryResource('install.sh')
    writeFile file: '/tmp/purplemet-install.sh', text: installScript
    sh "chmod +x /tmp/purplemet-install.sh"

    withEnv(["PURPLEMET_CLI_VERSION=${version}"]) {
        sh '''#!/bin/bash
            set -e
            source /tmp/purplemet-install.sh
            purplemet_install
        '''
    }
}
