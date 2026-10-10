param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$Plugin,
    [Parameter(Mandatory = $true)][string]$Skill,
    [Parameter(Mandatory = $true)][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Description
)
$ErrorActionPreference = 'Stop'
foreach ($pair in @{ plugin = $Plugin; skill = $Skill; agent = $Agent }.GetEnumerator()) {
    if ($pair.Value -notmatch '^[a-z0-9-]+$') { throw "$($pair.Key) must be lowercase letters, digits, and hyphens" }
}
$root = (Resolve-Path -LiteralPath $Marketplace).Path
$dest = Join-Path $root "plugins/$Plugin/skills/$Skill"
if (Test-Path -LiteralPath $dest) { throw "skill already exists: $Plugin/$Skill" }
$utf8 = [Text.UTF8Encoding]::new($false)
function Write-Utf8([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    if (-not $Text.EndsWith("`n")) { $Text += "`n" }
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}
$quoted = '"' + (($Description -replace '\\', '\\') -replace '"', '\"') + '"'
Write-Utf8 (Join-Path $dest 'SKILL.md') @"
---
name: $Skill
description: $quoted
---
# $Skill
Spoken route: ``@${Agent} /${Plugin}:${Skill}``.
## Workflow
1. Read this skill only after the marketplace catalog names it.
2. Run scripts/validate.ps1.
3. Stop. This package is a candidate until a separate check registers it.
"@
Write-Utf8 (Join-Path $dest "agents/$Agent.md") @"
---
name: $Agent
description: $quoted
tools: Read, Grep, Glob
skills: $Skill
---
Use the $Skill skill. Run scripts/validate.ps1. Do not register this candidate.
"@
Write-Utf8 (Join-Path $dest 'scripts/validate.ps1') @'
param()
$ErrorActionPreference = 'Stop'
$skillDir = Split-Path -Parent $PSScriptRoot
$name = Split-Path -Leaf $skillDir
$text = Get-Content -LiteralPath (Join-Path $skillDir 'SKILL.md') -Raw
if ($text -notmatch "(?m)^name: $name\s*$") { throw "name mismatch for $name" }
foreach ($rel in @('references/package.md','assets/request.json','tests/fixture.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $skillDir $rel) -PathType Leaf)) { throw "missing $rel" }
}
'PASS'
return
'@
Write-Utf8 (Join-Path $dest 'references/package.md') @"
# $Skill
Candidate skill in plugin $Plugin. Agent: $Agent.
Registration is a separate step. This file does not grant it.
"@
Write-Utf8 (Join-Path $dest 'assets/request.json') (@{
    plugin = $Plugin; skill = $Skill; agent = $Agent; description = $Description; registered = $false
} | ConvertTo-Json)
Write-Utf8 (Join-Path $dest 'tests/fixture.json') (@{ skill = $Skill; plugin = $Plugin; registered = $false } | ConvertTo-Json)
& (Join-Path $dest 'scripts/validate.ps1') | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'candidate validation failed' }
Write-Output "CANDIDATE plugins/$Plugin/skills/$Skill"
return