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
exit 0
