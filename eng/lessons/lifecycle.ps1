$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$trailRoot=Join-Path $root '.pmcro\trails'
$before=@{}
Get-ChildItem -LiteralPath $trailRoot -Filter 'goal-*.jsonl' -File -ErrorAction SilentlyContinue | ForEach-Object {$before[$_.FullName]=$true}
$id='learn-lifecycle-'+[guid]::NewGuid().ToString('N').Substring(0,8)
try {
  & (Join-Path $root 'eng\run-tutorial.ps1') -RunId $id | Out-Null
  $check=Get-Content -LiteralPath (Join-Path $trailRoot "$id-check.jsonl") -Raw|ConvertFrom-Json
  if($check.verdict -ne 'PASS'){throw "checker verdict $($check.verdict)"}
  'LESSON-PASS lifecycle'
} finally {
  Get-ChildItem -LiteralPath $trailRoot -Filter 'goal-*.jsonl' -File -ErrorAction SilentlyContinue | ForEach-Object {
    if(-not $before.ContainsKey($_.FullName)){Remove-Item -LiteralPath $_.FullName -Force}
  }
}
