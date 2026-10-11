param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$RunId
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'phase-hook.psm1') -Force
$market = (Resolve-Path -LiteralPath $Marketplace).Path
$checkPath = Join-Path $market ".pmcro/trails/$RunId-check.jsonl"
$callPath = Join-Path $market ".pmcro/trails/$RunId.jsonl"
if (-not (Test-Path -LiteralPath $checkPath)) { throw 'reflect requires the check skill verdict' }
if (-not (Test-Path -LiteralPath $callPath)) { throw 'reflect requires the call trail' }
$check = Get-Content -LiteralPath $checkPath -Raw | ConvertFrom-Json
if ($check.verdict -ne 'PASS' -and $check.verdict -ne 'LOOP') { throw 'reflect requires PASS or LOOP' }
$out = Join-Path $market ".pmcro/trails/$RunId-reflect.jsonl"
if (Test-Path -LiteralPath $out) { throw "append-only: reflect already exists for $RunId" }
$events = @(Get-Content -LiteralPath $callPath | ForEach-Object { $_ | ConvertFrom-Json })
$admit = $events | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
if ($admit.decision -ne 'invoke' -and $admit.decision -ne 'goal') { throw "reflect requires invoke or goal, not $($admit.decision)" }
$frames = @($events | ForEach-Object { $_.phase })
$plan = $events | Where-Object { $_.phase -eq 'plan' } | Select-Object -First 1
$steps = @($plan.steps | Where-Object { $_ })
$dropped = @($plan.dropped | Where-Object { $_ })
$openedBody = @($events | ForEach-Object { $_.loaded } | Where-Object { $_ -match '/SKILL\.md$' })
$doNot = @('call skill-creator')
$closedRoute = ''
$makerError = @($events | Where-Object { $_.phase -eq 'make' -and $_.error } | Select-Object -First 1)
if ($makerError) {
    $constraint = "Across $($frames -join ', '), the maker errored: $($makerError.error). The checker caught it."
    $intent = 'The orchestrator may seed the maker repair into the next cycle.'
    $do = @('the orchestrator may seed the next cycle')
}
elseif ($dropped.Count -gt 0) {
    $constraint = "Across $($frames -join ', '), plan dropped $($dropped -join ', ') because those resources were not validated."
    $intent = 'Keep only the validated steps.'
    $do = @('keep the validated steps', 'drop the unvalidated resources')
    $doNot = @('plan an unvalidated resource') + $doNot
}
elseif ($admit.decision -eq 'invoke') {
    $constraint = "Across $($frames -join ', '), $($admit.route) was invoked and the carried message was passed."
    $intent = "Leave $($admit.route) closed."
    $do = @('leave the route closed')
    $doNot = @('open that skill body again') + $doNot
}
elseif ($admit.reason -eq 'route stays closed') {
    $constraint = "Across $($frames -join ', '), $($admit.route) stayed closed. The skill body was not opened."
    $intent = 'Name one listed skill other than the closed route, and the message that invokes it.'
    $do = @('read the catalog', 'choose one listed skill other than the closed route', 'carry that skill message')
    $doNot = @('open that skill body again') + $doNot
    $closedRoute = $admit.route
}
elseif ($admit.reason -eq 'marketplace trail') {
    $generated = [string]@($events | Where-Object { $_.generated } | Select-Object -First 1).generated
    if (-not $generated) { throw 'marketplace trail did not generate a skill file' }
    $constraint = "Across $($frames -join ', '), the marketplace trail logged each folder as an orchestrator and each file as a subagent. The generated file is the next skill."
    $intent = "Name $generated as the next skill and carry its message."
    $do = @('name the generated file', 'carry that skill message')
}
elseif ($admit.plugin -and $admit.skill -and $openedBody.Count -eq 0) {
    $constraint = "Across $($frames -join ', '), $($admit.route) was named and its catalog message was carried. No skill body was opened."
    $intent = "Invoke $($admit.route) with the carried message."
    $do = @('invoke the named route', 'pass the carried message')
}
else {
    $constraint = "Across $($frames -join ', '), the goal added no step beyond the catalog."
    if ($openedBody.Count -eq 0) { $constraint = "$constraint No skill body was opened." }
    $intent = 'Name one listed skill and the message that invokes it.'
    $do = @('read the catalog', 'choose one listed skill', 'carry that skill message')
    $doNot = @('open a skill body before the choice') + $doNot
}
$depth = 0
if ($admit.meta) { $depth = [int]$admit.meta }
$nextDepth = [Math]::Min(3, $depth + 1)
$level = @('meta', 'meta meta', 'meta meta meta')[$nextDepth - 1]
if ($nextDepth -eq 3) { $doNot += 'add another meta wrap' }
$known = [ordered]@{ present = $true; call = $false }
$next = [ordered]@{
    intent = $intent
    because = $constraint
    level = $level
    depth = $nextDepth
    question = 'how could we have done better'
    cycle = $frames
    do = $do
    doNot = $doNot
    executed = $false
    skillCreator = $known
}
if ($closedRoute) { $next.closedRoute = $closedRoute }
$row = [ordered]@{
    phase = 'reflect'
    response = "I AM the Reflector"
    hookBefore = (Get-BeforeHook -Phase reflect -Seed $RunId)
    hookAfter = (Get-AfterHook -Phase reflect -Seed $RunId -Next '@orchestrator /pmcro:orchestrate')
    nextCall = '@orchestrator /pmcro:orchestrate'
    runId = $RunId
    verdict = $check.verdict
    frames = $frames
    question = 'how could we have done better'
    constraint = $constraint
    nextSeed = $next
}
[IO.File]::WriteAllText($out, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
Write-Output (Get-BeforeHook -Phase reflect -Seed $RunId)
Write-Output "CONSTRAINT $constraint"
Write-Output "INTENT $intent"
Write-Output (Get-AfterHook -Phase reflect -Seed $RunId -Next '@orchestrator /pmcro:orchestrate')
return