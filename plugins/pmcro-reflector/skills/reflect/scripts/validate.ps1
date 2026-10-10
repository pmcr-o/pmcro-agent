param()
$ErrorActionPreference = 'Stop'
$skillDir = Split-Path -Parent $PSScriptRoot
$name = Split-Path -Leaf $skillDir
$text = Get-Content -LiteralPath (Join-Path $skillDir 'SKILL.md') -Raw
if ($text -notmatch "(?m)^name: $([regex]::Escape($name))\s*$") { throw "frontmatter name mismatch for $name" }
$nested = @(Get-ChildItem -LiteralPath (Join-Path $skillDir 'agents') -Filter '*.md')
if ($nested.Count -ne 1) { throw 'expected one nested agent' }
$pluginAgent = Join-Path (Split-Path -Parent (Split-Path -Parent $skillDir)) ('agents/' + $nested[0].Name))
if ((Get-FileHash -LiteralPath $nested[0].FullName).Hash -ne (Get-FileHash -LiteralPath $pluginAgent).Hash) { throw 'stale agent projection' }
if ('local' -eq 'projection') {
  $source = Get-Content -LiteralPath (Join-Path $skillDir 'assets/source.json') -Raw | ConvertFrom-Json
  if ($source.executable) { throw 'projection must not be executable' }
}
'PASS: reflect'
