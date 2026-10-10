[CmdletBinding()]
param([string]$RunId='pmcro-tutorial-001')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$loop=Join-Path $root '.pmcro/plugins/pmcro-orchestrator/skills/orchestrate/scripts/loop-cycle.ps1'
& $loop -Marketplace $root -RunId $RunId -Source intent -Goal 'Demonstrate one bounded PMCR-O governance capability cycle for the tutorial.' -Plugin pmcro-governance -Skill govern
$check=Get-Content -LiteralPath (Join-Path $root ".pmcro/trails/$RunId-check.jsonl") -Raw|ConvertFrom-Json
if($check.verdict -ne 'PASS'){throw "tutorial verdict $($check.verdict)"}
Write-Output "TUTORIAL-PASS $RunId"
