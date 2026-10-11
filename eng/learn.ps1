[CmdletBinding()]
param(
  [ValidateSet('list','run','reset')][string]$Action='list',
  [string]$Module='',
  [string]$GithubAgentPath=''
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$config=Get-Content -LiteralPath (Join-Path $root '.pmcro\learning\modules.json') -Raw|ConvertFrom-Json
$receiptDir=Join-Path $root '.pmcro\learning\receipts'
$webProgress=Join-Path $root 'docs\data\progress.local.json'
New-Item -ItemType Directory -Force -Path $receiptDir | Out-Null
function Receipt([string]$id){Join-Path $receiptDir ($id+'.json')}
function Passed([string]$id){Test-Path -LiteralPath (Receipt $id) -PathType Leaf}
function Available($m){foreach($p in @($m.prerequisites)){if(-not(Passed $p)){return $false}};return $true}
function Write-WebProgress {
  $rows=@();foreach($m in $config.modules){$state=if(Passed $m.id){'PASS'}elseif(Available $m){'AVAILABLE'}else{'LOCKED'};$rows += [ordered]@{id=$m.id;title=$m.title;state=$state;job=$m.job;teaches=$m.teaches}}
  $o=[ordered]@{schema='pmcro.learning.progress/v1';updatedAt=[DateTimeOffset]::UtcNow.ToString('o');modules=$rows}
  [IO.File]::WriteAllText($webProgress,($o|ConvertTo-Json -Depth 8)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
}
function Resolve-GithubAgent {
  $candidates=@()
  if($GithubAgentPath){$candidates += $GithubAgentPath}
  if($env:PMCRO_GITHUB_AGENT){$candidates += $env:PMCRO_GITHUB_AGENT}
  $external=Join-Path $root '.pmcro\control\external-agents.json'
  if(Test-Path -LiteralPath $external){
    $row=(Get-Content -LiteralPath $external -Raw|ConvertFrom-Json).agents|Where-Object {$_.id -eq 'github-agent' -and $_.status -eq 'CONFIRMED'}|Select-Object -First 1
    if($row -and $row.localPath){$candidates += [string]$row.localPath}
  }
  $parent=Split-Path -Parent $root
  $candidates += (Join-Path $parent 'github-agent')
  $grand=Split-Path -Parent $parent
  if($grand){$candidates += (Join-Path $grand 'github-agent')}
  foreach($candidate in $candidates){
    if(-not $candidate){continue}
    $p=[IO.Path]::GetFullPath($candidate)
    $script=Join-Path $p '.pmcro\plugins\github\skills\local-actions\scripts\operate.ps1'
    if(Test-Path -LiteralPath $script -PathType Leaf){return [pscustomobject]@{Root=$p;Script=$script}}
  }
  throw 'github-agent/local-actions is required for local lesson execution. Integrate or connect github-agent, or pass -GithubAgentPath.'
}
if($Action -eq 'reset'){
  Get-ChildItem -LiteralPath $receiptDir -Filter '*.json' -File -ErrorAction SilentlyContinue|Remove-Item -Force
  if(Test-Path $webProgress){Remove-Item $webProgress -Force};Write-Output 'LEARNING-RESET';return
}
if($Action -eq 'list'){
  foreach($m in $config.modules){$state=if(Passed $m.id){'PASS'}elseif(Available $m){'AVAILABLE'}else{'LOCKED'};[pscustomobject]@{Module=$m.id;State=$state;Job=$m.job;Title=$m.title}}
  Write-WebProgress;return
}
$m=@($config.modules|Where-Object {$_.id -eq $Module})
if($m.Count -ne 1){throw "unknown module: $Module"};$m=$m[0]
if(-not(Available $m)){throw "module locked; pass prerequisites first: $(@($m.prerequisites)-join ', ')"}
$github=Resolve-GithubAgent
$executionRoot=Join-Path ([IO.Path]::GetTempPath()) ('pmcro-learning-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $executionRoot | Out-Null
try {
  Get-ChildItem -LiteralPath $root -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $executionRoot -Recurse -Force }
  $git=Get-Command git -ErrorAction Stop
  & $git.Source -C $executionRoot init -q
  & $git.Source -C $executionRoot config user.email 'pmcro-learning@local.invalid'
  & $git.Source -C $executionRoot config user.name 'PMCR-O Learning I'
  & $git.Source -C $executionRoot add -A
  & $git.Source -C $executionRoot commit -q -m 'PMCR-O learning execution snapshot'
  if($LASTEXITCODE -ne 0){throw 'ephemeral learning Git snapshot commit failed'}
  $evidence=& $github.Script -Operation run -Workspace $executionRoot -Workflow '.github/workflows/learn.yml' -Job $m.job -Event workflow_dispatch -Apply
} finally {
  if(Test-Path -LiteralPath $executionRoot){Remove-Item -LiteralPath $executionRoot -Recurse -Force -ErrorAction SilentlyContinue}
}
$head='UNPUBLISHED-BUILD'; try{$top=(git -C $root rev-parse --show-toplevel 2>$null).Trim();if($top -and ([IO.Path]::GetFullPath($top).TrimEnd([IO.Path]::DirectorySeparatorChar) -eq [IO.Path]::GetFullPath($root).TrimEnd([IO.Path]::DirectorySeparatorChar))){$head=(git -C $root rev-parse HEAD).Trim()}}catch{};$workflowHash=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root '.github\workflows\learn.yml')).Hash.ToLowerInvariant()
$receipt=[ordered]@{schema='pmcro.learning.receipt/v1';module=$m.id;job=$m.job;verdict='PASS';runner='@github-agent /github:local-actions';executionIsolation='ephemeral-git-snapshot';githubAgent=$github.Root;gitCommit=$head;workflowSha256=$workflowHash;completedAt=[DateTimeOffset]::UtcNow.ToString('o');evidence=@($evidence)}
[IO.File]::WriteAllText((Receipt $m.id),($receipt|ConvertTo-Json -Depth 12)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
Write-WebProgress;Write-Output "UNLOCKED $($m.id)"
