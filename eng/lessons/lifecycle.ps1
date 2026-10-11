$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id='learn-lifecycle-'+[guid]::NewGuid().ToString('N').Substring(0,8)
& (Join-Path $root 'eng\run-tutorial.ps1') -RunId $id | Out-Null
$check=Get-Content -LiteralPath (Join-Path $root ".pmcro\trails\$id-check.jsonl") -Raw|ConvertFrom-Json
if($check.verdict -ne 'PASS'){throw "checker verdict $($check.verdict)"}
'LESSON-PASS lifecycle'
