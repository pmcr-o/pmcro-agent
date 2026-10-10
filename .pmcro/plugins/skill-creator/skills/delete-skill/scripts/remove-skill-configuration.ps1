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
$dir = Join-Path $root '.mcp'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$path = Join-Path $dir 'skill_configuration.json'
$rows = @()
if (Test-Path -LiteralPath $path) {
    $doc = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $rows = @($doc.configurations | Where-Object { $_.plugin -and $_.skill })
}
$before = @($rows).Count
$kept = @($rows | Where-Object { -not ($_.plugin -eq $Plugin -and $_.skill -eq $Skill) })
$removed = $before - $kept.Count
$out = [ordered]@{ configurations = @($kept) }
[IO.File]::WriteAllText($path, (($out | ConvertTo-Json -Depth 5) + "`n"), [Text.UTF8Encoding]::new($false))
Write-Output "TRIGGER mcp.postgres remove_skill_configuration plugins/$Plugin/skills/$Skill removed=$removed"
return