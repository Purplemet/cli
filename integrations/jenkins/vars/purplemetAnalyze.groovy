/**
 * Run a Purplemet security analysis.
 *
 * All analysis logic (argument building, execution, result parsing) is delegated
 * to the shared analyze.sh script. This Groovy wrapper handles Jenkins-specific
 * concerns: credential injection, environment mapping, and build status.
 *
 * Usage:
 *   purplemetAnalyze(
 *       url: 'https://your-app.example.com',
 *       token: 'PURPLEMET_API_TOKEN',       // Jenkins credential ID
 *       failSeverity: 'high',               // optional
 *       failRating: '',                      // optional (A-F)
 *       failCvss: '0',                       // optional (e.g. '9.0')
 *       failOnEol: false,                    // optional
 *       failOnSsl: false,                    // optional
 *       failOnCert: false,                   // optional
 *       excludeTech: '',                     // optional (comma-separated)
 *       excludeIgnored: false,               // optional
 *       failOnHeaders: false,                // optional — HTTP security headers (CSP, HSTS)
 *       failOnCookies: false,                // optional — insecure cookies
 *       failOnUnsafe: false,                 // optional — unsafe components
 *       failOnKev: false,                    // optional — CISA KEV
 *       failOnEpss: '0',                     // optional — EPSS score threshold (0.0-1.0)
 *       failOnActiveExploits: false,         // optional — actively exploited vulns
 *       failOnOssfScore: '0',               // optional — OpenSSF Scorecard threshold (0-10)
 *       failOnCertExpiry: '0',              // optional — fail if cert expires within N days
 *       failOnIssueCount: '0',              // optional — fail if issue count >= threshold
 *       requireWaf: false,                   // optional — fail if no WAF detected
 *       failOnSensitiveServices: false,      // optional — fail if sensitive services exposed
 *       format: 'json',                      // optional — output format: json, human, sarif, html
 *       noCreate: false,                     // optional — don't auto-create site if URL not found
 *       timeout: '1800000',                  // optional, ms (default 30 min)
 *       version: 'latest',                   // optional
 *       baseUrl: '',                         // optional, API base URL override
 *       basicUser: '',                       // optional, HTTP Basic Auth user (dev API)
 *       basicPass: ''                        // optional, HTTP Basic Auth pass (dev API)
 *   )
 */
def call(Map config = [:]) {
    def targetUrl = config.get('url', '')
    def tokenCredId = config.get('token', 'PURPLEMET_API_TOKEN')
    def version = config.get('version', 'latest')

    if (!targetUrl) {
        error "purplemetAnalyze: 'url' parameter is required"
    }

    // Install CLI
    purplemetInstall(version: version)

    // Map Groovy config to PURPLEMET_* env vars for analyze.sh.
    // Prepend ~/.local/bin to PATH so analyze.sh finds purplemet-cli when
    // install fell back there (no sudo + /usr/local/bin not writable).
    // This is a no-op when the binary is in /usr/local/bin or already on PATH.
    def envVars = [
        "PATH=${env.HOME}/.local/bin:${env.PATH}",
        "PURPLEMET_TARGET_URL=${targetUrl}",
        "PURPLEMET_FAIL_SEVERITY=${config.get('failSeverity', 'high')}",
        "PURPLEMET_WAIT_TIMEOUT=${config.get('timeout', '1800000')}",
        "PURPLEMET_FORMAT=${config.get('format', 'json')}",
        "PURPLEMET_FAIL_RATING=${config.get('failRating', '')}",
        "PURPLEMET_FAIL_CVSS=${config.get('failCvss', '0')}",
        "PURPLEMET_FAIL_ON_EOL=${config.get('failOnEol', false)}",
        "PURPLEMET_FAIL_ON_SSL=${config.get('failOnSsl', false)}",
        "PURPLEMET_FAIL_ON_CERT=${config.get('failOnCert', false)}",
        "PURPLEMET_EXCLUDE_TECH=${config.get('excludeTech', '')}",
        "PURPLEMET_EXCLUDE_IGNORED=${config.get('excludeIgnored', false)}",
        "PURPLEMET_FAIL_ON_HEADERS=${config.get('failOnHeaders', false)}",
        "PURPLEMET_FAIL_ON_COOKIES=${config.get('failOnCookies', false)}",
        "PURPLEMET_FAIL_ON_UNSAFE=${config.get('failOnUnsafe', false)}",
        "PURPLEMET_FAIL_ON_KEV=${config.get('failOnKev', false)}",
        "PURPLEMET_FAIL_ON_EPSS=${config.get('failOnEpss', '0')}",
        "PURPLEMET_FAIL_ON_ACTIVE_EXPLOITS=${config.get('failOnActiveExploits', false)}",
        "PURPLEMET_FAIL_ON_OSSF_SCORE=${config.get('failOnOssfScore', '0')}",
        "PURPLEMET_FAIL_ON_CERT_EXPIRY=${config.get('failOnCertExpiry', '0')}",
        "PURPLEMET_FAIL_ON_ISSUE_COUNT=${config.get('failOnIssueCount', '0')}",
        "PURPLEMET_REQUIRE_WAF=${config.get('requireWaf', false)}",
        "PURPLEMET_FAIL_ON_SENSITIVE_SERVICES=${config.get('failOnSensitiveServices', false)}",
        "PURPLEMET_NO_CREATE=${config.get('noCreate', false)}",
    ]

    def baseUrl = config.get('baseUrl', '')
    if (baseUrl) {
        envVars.add("PURPLEMET_BASE_URL=${baseUrl}")
    }

    def basicUser = config.get('basicUser', '')
    def basicPass = config.get('basicPass', '')
    if (basicUser) {
        envVars.add("PPM_CLOUD_UI_BASIC_USER=${basicUser}")
    }
    if (basicPass) {
        envVars.add("PPM_CLOUD_UI_BASIC_PASS=${basicPass}")
    }

    // Load analyze.sh from shared library resources
    def analyzeScript = libraryResource('analyze.sh')
    writeFile file: '/tmp/purplemet-analyze.sh', text: analyzeScript
    sh "chmod +x /tmp/purplemet-analyze.sh"

    // Derive report filename from the configured format so archiveArtifacts
    // picks up the right file when format != 'json'.
    def format = config.get('format', 'json')
    def ext
    switch (format) {
        case 'sarif': ext = 'sarif'; break
        case 'html':  ext = 'html';  break
        case 'human': ext = 'txt';   break
        default:      ext = 'json'
    }
    def reportFile = "purplemet-report.${ext}"

    withCredentials([string(credentialsId: tokenCredId, variable: 'PURPLEMET_API_TOKEN')]) {
      withEnv(envVars) {
        // Delegate to shared analysis script
        def exitCode = sh(
            script: '/tmp/purplemet-analyze.sh',
            returnStatus: true
        )

        // Archive report (filename depends on format)
        archiveArtifacts artifacts: reportFile, allowEmptyArchive: true

        if (exitCode == 1) {
            unstable("Purplemet: security gate(s) failed")
        } else if (exitCode > 1) {
            error("Purplemet analysis failed with exit code ${exitCode}")
        }
      }
    }
}
