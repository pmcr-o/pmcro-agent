param()
$ErrorActionPreference = 'Stop'
$skillDir = Split-Path -Parent $PSScriptRoot
foreach ($rel in @('SKILL.md','agents/deleter.md','scripts/delete-skill.ps1','scripts/remove-skill-configuration.ps1','references/package.md','assets/request.json','tests/fixture.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $skillDir $rel) -PathType Leaf)) { throw "missing $rel" }
}
$text = Get-Content -LiteralPath (Join-Path $skillDir 'SKILL.md') -Raw
if ($text -notmatch '(?m)^name: delete-skill\s*$') { throw 'frontmatter name mismatch' }
'PASS: delete-skill'
return