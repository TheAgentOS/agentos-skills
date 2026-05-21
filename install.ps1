# AgentOS skills — Windows PowerShell installer.
#
# Usage:
#   iwr -useb https://raw.githubusercontent.com/TheAgentOS/agentos-skills/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$repo = if ($env:AGENTOS_SKILLS_REPO) { $env:AGENTOS_SKILLS_REPO } else { "TheAgentOS/agentos-skills" }
$ref  = if ($env:AGENTOS_SKILLS_REF)  { $env:AGENTOS_SKILLS_REF }  else { "main" }
$tarballUrl = "https://codeload.github.com/$repo/tar.gz/$ref"

$tmpRoot = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "agentos-skills-$([Guid]::NewGuid())")
try {
    Write-Host "==> downloading $repo@$ref"
    $tarPath = Join-Path $tmpRoot.FullName "src.tar.gz"
    Invoke-WebRequest -Uri $tarballUrl -OutFile $tarPath -UseBasicParsing
    # tar is built into modern Windows.
    tar -xzf $tarPath -C $tmpRoot.FullName

    $src = Get-ChildItem -Directory -Path $tmpRoot.FullName | Select-Object -First 1
    if (-not $src -or -not (Test-Path (Join-Path $src.FullName "skills"))) {
        throw "unexpected tarball layout under $($tmpRoot.FullName)"
    }

    $cwd = Get-Location
    Write-Host "==> installing into $cwd"

    Copy-Item -Path (Join-Path $src.FullName "AGENTS.md") -Destination (Join-Path $cwd "AGENTS.md.agentos") -Force
    Write-Host "    wrote .\AGENTS.md.agentos (merge into AGENTS.md if you have one)"

    $claudeDir = Join-Path $cwd ".claude\skills"
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    Copy-Item -Path (Join-Path $src.FullName "skills\*") -Destination $claudeDir -Recurse -Force
    Write-Host "    wrote .\.claude\skills\{agenthog-setup,...}"

    $cursorDir = Join-Path $cwd ".cursor\rules"
    New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null
    Get-ChildItem -Directory (Join-Path $src.FullName "skills") | ForEach-Object {
        $name = $_.Name
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillFile) {
            Copy-Item -Path $skillFile -Destination (Join-Path $cursorDir "$name.md") -Force
        }
    }
    Write-Host "    wrote .\.cursor\rules\*.md"

    Write-Host ""
    Write-Host "✓ Done. Open your IDE agent and ask, e.g.:"
    Write-Host "    Set up AgentHog tracing in my application."
} finally {
    Remove-Item -Recurse -Force $tmpRoot.FullName -ErrorAction SilentlyContinue
}
