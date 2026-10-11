$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$q=Join-Path $root '.pmcro\queue\scripts'
$id='learn-queue-'+[guid]::NewGuid().ToString('N').Substring(0,8)
& (Join-Path $q 'enqueue.ps1') -Kind 'pmcro.seed' -SourceAgent 'pmcro-agent' -TargetAgent 'pmcro-agent' -TrailId 'learn:queue' -CycleId 'learn:queue' -MessageId $id | Out-Null
& (Join-Path $q 'claim.ps1') -WorkerId 'learn-worker' -MessageId $id | Out-Null
& (Join-Path $q 'ack.ps1') -MessageId $id -WorkerId 'learn-worker' | Out-Null
$r=& (Join-Path $q 'enqueue.ps1') -Kind 'pmcro.seed' -SourceAgent 'pmcro-agent' -TargetAgent 'pmcro-agent' -TrailId 'learn:queue' -CycleId 'learn:queue' -MessageId $id
if($r -notmatch 'IDEMPOTENT'){throw 'idempotent replay failed'}
'LESSON-PASS queue'
