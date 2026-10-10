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
$PSNativeCommandUseErrorActionPreference = $false
$plugins = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$setup = Join-Path $PSScriptRoot 'setup-call.ps1'
$plan = Join-Path $plugins 'pmcro-planner\skills\plan\scripts\plan-task.ps1'
$make = Join-Path $plugins 'pmcro-maker\skills\make\scripts\make-task.ps1'
$check = Join-Path $plugins 'pmcro-checker\skills\check\scripts\check-task.ps1'
$reflect = Join-Path $plugins 'pmcro-reflector\skills\reflect\scripts\reflect-task.ps1'
$call = @{ Marketplace = $Marketplace; RunId = $RunId; Source = $Source }
if ($Goal) { $call.Goal = $Goal }
if ($Plugin) { $call.Plugin = $Plugin }
if ($Skill) { $call.Skill = $Skill }
if ($FromRun) { $call.FromRun = $FromRun }
if ($Do) { $call.Do = $Do }
if ($Depth -gt 0) { $call.Depth = $Depth }
& $setup @call
& $plan -Marketplace $Marketplace -RunId $RunId
& $make -Marketplace $Marketplace -RunId $RunId
& $check -Marketplace $Marketplace -RunId $RunId
& $reflect -Marketplace $Marketplace -RunId $RunId
return