$ErrorActionPreference = 'Stop'

function Get-PhaseRoute {
    param([Parameter(Mandatory = $true)][string]$Phase)
    switch ($Phase) {
        'orchestrate' { '@orchestrator /pmcro:orchestrate' }
        'plan' { '@planner /pmcro:plan' }
        'make' { '@maker /pmcro:make' }
        'check' { '@checker /pmcro:check' }
        'reflect' { '@reflector /pmcro:reflect' }
        default { throw "unknown phase $Phase" }
    }
}

function Get-BeforeHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed)
    $route = Get-PhaseRoute $Phase
    if ($Seed) { "I AM the $route $Seed" } else { "I AM the $route" }
}

function Get-AfterHook {
    param([Parameter(Mandatory = $true)][string]$Phase, [string]$Seed, [Parameter(Mandatory = $true)][string]$Next)
    if ($Seed) { "$Seed next $Next" } else { "next $Next" }
}

Export-ModuleMember -Function Get-PhaseRoute, Get-BeforeHook, Get-AfterHook
