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
