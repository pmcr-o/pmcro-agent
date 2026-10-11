Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
foreach($name in @('catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json')){
  $canonical=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root ".pmcro\control\$name")).Hash
  $agent=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root ".agents\$name")).Hash
  if($canonical -ne $agent){throw ".agents/$name drift"}
  foreach($hostDir in @('.claude','.grok','.cursor','.github')){
    $h=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root "$hostDir\$name")).Hash
    if($h -ne $canonical){throw "$hostDir/$name drift"}
  }
}
'LESSON-PASS projections'
