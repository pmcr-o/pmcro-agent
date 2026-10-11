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

function Get-PreviousPhase {
    param([Parameter(Mandatory = $true)][string]$Phase)
    switch ($Phase) {
        'orchestrate' { 'ROOT_OR_REFLECT' }
        'plan' { 'ORCHESTRATE' }
        'make' { 'PLAN' }
        'check' { 'MAKE' }
        'reflect' { 'CHECK' }
        default { throw "unknown phase $Phase" }
    }
}

function Get-NextPhase {
    param([Parameter(Mandatory = $true)][string]$Phase)
    switch ($Phase) {
        'orchestrate' { 'PLAN' }
        'plan' { 'MAKE' }
        'make' { 'CHECK' }
        'check' { 'REFLECT' }
        'reflect' { 'ORCHESTRATE' }
        default { throw "unknown phase $Phase" }
    }
}

function Get-BeforeHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed)
    $route = Get-PhaseRoute $Phase
    $from = Get-PreviousPhase $Phase
    $nextPhase = Get-NextPhase $Phase
    $line = "I AM the $route | ACCOUNTABILITY | PHASE=$($Phase.ToUpperInvariant()) | FROM=$from | NEXT=$nextPhase | AUTHORITY=.agents/grants.json | NO_JUMP=true"
    if ($Seed) { $line = "$line | INTENT=$Seed" }
    return $line
}

function Get-AfterHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed, [Parameter(Mandatory = $true)][string]$Next)
    if ($Phase -eq 'reflect') { $Next = Get-NextRoute reflect }
    $route = Get-PhaseRoute $Phase
    $nextPhase = Get-NextPhase $Phase
    $line = "I AM the $route | HANDOFF | NEXT_PHASE=$nextPhase | NEXT_I=$Next | NO_JUMP=true"
    if ($Seed) { $line = "$line | OBJECT=$Seed" }
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
        [int]$MetaDepth = 0,
        [string[]]$EvidenceRefs = @()
    )
    $previous = Get-PreviousPhase $Phase
    $nextPhase = Get-NextPhase $Phase
    $nextI = Get-NextRoute $Phase
    $evidence = @($EvidenceRefs)
    if ($evidence.Count -eq 0) { $evidence = @($ObjectRefs) }
    return [ordered]@{
        schema = 'pmcro.i-frame/v1'
        am = (Get-PhaseRoute $Phase)
        phase = $Phase.ToUpperInvariant()
        intentRef = $IntentRef
        intent = $Intent
        entityRef = (Get-PhaseRoute $Phase)
        behavior = $Behavior
        objectRefs = @($ObjectRefs)
        addressedI = $AddressedI
        authorityCeilingRef = $AuthorityCeilingRef
        metaDepth = $MetaDepth
        accountability = [ordered]@{
            schema = 'pmcro.accountability-frame/v1'
            phase = $Phase.ToUpperInvariant()
            allowedPrevious = $previous
            allowedNext = $nextPhase
            nextI = $nextI
            evidenceRefs = @($evidence)
            authorityCeilingRef = $AuthorityCeilingRef
            noJump = $true
        }
    }
}
Export-ModuleMember -Function Get-PhaseRoute, Get-NextRoute, Get-PreviousPhase, Get-NextPhase, Get-BeforeHook, Get-AfterHook, New-IFrame
