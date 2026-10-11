param()
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
foreach($rel in @('SKILL.md','agents/intent-refinement-agent.md','scripts/operate.py','references/contract.md','assets/intent-refinement.schema.json','assets/request.json','tests/fixture.json')){if(-not(Test-Path -LiteralPath (Join-Path $root $rel) -PathType Leaf)){throw "missing $rel"}}
python (Join-Path $PSScriptRoot 'operate.py') validate --input (Join-Path $root 'tests/fixture.json')
if($LASTEXITCODE -ne 0){throw 'fixture validation failed'}
'PASS'
