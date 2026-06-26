# AgentOS skills — Windows PowerShell installer.
#
# Mirrors the `npx skills add` layout: installable skills land in the shared
# .agents\skills store (read by Cursor, Codex, Gemini CLI, Copilot, Amp, Zed,
# …) plus .claude\skills and .windsurf\skills for the editors that read their
# own locations. Skills marked `internal: true` in their SKILL.md frontmatter
# (e.g. planned, not-yet-implemented skills) are skipped.
#
# Usage:
#   iwr -useb https://raw.githubusercontent.com/TheAgentOS/agentos-skills/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$repo = if ($env:AGENTOS_SKILLS_REPO) { $env:AGENTOS_SKILLS_REPO } else { "TheAgentOS/agentos-skills" }
$ref  = if ($env:AGENTOS_SKILLS_REF)  { $env:AGENTOS_SKILLS_REF }  else { "main" }
$tarballUrl = "https://codeload.github.com/$repo/tar.gz/$ref"

# Returns $true if the SKILL.md frontmatter marks the skill internal (hidden
# from install), matching the npx installer's `metadata.internal: true` flag.
function Test-SkillInternal {
    param([string]$SkillMdPath)
    $fence = 0
    foreach ($line in Get-Content -LiteralPath $SkillMdPath) {
        if ($line -match '^\s*---\s*$') {
            $fence++
            if ($fence -eq 2) { return $false }
            continue
        }
        if ($fence -eq 1 -and $line -match '^\s*internal:\s*true(\s|$)') { return $true }
    }
    return $false
}

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

    $stores = @(
        (Join-Path $cwd ".agents\skills"),
        (Join-Path $cwd ".claude\skills"),
        (Join-Path $cwd ".windsurf\skills")
    )
    foreach ($store in $stores) { New-Item -ItemType Directory -Path $store -Force | Out-Null }

    $installed = 0
    $skipped = 0
    Get-ChildItem -Directory (Join-Path $src.FullName "skills") | ForEach-Object {
        $name = $_.Name
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) { return }

        if (Test-SkillInternal $skillFile) {
            Write-Host "    skip $name (internal / not yet implemented)"
            $script:skipped++
            return
        }

        foreach ($store in $stores) {
            $target = Join-Path $store $name
            if (Test-Path $target) { Remove-Item -Recurse -Force $target }
            Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
        }
        Write-Host "    wrote $name"
        $script:installed++
    }

    if ($installed -eq 0) {
        throw "no installable skills found in $repo@$ref"
    }

    Copy-Item -Path (Join-Path $src.FullName "AGENTS.md") -Destination (Join-Path $cwd "AGENTS.md.agentos") -Force
    Write-Host "    wrote .\AGENTS.md.agentos (merge into AGENTS.md if you have one)"

    Write-Host ""
    Write-Host "✓ Installed $installed skill(s) ($skipped skipped) into .agents\skills, .claude\skills, .windsurf\skills"
    Write-Host "  Open your IDE agent and ask, e.g.:"
    Write-Host "    Set up AgentHog tracing in my application."
} finally {
    Remove-Item -Recurse -Force $tmpRoot.FullName -ErrorAction SilentlyContinue
}
