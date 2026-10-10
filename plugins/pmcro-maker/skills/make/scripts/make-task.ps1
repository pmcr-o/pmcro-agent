param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$RunId
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'phase-hook.psm1') -Force
$market = (Resolve-Path -LiteralPath $Marketplace).Path
$trail = Join-Path $market ".pmcro/trails/$RunId.jsonl"
if (-not (Test-Path -LiteralPath $trail)) { throw "missing call trail $RunId" }
$events = @(Get-Content -LiteralPath $trail | ForEach-Object { $_ | ConvertFrom-Json })
$plan = $events | Where-Object { $_.phase -eq 'plan' } | Select-Object -First 1
if (-not $plan) { throw 'make requires a plan' }
if (@($events | Where-Object { $_.phase -eq 'make' }).Count -gt 0) { throw 'make already recorded' }
$admit = $events | Where-Object { $_.phase -eq 'orchestrate' } | Select-Object -First 1
$seed = [string]$admit.message
$before = Get-BeforeHook -Phase make -Seed $seed
$after = Get-AfterHook -Phase make -Seed $seed -Next (Get-NextRoute make)
$response = "I AM the $(Get-PhaseRoute make)"
Write-Output $before
$utf8 = [Text.UTF8Encoding]::new($false)
try {
    if ($plan.action -eq 'goal') {
        $seq = $events.Count + 1
        $carried = [int]($admit.message -and $plan.message -eq $admit.message)
        $generated = ''
        if ($admit.reason -eq 'marketplace trail') {
            $system = Split-Path -Parent $market
            if (-not (Test-Path -LiteralPath (Join-Path $system 'catalog.json'))) { throw 'marketplace trail requires the system catalog' }
            $orchestrators = New-Object System.Collections.Generic.List[object]
            $rootFiles = @(Get-ChildItem -LiteralPath $system -Force -File | ForEach-Object { $_.Name } | Sort-Object)
            $orchestrators.Add([pscustomobject]@{ folder = 'marketplace'; subagents = @($rootFiles) })
            foreach ($dir in @(Get-ChildItem -LiteralPath $system -Force -Directory | Sort-Object Name)) {
                $files = @(Get-ChildItem -LiteralPath $dir.FullName -Force -File | ForEach-Object { $_.Name } | Sort-Object)
                $orchestrators.Add([pscustomobject]@{ folder = $dir.Name; subagents = @($files) })
            }
            $generated = ".pmcro/trails/$RunId-skill.json"
            $blocks = New-Object System.Collections.Generic.List[string]
            foreach ($item in $orchestrators) {
                $names = @($item.subagents | ForEach-Object { '"' + (($_ -replace '\\', '\\') -replace '"', '\"') + '"' })
                $blocks.Add(('{"folder":"' + $item.folder + '","subagents":[' + ($names -join ',') + ']}'))
            }
            $skillMessage = 'The marketplace trail names each folder as an orchestrator and each file in it as a subagent.'
            $doc = '{"skill":"marketplace-trail","message":"' + $skillMessage + '","orchestrators":[' + ($blocks -join ',') + ']}'
            $outFile = Join-Path $market ($generated.Replace('/', [IO.Path]::DirectorySeparatorChar))
            [IO.File]::WriteAllText($outFile, ($doc + "`n"), $utf8)
        }
        $row = [ordered]@{
            seq = $seq; phase = 'make'; response = $response; hookBefore = $before; hookAfter = $after
            level = 1; loaded = @('.agents/catalog.json')
            goal = $admit.goal; source = $admit.source; message = $admit.message
            skillCreator = [ordered]@{ present = $true; operations = @('create', 'read', 'update', 'delete'); call = $false }
            score = [ordered]@{ followedPlan = 1; carriedMessage = $carried; bodyStayedClosed = 1; noSkillCreatorCall = 1 }
            handoff = 'CHECKER REQUIRED'; nextCall = (Get-NextRoute make)
        }
        if ($generated) { $row.generated = $generated; $row.nextSkill = $generated }
        [IO.File]::AppendAllText($trail, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), $utf8)
        Write-Output $after
return
    }
    if ($plan.action -ne 'invoke') { throw "make requires invoke or goal, not $($plan.action)" }
    Import-Module (Join-Path $PSScriptRoot 'disclosure.psm1') -Force
    Initialize-Disclosure $market
    Open-Disclosure 1 '.agents/catalog.json' | Out-Null
    $skillMd = "plugins/$($admit.plugin)/skills/$($admit.skill)/SKILL.md"
    Open-Disclosure 2 $skillMd | Out-Null
    $validate = "plugins/$($admit.plugin)/skills/$($admit.skill)/scripts/validate.ps1"
    Open-Disclosure 3 $validate | Out-Null
    & (Join-Path $market ($validate.Replace('/', [IO.Path]::DirectorySeparatorChar))) | Out-Null

    $seq = $events.Count
    $seq++
    $body = [ordered]@{
        seq = $seq; phase = 'make'; response = $response; hookBefore = $before; hookAfter = $after
        level = 2; loaded = @($skillMd); skillBody = $skillMd
        invoke = $admit.route; message = $admit.message
        score = [ordered]@{ followedPlan = 1; carriedMessage = 1; bodyOpened = 1; noSkillCreatorCall = 1 }
        nextCall = (Get-PhaseRoute make)
    }
    [IO.File]::AppendAllText($trail, (($body | ConvertTo-Json -Compress -Depth 6) + "`n"), $utf8)
    $seq++
    $script = [ordered]@{
        seq = $seq; phase = 'make'; response = $response; hookBefore = $before; hookAfter = $after
        level = 3; loaded = @($validate); script = $validate
        exitCode = 0; handoff = 'CHECKER REQUIRED'; nextCall = (Get-NextRoute make)
    }
    [IO.File]::AppendAllText($trail, (($script | ConvertTo-Json -Compress -Depth 6) + "`n"), $utf8)
    Write-Output $after
return
}
catch {
    $err = $_.Exception.Message
    $seq = $events.Count + 1
    $row = [ordered]@{
        seq = $seq; phase = 'make'; response = $response; hookBefore = $before; hookAfter = $after
        level = 1; loaded = @('.agents/catalog.json')
        goal = $admit.goal; source = $admit.source; message = $admit.message
        error = $err
        skillCreator = [ordered]@{ present = $true; operations = @('create', 'read', 'update', 'delete'); call = $false }
        score = [ordered]@{ followedPlan = 0; carriedMessage = 1; bodyStayedClosed = 1; noSkillCreatorCall = 1 }
        handoff = 'CHECKER REQUIRED'; nextCall = (Get-NextRoute make)
    }
    [IO.File]::AppendAllText($trail, (($row | ConvertTo-Json -Compress -Depth 6) + "`n"), $utf8)
    Write-Output "MAKER ERROR $err"
    Write-Output $after
return
}
