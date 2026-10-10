param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$Plugin,
    [Parameter(Mandatory = $true)][string]$Skill,
    [switch]$Body
)
$ErrorActionPreference = 'Stop'
foreach ($pair in @{ plugin = $Plugin; skill = $Skill }.GetEnumerator()) {
    if ($pair.Value -notmatch '^[a-z0-9-]+$') { throw "$($pair.Key) must be lowercase letters, digits, and hyphens" }
}
$root = (Resolve-Path -LiteralPath $Marketplace).Path
$catalogPath = Join-Path $root '.agents/catalog.json'
if (-not (Test-Path -LiteralPath $catalogPath)) { throw 'Marketplace has no .agents/catalog.json' }
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$match = @($catalog.skills | Where-Object { $_.id -eq $Skill -and $_.plugin -eq $Plugin })
$rel = "plugins/$Plugin/skills/$Skill"
if ($match.Count -eq 1 -and -not $Body) {
    Write-Output "RETRIEVE $rel"
    Write-Output $match[0].description
return
}
$skillMd = Join-Path $root "plugins/$Plugin/skills/$Skill/SKILL.md"
if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) { throw "skill not found: $rel" }
$text = Get-Content -LiteralPath $skillMd -Raw
$description = if ($text -match '(?m)^description:\s*(.+)\s*$') { $Matches[1].Trim().Trim('"') } else { '' }
Write-Output "RETRIEVE $rel"
Write-Output $description
if ($Body) { Write-Output 'BODY' }
return