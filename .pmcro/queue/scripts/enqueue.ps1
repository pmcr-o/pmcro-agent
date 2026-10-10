[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Kind,[Parameter(Mandatory=$true)][string]$SourceAgent,[Parameter(Mandatory=$true)][string]$TargetAgent,[Parameter(Mandatory=$true)][string]$TrailId,[Parameter(Mandatory=$true)][string]$CycleId,[string]$MessageId='',[string]$TraceId='',[string]$CorrelationId='',[string]$ParentMessageId='',[string]$CausationId='',[string]$Plugin='',[string]$Skill='',[string]$PayloadPath='',[ValidateSet('CONFIRMED','NOT-YET-VERIFIED','NOT-RUN')][string]$EvidenceStatus='NOT-RUN',[string[]]$GrantRefs=@(),[int]$DelaySeconds=0,[string]$ExpiresAt='')
Import-Module (Join-Path $PSScriptRoot 'queue.psm1') -Force -DisableNameChecking
$c=Get-QueueConfig;if($TargetAgent -ne [string]$c.agent){throw "target queue is $($c.agent), not $TargetAgent"}
if(-not $MessageId){$MessageId=[guid]::NewGuid().ToString('N')};if(-not $TraceId){$TraceId=$MessageId};if(-not $CorrelationId){$CorrelationId=$TraceId}
Assert-SafeId $MessageId 'messageId';Assert-SafeId $TraceId 'traceId';Assert-SafeId $CorrelationId 'correlationId'
if($Kind -notin @($c.allowedKinds)){throw "message kind not allowed: $Kind"}
$payload=[ordered]@{};if($PayloadPath){if(-not(Test-Path -LiteralPath $PayloadPath -PathType Leaf)){throw 'PayloadPath missing'};$payload=Get-Content -LiteralPath $PayloadPath -Raw|ConvertFrom-Json}
$now=UtcNow;$available=$now.AddSeconds([Math]::Max(0,$DelaySeconds))
if($ExpiresAt){$expiry=[DateTimeOffset]::Parse($ExpiresAt);if($expiry -le $now){throw 'ExpiresAt must be in the future'}}
$body=[ordered]@{apiVersion='pmcro.message/v1';kind=$Kind;messageId=$MessageId;traceId=$TraceId;correlationId=$CorrelationId;parentMessageId=$ParentMessageId;causationId=$CausationId;trailId=$TrailId;cycleId=$CycleId;sourceAgent=$SourceAgent;targetAgent=$TargetAgent;plugin=$Plugin;skill=$Skill;createdAt=(Iso $now);availableAt=(Iso $available);expiresAt=$ExpiresAt;evidenceStatus=$EvidenceStatus;grantRefs=@($GrantRefs);payload=$payload}
$dedupe=Dedupe-Digest ([pscustomobject]$body);$digest=Digest-Body ([pscustomobject]$body);$msg=[ordered]@{};foreach($k in $body.Keys){$msg[$k]=$body[$k]};$msg.dedupeDigest=$dedupe;$msg.contentDigest=$digest
$existing=Find-Envelope $MessageId;$receipt=Join-Path (Get-QueueRoot) "receipts/$MessageId.json"
if(-not $existing -and (Test-Path -LiteralPath $receipt)){$r=Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json;if([string]$r.dedupeDigest -eq $dedupe){Write-Output "IDEMPOTENT $MessageId";return}else{throw 'messageId conflict with completed receipt'}}
if($existing){$old=Get-Content -LiteralPath $existing -Raw|ConvertFrom-Json;$oldDedupe=if($old.PSObject.Properties['dedupeDigest']){[string]$old.dedupeDigest}else{Dedupe-Digest $old};if($oldDedupe -eq $dedupe){Write-Output "IDEMPOTENT $MessageId";return}else{throw 'messageId conflict with different semantic content'}}
$q=Get-QueueRoot;$tmp=Join-Path $q "tmp/$MessageId.$([guid]::NewGuid().ToString('N')).json";$dest=Join-Path $q "inbox/$MessageId.json"
[IO.File]::WriteAllText($tmp,(($msg|ConvertTo-Json -Depth 30)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
try{Move-Item -LiteralPath $tmp -Destination $dest -ErrorAction Stop}catch{if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force};$old=Find-Envelope $MessageId;if($old){$m=Get-Content -LiteralPath $old -Raw|ConvertFrom-Json;$oldDedupe=if($m.PSObject.Properties['dedupeDigest']){[string]$m.dedupeDigest}else{Dedupe-Digest $m};if($oldDedupe -eq $dedupe){Write-Output "IDEMPOTENT $MessageId";return}};throw}
$state=[ordered]@{messageId=$MessageId;status='ENQUEUED';attempt=0;availableAt=(Iso $available);claimedBy='';leaseUntil='';lastError='';updatedAt=(Iso (UtcNow))};Write-State $MessageId $state
Write-Output "ENQUEUED $MessageId $digest"
