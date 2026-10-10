$ErrorActionPreference = 'Stop'

function Initialize-Disclosure([string]$Root) {
    $script:DisclosureRoot = (Resolve-Path -LiteralPath $Root).Path
    $script:DisclosureLevel1 = $false
    $script:DisclosureLevel2 = @{}
}

function Open-Disclosure([int]$Level, [string]$Relative) {
    if (-not $script:DisclosureRoot) { throw 'disclosure is not initialized' }
    $relative = ($Relative -replace '\\', '/')
    $full = Join-Path $script:DisclosureRoot ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)
    if ($Level -eq 1) {
        if ($relative -ne '.agents/catalog.json' -and $relative -ne '.agents/index.json') {
            throw "level 1 may only open the catalog or index, not $relative"
        }
        $script:DisclosureLevel1 = $true
    }
    elseif ($Level -eq 2) {
        if (-not $script:DisclosureLevel1) { throw 'level 2 was opened before the catalog' }
        if ($relative -notmatch '/SKILL\.md$') { throw "level 2 is a SKILL.md, not $relative" }
        $script:DisclosureLevel2[$relative] = $true
    }
    elseif ($Level -eq 3) {
        if ($relative -notmatch '^(?<skill>.+)/(?:references|scripts)/[^/]+$') {
            throw "level 3 must be a references or scripts file, not $relative"
        }
        $skillMd = $Matches.skill + '/SKILL.md'
        if (-not $script:DisclosureLevel2.ContainsKey($skillMd)) {
            throw "level 3 opened before SKILL.md: $relative"
        }
    }
    else { throw "unknown disclosure level $Level" }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "missing disclosed file $relative" }
    return [IO.File]::ReadAllText($full)
}

Export-ModuleMember -Function Initialize-Disclosure, Open-Disclosure
