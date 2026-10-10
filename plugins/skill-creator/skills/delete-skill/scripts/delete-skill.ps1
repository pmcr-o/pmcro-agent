param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$Plugin,
    [Parameter(Mandatory = $true)][string]$Skill
)
$ErrorActionPreference = 'Stop'
foreach ($pair in @{ plugin = $Plugin; skill = $Skill }.GetEnumerator()) {
    if ($pair.Value -notmatch '^[a-z0-9-]+$') { throw "$($pair.Key) must be lowercase letters, digits, and hyphens" }
}
$root = (Resolve-Path -LiteralPath $Marketplace).Path
$catalogPath = Join-Path $root '.agents/catalog.json'
if (-not (Test-Path -LiteralPath $catalogPath)) { throw 'Marketplace has no .agents/catalog.json' }
$before = [IO.File]::ReadAllText($catalogPath)
$catalog = $before | ConvertFrom-Json
$match = @($catalog.skills | Where-Object { $_.id -eq $Skill -and $_.plugin -eq $Plugin })
$rel = "plugins/$Plugin/skills/$Skill"
if ($match.Count -eq 1) { Write-Output "REGISTERED $rel"; exit 2 }
$folder = Join-Path $root "plugins/$Plugin/skills/$Skill"
if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw "skill not found: $rel" }
Remove-Item -LiteralPath $folder -Recurse -Force
if ([IO.File]::ReadAllText($catalogPath) -ne $before) { throw 'catalog changed' }
& (Join-Path $PSScriptRoot 'remove-skill-configuration.ps1') -Marketplace $root -Plugin $Plugin -Skill $Skill

Write-Output "DELETED $rel"
return