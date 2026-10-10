param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][ValidateSet('intent', 'trail', 'catalog', 'loop')][string]$Source,
    [string]$Goal,
    [string]$Plugin,
    [string]$Skill,
    [string]$FromRun,
    [string[]]$Do,
    [int]$Depth = 0
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'phase-hook.psm1') -Force
if ($RunId -notmatch '^[A-Za-z0-9-]+$') { throw 'RunId must be a simple name' }
if (-not (Test-Path -LiteralPath (Join-Path $Marketplace '.agents/catalog.json'))) { throw 'Marketplace has no .agents/catalog.json' }
$market = (Resolve-Path -LiteralPath $Marketplace).Path
Import-Module (Join-Path $PSScriptRoot 'disclosure.psm1') -Force
Initialize-Disclosure $market
$trail = Join-Path $market ".pmcro/trails/$RunId.jsonl"
if (Test-Path -LiteralPath $trail) { throw "append-only: $RunId already exists" }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $trail) | Out-Null
$catalog = (Open-Disclosure 1 '.agents/catalog.json') | ConvertFrom-Json
$metaIn = 0
$choose = $false
$invokeNamed = $false
$leaveClosed = $false
$marketplaceTrail = @($Do) -contains 'log the trail at the marketplace'
$closedRoute = ''
$priorIntent = ''
if ($Source -eq 'intent' -or $Source -eq 'loop') {
    if (-not $Goal) { throw "$Source requires a goal" }
    $message = $Goal
}
elseif ($Source -eq 'catalog') {
    $message = 'High-level goal from the skill catalog.'
}
else {
    if ($FromRun -notmatch '^[A-Za-z0-9-]+$') { throw 'FromRun must be a simple name' }
    $reflectPath = Join-Path $market ".pmcro/trails/$FromRun-reflect.jsonl"
    $callPath = Join-Path $market ".pmcro/trails/$FromRun.jsonl"
    $metaIn = 0
    if (Test-Path -LiteralPath $reflectPath) {
        $prior = Get-Content -LiteralPath $reflectPath -Raw | ConvertFrom-Json
        if ($prior.nextSeed.intent) {
            $message = [string]$prior.nextSeed.intent
            $priorIntent = $message
            $metaIn = [int]$prior.nextSeed.depth
            $closedRoute = [string]$prior.nextSeed.closedRoute
            $choose = @($prior.nextSeed.do | Where-Object { "$_" -like 'choose one listed skill*' }).Count -gt 0
            $invokeNamed = @($prior.nextSeed.do) -contains 'invoke the named route'
            $leaveClosed = @($prior.nextSeed.do) -contains 'leave the route closed'
            if (@($prior.nextSeed.do) -contains 'log the trail at the marketplace') { $marketplaceTrail = $true }
            if ($leaveClosed -and (Test-Path -LiteralPath $callPath)) {
                $priorEvents = @(Get-Content -LiteralPath $callPath | ForEach-Object { $_ | ConvertFrom-Json })
                $priorAdmit = $priorEvents | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
                if ($priorAdmit.plugin -and $priorAdmit.skill) {
                    $Plugin = [string]$priorAdmit.plugin
                    $Skill = [string]$priorAdmit.skill
                }
            }
            if ($invokeNamed -and (Test-Path -LiteralPath $callPath)) {
                $priorEvents = @(Get-Content -LiteralPath $callPath | ForEach-Object { $_ | ConvertFrom-Json })
                $priorAdmit = $priorEvents | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
                if ($priorAdmit.plugin -and $priorAdmit.skill) {
                    $Plugin = [string]$priorAdmit.plugin
                    $Skill = [string]$priorAdmit.skill
                    $message = [string]$priorAdmit.message
                }
            }
        }
        elseif ($prior.nextSeed.goal) { $message = $prior.nextSeed.goal }
        else { $message = $prior.nextSeed.message }
    }
    elseif (Test-Path -LiteralPath $callPath) {
        $priorEvents = @(Get-Content -LiteralPath $callPath | ForEach-Object { $_ | ConvertFrom-Json })
        $message = @($priorEvents | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1).message
    }
    else { throw "trail $FromRun has no goal" }
    if (-not $message) { throw "trail $FromRun has no goal" }
}
if ($Source -eq 'intent' -and $Depth -gt 0) { $metaIn = $Depth }
$known = [ordered]@{ present = $true; operations = @('create', 'read', 'update', 'delete'); call = $false }
$named = $false
$updatedIntent = ''
if ($choose -and -not $marketplaceTrail) {
    $picked = @($catalog.skills | Where-Object {
        -not $closedRoute -or ("@orchestrator /$($_.plugin):$($_.id)" -ne $closedRoute)
    } | Select-Object -First 1)
    if ($picked.Count -eq 1) {
        $Plugin = [string]$picked[0].plugin
        $Skill = [string]$picked[0].id
        $message = [string]$picked[0].description
        $updatedIntent = "Name @orchestrator /${Plugin}:${Skill} and carry its catalog message."
        $named = $true
    }
}
$match = @()
if ($Plugin -and $Skill) { $match = @($catalog.skills | Where-Object { $_.id -eq $Skill -and $_.plugin -eq $Plugin }) }
if ($marketplaceTrail) {
    $decision = 'goal'
    $reason = 'marketplace trail'
    $route = ''
    $Plugin = ''
    $Skill = ''
}
elseif ($match.Count -eq 1 -and -not $named -and -not $leaveClosed) {
    $decision = 'invoke'
    $reason = 'catalog lists the skill'
    $route = "@orchestrator /${Plugin}:${Skill}"
}
else {
    $decision = 'goal'
    if ($leaveClosed -and $Plugin -and $Skill) {
        $reason = 'route stays closed'
        $route = "@orchestrator /${Plugin}:${Skill}"
    }
    elseif ($named) {
        $reason = 'catalog names the skill and its message'
        $route = "@orchestrator /${Plugin}:${Skill}"
    }
    else {
        $reason = 'skill-creator exists by default, so the cycle does not call it'
        $route = ''
    }
}
$row = [ordered]@{
    seq = 1; phase = 'orchestrate'; response = "I AM the $(Get-PhaseRoute orchestrate)"; hookBefore = (Get-BeforeHook -Phase orchestrate -Seed $message); hookAfter = (Get-AfterHook -Phase orchestrate -Seed $message -Next (Get-NextRoute orchestrate)); level = 1; loaded = @('.agents/catalog.json')
    decision = $decision; source = $Source; goal = $(if ($updatedIntent) { $updatedIntent } else { $message }); message = $message
    plugin = $Plugin; skill = $Skill; reason = $reason; route = $route
    skillCreator = $known; nextCall = (Get-NextRoute orchestrate)
}
if ($Source -eq 'trail') { $row.fromRun = $FromRun }
if ($metaIn) { $row.meta = $metaIn }
if ($priorIntent) { $row.priorIntent = $priorIntent }
if ($updatedIntent) { $row.updatedIntent = $updatedIntent }
if ($closedRoute) { $row.closedRoute = $closedRoute }
[IO.File]::WriteAllText($trail, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
Write-Output (Get-BeforeHook -Phase orchestrate -Seed $message)
Write-Output (Get-AfterHook -Phase orchestrate -Seed $message -Next (Get-NextRoute orchestrate))
return