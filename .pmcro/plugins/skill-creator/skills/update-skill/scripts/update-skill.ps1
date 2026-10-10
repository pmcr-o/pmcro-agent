param(
    [Parameter(Mandatory = $true)][string]$Marketplace,
    [Parameter(Mandatory = $true)][string]$Plugin,
    [Parameter(Mandatory = $true)][string]$Skill,
    [Parameter(Mandatory = $true)][string]$Description
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
if ($match.Count -eq 1) { throw "registered skill is not updated here: $rel" }
$skillMd = Join-Path $root "plugins/$Plugin/skills/$Skill/SKILL.md"
if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) { throw "skill not found: $rel" }
$quoted = '"' + (($Description -replace '\\', '\\') -replace '"', '\"') + '"'
$text = [IO.File]::ReadAllText($skillMd)
$updated = [regex]::Replace($text, '(?m)^description:.*$', "description: $quoted", 1)
[IO.File]::WriteAllText($skillMd, $updated, [Text.UTF8Encoding]::new($false))
$request = Join-Path $root "plugins/$Plugin/skills/$Skill/assets/request.json"
if (Test-Path -LiteralPath $request) {
    $json = Get-Content -LiteralPath $request -Raw | ConvertFrom-Json
    $json.description = $Description
    [IO.File]::WriteAllText($request, (($json | ConvertTo-Json) + "`n"), [Text.UTF8Encoding]::new($false))
}
if ([IO.File]::ReadAllText($catalogPath) -ne $before) { throw 'catalog changed' }
Write-Output "UPDATED $rel"
return