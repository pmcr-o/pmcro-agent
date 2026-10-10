param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$text = Get-Content -LiteralPath $Path -Raw
if ($text -match 'agent_control_specification_version') { Write-Output 'SYNTHESIS-REFUSED'; exit 2 }
if ($text -notmatch 'pmcro\.workflow\.v1') { Write-Output 'NOT-WORKFLOW'; exit 2 }
if ($text -match 'synthesizeAcsPolicy:\s*true') { Write-Output 'SYNTHESIS-REFUSED'; exit 2 }
Write-Output 'WORKFLOW-OK'
return