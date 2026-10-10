Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-QueueRoot { Split-Path -Parent $PSScriptRoot }
function Get-QueueConfig { Get-Content -LiteralPath (Join-Path (Get-QueueRoot) 'config.json') -Raw | ConvertFrom-Json }
function Assert-SafeId([string]$Value,[string]$Name){if([string]::IsNullOrWhiteSpace($Value)-or $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$'){throw "$Name is invalid"}}
function UtcNow { [DateTimeOffset]::UtcNow }
function Iso([DateTimeOffset]$Value){$Value.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')}
function Write-JsonAtomic([string]$Path,$Value){
  $tmp="$Path.tmp.$([guid]::NewGuid().ToString('N'))";$json=$Value|ConvertTo-Json -Depth 30
  [IO.File]::WriteAllText($tmp,$json+[Environment]::NewLine,[Text.UTF8Encoding]::new($false));Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Canonical-Body($m){
  [ordered]@{apiVersion=[string]$m.apiVersion;kind=[string]$m.kind;messageId=[string]$m.messageId;traceId=[string]$m.traceId;correlationId=[string]$m.correlationId;parentMessageId=[string]$m.parentMessageId;causationId=[string]$m.causationId;trailId=[string]$m.trailId;cycleId=[string]$m.cycleId;sourceAgent=[string]$m.sourceAgent;targetAgent=[string]$m.targetAgent;plugin=[string]$m.plugin;skill=[string]$m.skill;createdAt=[string]$m.createdAt;availableAt=[string]$m.availableAt;expiresAt=[string]$m.expiresAt;evidenceStatus=[string]$m.evidenceStatus;grantRefs=@($m.grantRefs);payload=$m.payload}
}
function Digest-Body($m){$json=(Canonical-Body $m)|ConvertTo-Json -Compress -Depth 30;$bytes=[Text.Encoding]::UTF8.GetBytes($json);$sha=[Security.Cryptography.SHA256]::Create();try{(([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant())}finally{$sha.Dispose()}}
function Stable-Body($m){
  [ordered]@{apiVersion=[string]$m.apiVersion;kind=[string]$m.kind;messageId=[string]$m.messageId;traceId=[string]$m.traceId;correlationId=[string]$m.correlationId;parentMessageId=[string]$m.parentMessageId;causationId=[string]$m.causationId;trailId=[string]$m.trailId;cycleId=[string]$m.cycleId;sourceAgent=[string]$m.sourceAgent;targetAgent=[string]$m.targetAgent;plugin=[string]$m.plugin;skill=[string]$m.skill;expiresAt=[string]$m.expiresAt;evidenceStatus=[string]$m.evidenceStatus;grantRefs=@($m.grantRefs);payload=$m.payload}
}
function Dedupe-Digest($m){$json=(Stable-Body $m)|ConvertTo-Json -Compress -Depth 30;$bytes=[Text.Encoding]::UTF8.GetBytes($json);$sha=[Security.Cryptography.SHA256]::Create();try{(([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant())}finally{$sha.Dispose()}}
function Validate-Message($m,$config){
  foreach($f in @('apiVersion','kind','messageId','traceId','correlationId','trailId','cycleId','sourceAgent','targetAgent','createdAt','availableAt','evidenceStatus','dedupeDigest','contentDigest')){if(-not $m.PSObject.Properties[$f]-or[string]::IsNullOrWhiteSpace([string]$m.$f)){throw "missing message field: $f"}}
  Assert-SafeId ([string]$m.messageId) 'messageId';Assert-SafeId ([string]$m.traceId) 'traceId';Assert-SafeId ([string]$m.correlationId) 'correlationId'
  if([string]$m.apiVersion -ne 'pmcro.message/v1'){throw 'unsupported message apiVersion'}
  if([string]$m.targetAgent -ne [string]$config.agent){throw "message targetAgent must be $($config.agent)"}
  if([string]$m.kind -notin @($config.allowedKinds)){throw "message kind not allowed: $($m.kind)"}
  if([string]$m.evidenceStatus -notin @('CONFIRMED','NOT-YET-VERIFIED','NOT-RUN')){throw 'invalid evidenceStatus'}
  if((Dedupe-Digest $m) -ne [string]$m.dedupeDigest){throw 'message dedupe digest mismatch'}
  if((Digest-Body $m) -ne [string]$m.contentDigest){throw 'message digest mismatch'}
  $true
}
function Find-Envelope([string]$MessageId){
  $q=Get-QueueRoot;foreach($d in @('inbox','processing','delayed','completed','dead-letter')){$p=Join-Path $q "$d/$MessageId.json";if(Test-Path -LiteralPath $p -PathType Leaf){return $p}};return $null
}
function Read-State([string]$MessageId){$p=Join-Path (Get-QueueRoot) "state/$MessageId.json";if(Test-Path -LiteralPath $p){Get-Content -LiteralPath $p -Raw|ConvertFrom-Json}else{$null}}
function Write-State([string]$MessageId,$State){Write-JsonAtomic (Join-Path (Get-QueueRoot) "state/$MessageId.json") $State}
Export-ModuleMember -Function *
