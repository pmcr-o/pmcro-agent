param([string]$MessageId='queue-cross-platform-001')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$q=Join-Path $root '.pmcro/queue/scripts'
& (Join-Path $q 'enqueue.ps1') -Kind 'pmcro.seed' -SourceAgent 'pmcro-agent' -TargetAgent 'pmcro-agent' -TrailId 'queue:cross-platform' -CycleId 'queue:cross-platform' -MessageId $MessageId | Out-Null
$inbox=Join-Path $root ".pmcro/queue/inbox/$MessageId.json"
& (Join-Path $q 'validate-message.ps1') -MessagePath $inbox | Out-Null
$claim=& (Join-Path $q 'claim.ps1') -WorkerId 'cross-platform-worker' -MessageId $MessageId
if(($claim|Out-String) -notmatch '"status"\s*:\s*"CLAIMED"'){throw 'claim failed'}
& (Join-Path $q 'ack.ps1') -MessageId $MessageId -WorkerId 'cross-platform-worker' | Out-Null
$replay=& (Join-Path $q 'enqueue.ps1') -Kind 'pmcro.seed' -SourceAgent 'pmcro-agent' -TargetAgent 'pmcro-agent' -TrailId 'queue:cross-platform' -CycleId 'queue:cross-platform' -MessageId $MessageId
if(($replay|Out-String) -notmatch 'IDEMPOTENT'){throw 'semantic replay not idempotent'}
'QUEUE-CROSS-PLATFORM-PASS'
