Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$bip=Get-Content -LiteralPath (Join-Path $root '.pmcro\protocol\behavioral-intent-programming.json') -Raw|ConvertFrom-Json
$iol=Get-Content -LiteralPath (Join-Path $root '.pmcro\protocol\i-only-language.json') -Raw|ConvertFrom-Json
$ischema=Get-Content -LiteralPath (Join-Path $root '.pmcro\protocol\i-context.schema.json') -Raw|ConvertFrom-Json
if($bip.ingress.firstActivePhase -ne 'ORCHESTRATE' -or -not $bip.ingress.rawSeedImmutable){throw 'BIP ingress law mismatch'}
if($iol.generatedSpeech -ne 'I_ONLY' -or -not $iol.rawIntentLiteralExempt){throw 'I-only language law mismatch'}
if($ischema.properties.consciousnessClaim.const -ne $false){throw 'I-context may not assert consciousness'}
$hook=Join-Path $root '.pmcro\plugins\pmcro-orchestrator\skills\orchestrate\scripts\phase-hook.psm1'
Import-Module $hook -Force
$frame=New-IFrame -Phase orchestrate -IntentRef 'lesson:self:raw' -Intent 'I learn how bounded self-reference works.' -Behavior 'inspect my operational identity frame' -ObjectRefs @('lesson:self:prior-I') -AddressedI '@planner /pmcro-planner:plan'
if($frame.schema -ne 'pmcro.i-frame/v1'){throw 'I-frame schema mismatch'}
if($frame.am -ne '@orchestrator /pmcro-orchestrator:orchestrate'){throw 'I-frame identity mismatch'}
if($frame.addressedI -ne '@planner /pmcro-planner:plan'){throw 'addressed I mismatch'}
if($frame.authorityCeilingRef -ne '.agents/grants.json'){throw 'authority ceiling missing'}
if('lesson:self:prior-I' -notin @($frame.objectRefs)){throw 'prior I is not an explicit object'}
'LESSON-PASS self'
