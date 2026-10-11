param([Parameter(Mandatory=$true)][string]$RawFile,[Parameter(Mandatory=$true)][string]$RootIntentRef,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$raw=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $RawFile).Path,[Text.Encoding]::UTF8)
if([string]::IsNullOrEmpty($raw)){throw 'rawIntent'}
$working=($raw -replace '\s+',' ').Trim()
if([string]::IsNullOrEmpty($working)){throw 'workingIntent'}
$changes=@(); if($working -ne $raw){$changes=@('Collapsed whitespace only; no semantic inference performed by deterministic wrapper.')}
$I=[ordered]@{
  schema='pmcro.i-context/v1'
  iRef=('i:'+ $RootIntentRef +':orchestrate')
  entityRef='pmcro-agent'
  role='ORCHESTRATE'
  behavior='refine-intent'
  intentRef=$RootIntentRef
  lineageRootRef=$RootIntentRef
  parentIRef=''
  objectIRefs=@()
  addressedIRef='reasoning-agent'
  authorityCeilingRef='authority:inherited'
  metaDepth=0
  consciousnessClaim=$false
}
$obj=[ordered]@{
  schema='pmcro.intent-refinement/v1'
  I=$I
  rootIntentRef=$RootIntentRef
  ownerPhase='ORCHESTRATE'
  invokedBy='orchestrator'
  rawIntent=$raw
  workingIntent=$working
  requestedOutcome=$working
  validatedClaims=@([ordered]@{
    claimId='claim-001'; sourceStart=0; sourceEnd=$raw.Length; sourceExcerpt=$raw; interpretation=$working; status='CONFIRMED'
  })
  unresolvedFragments=@('Semantic decomposition remains unresolved until an agent/model emits smaller exact-source-grounded CONFIRMED claims.')
  explicitConstraints=@()
  assumptions=@()
  changes=$changes
  rationaleSummary='Conservative ingress refinement preserves the entire source as one exact CONFIRMED claim; deterministic cleanup does not pretend to be semantic understanding.'
  authorityGranted=$false
  executionPerformed=$false
}
$parent=Split-Path -Parent $Output; if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
[IO.File]::WriteAllText($Output,(($obj|ConvertTo-Json -Depth 12)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
Write-Output "INTENT-REFINEMENT-PASS $Output"
