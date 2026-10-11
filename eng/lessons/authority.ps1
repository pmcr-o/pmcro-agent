Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$p=Get-Content -LiteralPath (Join-Path $root '.pmcro\control\project.json') -Raw|ConvertFrom-Json
$r=Get-Content -LiteralPath (Join-Path $root '.pmcro\control\routing.json') -Raw|ConvertFrom-Json
if($p.canonical -ne '.pmcro' -or $p.projection -ne '.agents'){throw 'authority chain mismatch'}
if($p.orchestratorRole -ne 'global-orchestrator'){throw 'pmcro-agent is not global orchestrator'}
if($r.questionGate -ne $false -or $r.unresolvedAmbiguity.askUser -ne $false){throw 'clarification gate is enabled'}
'LESSON-PASS authority'
