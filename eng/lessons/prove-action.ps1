Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$plugin='learning-lab';$skill='hello-action';$agent='learning-action-agent'
$pluginRoot=Join-Path $root "plugins\$plugin";$run='learn-action-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$trail=Join-Path $root ".pmcro\trails\$run.jsonl";$runtime=Join-Path $root ".pmcro\runtime\intent-refinement"
try {
  $creator=Join-Path $root '.pmcro\plugins\skill-creator\skills\create-skill\scripts\create-skill.ps1'
  & $creator -Marketplace $root -Plugin $plugin -Skill $skill -Agent $agent -Description 'A disposable action whose route must remain closed until promotion.' | Out-Null
  $setup=Join-Path $root '.pmcro\plugins\pmcro-orchestrator\skills\orchestrate\scripts\setup-call.ps1'
  & $setup -Marketplace $root -RunId $run -Source intent -Goal 'I want to try the generated learning action.' -Plugin $plugin -Skill $skill | Out-Null
  $events=@(Get-Content -LiteralPath $trail|ForEach-Object {$_|ConvertFrom-Json})
  $intent=@($events|Where-Object {$_.phase -eq 'intent-refinement'}|Select-Object -First 1)
  $admit=@($events|Where-Object {$_.phase -eq 'orchestrate'}|Select-Object -First 1)
  if($intent.Count -ne 1 -or $intent[0].ownerPhase -ne 'ORCHESTRATE'){throw 'generated-action interaction bypassed intent refinement'}
  if($admit.Count -ne 1){throw 'missing orchestration decision'}
  if($admit[0].decision -eq 'invoke'){throw 'unregistered generated action was incorrectly invokable'}
  if($admit[0].route){throw 'unregistered generated action received a routable authority path'}
  'LESSON-PASS prove-action'
} finally {
  if(Test-Path -LiteralPath $pluginRoot){Remove-Item -LiteralPath $pluginRoot -Recurse -Force}
  foreach($p in @($trail,(Join-Path $runtime "$run.raw.txt"),(Join-Path $runtime "$run.json"))){if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force}}
}
