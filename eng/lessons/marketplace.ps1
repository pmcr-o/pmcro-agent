Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ext=Get-Content -LiteralPath (Join-Path $root '.pmcro\protocol\marketplace-extension.json') -Raw|ConvertFrom-Json
$eco=Get-Content -LiteralPath (Join-Path $root '.pmcro\control\ecosystem.json') -Raw|ConvertFrom-Json
$ids=@($eco.agents|ForEach-Object {$_.id})
if($ext.mode -ne 'autonomous-bounded' -or $ext.questionGate -ne $false){throw 'outer loop contract mismatch'}
foreach($id in @('pmcro-agent','dotnet-agent','skill-creator-agent')){if($id -notin $ids){throw "missing ecosystem agent $id"}}
if('reuse registered capabilities first' -notin @($ext.steps)){throw 'reuse-first rule missing'}
'LESSON-PASS marketplace'
