param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$RunId
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'phase-hook.psm1') -Force
$market = (Resolve-Path -LiteralPath $Marketplace).Path
Import-Module (Join-Path $PSScriptRoot 'disclosure.psm1') -Force
$trailPath = Join-Path $market ".pmcro/trails/$RunId.jsonl"
if (-not (Test-Path -LiteralPath $trailPath)) { throw "missing maker trail $RunId" }
$verdictPath = Join-Path $market ".pmcro/trails/$RunId-check.jsonl"
if (Test-Path -LiteralPath $verdictPath) { throw "append-only: check already exists for $RunId" }
$events = @(Get-Content -LiteralPath $trailPath | ForEach-Object { $_ | ConvertFrom-Json })
$fail = @()
$intent = $events | Where-Object { $_.phase -eq 'intent-refinement' } | Select-Object -First 1
$admit = $events | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
$plan = $events | Where-Object { $_.phase -eq 'plan' } | Select-Object -First 1
$phaseOrder = @($events | ForEach-Object { $_.phase }) -join ','
foreach ($event in $events) {
    if (-not $event.i) { $fail += "frame $($event.phase) has no bounded I identity"; continue }
    if ($event.i.schema -ne 'pmcro.i-frame/v1') { $fail += "frame $($event.phase) has invalid I schema" }
    if (-not $event.i.am -or -not $event.i.entityRef -or $event.i.am -ne $event.i.entityRef) { $fail += "frame $($event.phase) has inconsistent I entity" }
    if (-not $event.i.intentRef -or -not $event.i.intent -or -not $event.i.behavior) { $fail += "frame $($event.phase) has incomplete I intent/behavior" }
    if (-not $event.i.addressedI) { $fail += "frame $($event.phase) has no addressed I" }
    if (@($event.i.objectRefs).Count -lt 1 -or @($event.i.objectRefs | Where-Object { -not $_ }).Count -gt 0) { $fail += "frame $($event.phase) has invalid I dependency object refs" }
    if (-not $event.i.authorityCeilingRef) { $fail += "frame $($event.phase) has no I authority ceiling" }
    foreach ($generated in @([string]$event.i.behavior,[string]$event.i.addressedI,[string]$event.i.am)) {
        if ($generated -match '(?i)\b(you|your|we|our)\b') { $fail += "frame $($event.phase) generated non-I pronoun" }
    }
}
if (-not $intent) { $fail += 'missing mandatory intent-refinement ingress frame' }
else {
    if ($intent.response -ne "I AM the $(Get-PhaseRoute orchestrate)") { $fail += 'intent refinement did not speak as Orchestrator-I' }
    if ($intent.ownerPhase -ne 'ORCHESTRATE' -or $intent.invokedBy -ne 'orchestrator') { $fail += 'intent refinement is not owned by ORCHESTRATE' }
    if ($intent.authorityGranted -ne $false -or $intent.executionPerformed -ne $false) { $fail += 'intent refinement widened authority or executed work' }
    if (-not $intent.rawIntent -or -not $intent.workingIntent) { $fail += 'intent refinement omitted raw or working intent' }
    if (@($intent.validatedClaims).Count -lt 1) { $fail += 'intent refinement has no validated claims' }
    foreach ($claim in @($intent.validatedClaims)) {
        $raw=[string]$intent.rawIntent; $start=[int]$claim.sourceStart; $end=[int]$claim.sourceEnd
        if ($claim.status -ne 'CONFIRMED' -or -not $claim.claimId -or -not $claim.sourceExcerpt -or $start -lt 0 -or $end -le $start -or $end -gt $raw.Length -or $raw.Substring($start,$end-$start) -ne [string]$claim.sourceExcerpt) { $fail += 'intent refinement has claim without exact CONFIRMED source grounding' }
    }
    if ($admit.message -ne $intent.workingIntent) { $fail += 'orchestrate did not consume the refined working intent' }
}
if ($admit.skillCreator.present -ne $true -or $admit.skillCreator.call -ne $false) { $fail += 'skill-creator was not a default present capability' }
if ($plan.bareMinimum -ne $true) { $fail += 'plan is not the bare minimum' }
if (@($plan.steps)[0] -ne '.agents/catalog.json') { $fail += 'plan omitted the validated catalog' }
foreach ($id in @($plan.dropped)) {
    if (@($plan.steps) -contains $id) { $fail += "unvalidated resource was planned: $id" }
}
$called = @($events | ForEach-Object { $_.nextCall } | Where-Object { $_ -match 'skill-creator' })
if ($called.Count -ne 0) { $fail += 'the cycle called skill-creator' }
if ($admit.decision -eq 'invoke') {
    if ($phaseOrder -ne 'intent-refinement,orchestrate,plan,make,make') { $fail += "phase order $phaseOrder" }
    if ($plan.nextCall -ne (Get-NextRoute plan)) { $fail += 'invoke plan did not name make' }
    if (-not $plan.message) { $fail += 'invoke plan has no message' }
}
elseif ($admit.decision -eq 'goal') {
    if ($phaseOrder -ne 'intent-refinement,orchestrate,plan,make') { $fail += "phase order $phaseOrder" }
    if ($admit.nextCall -ne (Get-NextRoute orchestrate)) { $fail += 'goal did not stay on the cycle' }
    $bodies = @($events | ForEach-Object { $_.loaded } | Where-Object { $_ -match '/SKILL\.md$' })
    if ($bodies.Count -ne 0) { $fail += 'goal opened a skill body' }
    if (-not $admit.source) { $fail += 'goal has no source' }
}
else { $fail += "decision $($admit.decision) is not invoke or goal" }
$seenBody = $false
foreach ($event in $events) {
    foreach ($path in @($event.loaded)) {
        if ($path -match '/SKILL\.md$') { $seenBody = $true }
        if ($path -match '/(references|scripts)/' -and -not $seenBody) { $fail += "level 3 recorded before a skill body: $path" }
    }
}
$voice = @{ 'intent-refinement' = (Get-PhaseRoute orchestrate); orchestrate = (Get-PhaseRoute orchestrate); plan = (Get-PhaseRoute plan); make = (Get-PhaseRoute make) }
foreach ($event in $events) {
    $expectedVoice = "I AM the $($voice[$event.phase])"
    if ($event.response -ne $expectedVoice) { $fail += "frame $($event.phase) did not respond as $expectedVoice" }
    if ($event.hookBefore -and $event.hookBefore -notlike "$expectedVoice*") { $fail += "frame $($event.phase) before hook did not trigger $expectedVoice" }
}
$makerError = @($events | Where-Object { $_.phase -eq 'make' -and $_.error } | Select-Object -First 1)
if ($makerError) { $fail += "checker caught maker error: $($makerError.error)" }
if (@($events | Where-Object { $_.phase -eq 'check' -or $_.verdict }).Count -ne 0) { $fail += 'maker trail contains a verdict' }
if ($admit.decision -eq 'invoke') {
    $make = $events | Where-Object { $_.level -eq 3 } | Select-Object -Last 1
    if ([int]$make.exitCode -ne 0) { $fail += 'maker validate exit was not 0' }
    if (-not $make) { $fail += 'invoke did not record a script' }
    $invoked = @($events | Where-Object { $_.invoke } | Select-Object -First 1)
    if ($invoked.Count -ne 1 -or $invoked[0].message -ne $admit.message) { $fail += 'invoke did not pass the message' }
}

Initialize-Disclosure $market
$probeFailed = $false
try { Open-Disclosure 3 'plugins/dotnet/skills/csharp-expert/scripts/validate.ps1' | Out-Null } catch { $probeFailed = $true }
if (-not $probeFailed) { $fail += 'level 3 before level 2 was allowed' }

$setup = Join-Path $PSScriptRoot '../../../../pmcro-orchestrator/skills/orchestrate/scripts/setup-call.ps1'
$probeId = "goal-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
& $setup -Marketplace $market -Source intent -Goal 'probe a missing skill' -Plugin dotnet -Skill 'not-a-catalog-skill' -RunId $probeId | Out-Null
$probeEvents = @(Get-Content -LiteralPath (Join-Path $market ".pmcro/trails/$probeId.jsonl") | ForEach-Object { $_ | ConvertFrom-Json })
$probeAdmit = $probeEvents | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
$probeIntent = $probeEvents | Where-Object { $_.phase -eq 'intent-refinement' } | Select-Object -First 1
if (-not $probeIntent -or $probeIntent.ownerPhase -ne 'ORCHESTRATE') { $fail += 'missing skill probe skipped intent refinement' }
if ($probeAdmit.decision -ne 'goal') { $fail += 'missing skill was not kept as a goal' }
if ($probeAdmit.nextCall -ne (Get-NextRoute orchestrate)) { $fail += 'missing skill left the cycle' }
if ($probeAdmit.skillCreator.call -ne $false) { $fail += 'missing skill called skill-creator' }
$probeLoads = @($probeEvents | ForEach-Object { $_.loaded } | Where-Object { $_ -match '/SKILL\.md$' })
if ($probeLoads.Count -ne 0) { $fail += 'missing skill opened a skill body' }

$routed = @($events | Where-Object { $_.skillBody } | Select-Object -First 1).skillBody
if ($routed) {
    Initialize-Disclosure $market
    Open-Disclosure 1 '.agents/catalog.json' | Out-Null
    Open-Disclosure 2 $routed | Out-Null
    $scriptPath = ($routed -replace '/SKILL\.md$','') + '/scripts/validate.ps1'
    Open-Disclosure 3 $scriptPath | Out-Null
    & (Join-Path $market ($scriptPath.Replace('/', [IO.Path]::DirectorySeparatorChar))) | Out-Null

}

$makeScored = $events | Where-Object { $_.phase -eq 'make' -and $_.score } | Select-Object -First 1
if (-not $plan.score) { $fail += 'planner score is missing' }
if (-not $makeScored.score) { $fail += 'maker score is missing' }
$closedAvoided = 1
if ($admit.closedRoute -and $admit.route -eq $admit.closedRoute) { $closedAvoided = 0 }
$plannerExpected = [ordered]@{
    bareMinimum = [int]($plan.bareMinimum -eq $true -and @($plan.steps)[0] -eq '.agents/catalog.json')
    catalogFirst = [int](@($plan.steps)[0] -eq '.agents/catalog.json')
    closedRouteAvoided = $closedAvoided
    noSkillCreatorCall = [int]($plan.nextCall -notmatch 'skill-creator')
    handsToMake = [int]($plan.nextCall -eq (Get-NextRoute plan))
}
$bodyOpened = @($events | ForEach-Object { $_.loaded } | Where-Object { $_ -match '/SKILL\.md$' }).Count -gt 0
$makerExpected = [ordered]@{
    followedPlan = [int]($makeScored.phase -eq 'make')
    carriedMessage = [int]($makeScored.message -eq $admit.message)
    noSkillCreatorCall = [int]($makeScored.nextCall -notmatch 'skill-creator')
}
if ($admit.decision -eq 'invoke') { $makerExpected.bodyOpened = [int]$bodyOpened }
else { $makerExpected.bodyStayedClosed = [int](-not $bodyOpened) }
$matrix = [ordered]@{ planner = [ordered]@{}; maker = [ordered]@{} }
if ($plan.score) {
    foreach ($key in @($plannerExpected.Keys)) {
        $recorded = [int]$plan.score.$key
        $expected = [int]$plannerExpected.$key
        $matrix.planner.$key = $expected
        if ($recorded -ne $expected) { $fail += "planner $key recorded $recorded expected $expected" }
        if ($expected -ne 1) { $fail += "planner $key scored 0" }
    }
}
if ($makeScored.score) {
    foreach ($key in @($makerExpected.Keys)) {
        $recorded = [int]$makeScored.score.$key
        $expected = [int]$makerExpected.$key
        $matrix.maker.$key = $expected
        if ($recorded -ne $expected) { $fail += "maker $key recorded $recorded expected $expected" }
        if ($expected -ne 1) { $fail += "maker $key scored 0" }
    }
}
$verdict = if ($fail.Count -eq 0) { 'PASS' } else { 'LOOP' }
$intentRef = [string]@($events | Where-Object { $_.phase -eq 'intent-refinement' } | Select-Object -First 1).rootIntentRef
$row = [ordered]@{
    phase = 'check'; response = "I AM the $(Get-PhaseRoute check)"; i = (New-IFrame -Phase check -IntentRef $intentRef -Intent ([string]$admit.message) -Behavior 'independently judge lifecycle evidence' -ObjectRefs @("${RunId}:orchestrate","${RunId}:plan","${RunId}:make") -AddressedI (Get-NextRoute check)); hookBefore = (Get-BeforeHook -Phase check -Seed $RunId); hookAfter = (Get-AfterHook -Phase check -Seed $RunId -Next (Get-NextRoute check)); verdict = $verdict; runId = $RunId; failures = @($fail)
    matrix = $matrix
    mustFail = 'level 3 before SKILL.md threw'; goalProbe = $probeId; nextCall = (Get-NextRoute check)
}
[IO.File]::WriteAllText($verdictPath, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
Write-Output (Get-BeforeHook -Phase check -Seed $RunId)
Write-Output (Get-AfterHook -Phase check -Seed $RunId -Next (Get-NextRoute check))
Write-Output "$verdict next $(Get-NextRoute check)"
if ($verdict -ne 'PASS') { $fail | ForEach-Object { Write-Output "FAIL: $_" } }
return