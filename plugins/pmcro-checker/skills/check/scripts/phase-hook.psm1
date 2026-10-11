$ErrorActionPreference = 'Stop'

function Get-PhaseRoute {
    param([Parameter(Mandatory = $true)][string]$Phase)
    switch ($Phase) {
        'orchestrate' { '@orchestrator /pmcro-orchestrator:orchestrate' }
        'plan' { '@planner /pmcro-planner:plan' }
        'make' { '@maker /pmcro-maker:make' }
        'check' { '@checker /pmcro-checker:check' }
        'reflect' { '@reflector /pmcro-reflector:reflect' }
        default { throw "unknown phase $Phase" }
    }
}

function Get-NextRoute {
    param([Parameter(Mandatory = $true)][string]$Phase)
    switch ($Phase) {
        'orchestrate' { Get-PhaseRoute plan }
        'plan' { Get-PhaseRoute make }
        'make' { Get-PhaseRoute check }
        'check' { Get-PhaseRoute reflect }
        'reflect' { Get-PhaseRoute orchestrate }
        default { throw "unknown phase $Phase" }
    }
}

function Get-BeforeHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed)
    $line = "I AM the $(Get-PhaseRoute $Phase)"
    if ($Seed) { $line = "$line $Seed" }
    if ($Phase -eq 'reflect') { $line = "$line trigger $(Get-PhaseRoute orchestrate)" }
    return $line
}

function Get-AfterHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed, [Parameter(Mandatory = $true)][string]$Next)
    if ($Phase -eq 'reflect') { $Next = Get-NextRoute reflect }
    $line = if ($Seed) { "$Seed next $Next" } else { "next $Next" }
    if ($Phase -eq 'reflect') { $line = "$line trigger $(Get-PhaseRoute orchestrate)" }
    return $line
}


function New-IFrame {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('orchestrate','plan','make','check','reflect')][string]$Phase,
        [Parameter(Mandatory = $true)][string]$IntentRef,
        [Parameter(Mandatory = $true)][string]$Intent,
        [Parameter(Mandatory = $true)][string]$Behavior,
        [string[]]$ObjectRefs = @(),
        [string]$AddressedI,
        [string]$AuthorityCeilingRef = '.agents/grants.json',
        [int]$MetaDepth = 0
    )
    return [ordered]@{
        schema = 'pmcro.i-frame/v1'
        am = (Get-PhaseRoute $Phase)
        intentRef = $IntentRef
        intent = $Intent
        entityRef = (Get-PhaseRoute $Phase)
        behavior = $Behavior
        objectRefs = @($ObjectRefs)
        addressedI = $AddressedI
        authorityCeilingRef = $AuthorityCeilingRef
        metaDepth = $MetaDepth
    }
}
Export-ModuleMember -Function Get-PhaseRoute, Get-NextRoute, Get-BeforeHook, Get-AfterHook, New-IFrame
