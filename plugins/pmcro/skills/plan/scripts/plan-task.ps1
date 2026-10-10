param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$RunId,
    [string]$ResourcesPath
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'phase-hook.psm1') -Force
$market = (Resolve-Path -LiteralPath $Marketplace).Path
$trail = Join-Path $market ".pmcro/trails/$RunId.jsonl"
if (-not (Test-Path -LiteralPath $trail)) { throw "missing call trail $RunId" }
$events = @(Get-Content -LiteralPath $trail | ForEach-Object { $_ | ConvertFrom-Json })
$admit = $events | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
if (-not $admit) { throw 'plan requires an orchestrate call' }
if (@($events | Where-Object { $_.phase -eq 'plan' }).Count -gt 0) { throw 'plan already recorded' }
if ($admit.skillCreator.call) { throw 'plan does not call skill-creator' }
if ($admit.decision -eq 'invoke') {
    $acceptance = @('catalog lists the skill', 'invoke the skill with the message', 'SKILL.md is loaded before its script')
}
elseif ($admit.decision -eq 'goal') {
    $acceptance = @('the goal keeps its source', 'skill-creator is present by default', 'the cycle does not call skill-creator')
}
else { throw "plan requires invoke or goal, not $($admit.decision)" }
$incoming = @()
if ($ResourcesPath) {
    if (-not (Test-Path -LiteralPath $ResourcesPath -PathType Leaf)) { throw 'resources file is missing' }
    $incoming = @(Get-Content -LiteralPath $ResourcesPath -Raw | ConvertFrom-Json)
}
$validated = @($incoming | Where-Object { $_.validated -eq $true } | ForEach-Object { [string]$_.id })
$dropped = @($incoming | Where-Object { $_.validated -ne $true } | ForEach-Object { [string]$_.id })
$steps = @('.agents/catalog.json') + @($validated | Where-Object { $_ -and $_ -ne '.agents/catalog.json' })
$steps = @($steps | Select-Object -Unique)
$closedAvoided = 1
if ($admit.closedRoute -and $admit.route -eq $admit.closedRoute) { $closedAvoided = 0 }
$score = [ordered]@{
    bareMinimum = 1
    catalogFirst = 1
    closedRouteAvoided = $closedAvoided
    noSkillCreatorCall = 1
    handsToMake = 1
}
$row = [ordered]@{
    seq = $events.Count + 1; phase = 'plan'; response = "I AM the $(Get-PhaseRoute plan)"; hookBefore = (Get-BeforeHook -Phase plan -Seed $admit.message); hookAfter = (Get-AfterHook -Phase plan -Seed $admit.message -Next '@maker /pmcro:make'); level = 1; loaded = @('.agents/catalog.json')
    action = $admit.decision; source = $admit.source; route = $admit.route; message = $admit.message
    skillCreator = [ordered]@{ present = $true; call = $false }
    bareMinimum = $true; steps = $steps; dropped = $dropped
    acceptance = $acceptance; score = $score; nextCall = '@maker /pmcro:make'
}
[IO.File]::AppendAllText($trail, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
Write-Output (Get-BeforeHook -Phase plan -Seed $admit.message)
Write-Output (Get-AfterHook -Phase plan -Seed $admit.message -Next '@maker /pmcro:make')
return