from __future__ import annotations
import argparse,json,re
from pathlib import Path

def project_id(name:str)->str:
    value=re.sub(r'[^a-z0-9]+','-',name.lower()).strip('-')
    return value or 'project'

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--target',required=True);ap.add_argument('--output');a=ap.parse_args()
    target=Path(a.target).resolve()
    if not target.is_dir(): raise SystemExit('target directory does not exist')
    detected=[]
    if any(target.glob('*.sln')) or any(target.rglob('*.csproj')):detected.append('dotnet-agent')
    if (target/'.github').exists():detected.append('github-agent')
    if (target/'Dockerfile').is_file() or any(target.rglob('Dockerfile')):detected.append('docker-agent')
    if any(target.rglob('*.ps1')):detected.append('powershell-agent')
    state={
      'schema':'pmcro.project.setup/v1','target':str(target),'projectId':project_id(target.name),
      'gitRepository':(target/'.git').exists(),'existing':{x:(target/x).exists() for x in ['.pmcro','.agents','.claude','.grok','.cursor','.github']},
      'detectedDomainAgents':sorted(set(detected)),'recommendedRoute':'@pmcro-agent /pmcro-project:integrate-project',
      'mutation':False,'next':'run integrate-project dry-run, inspect conflicts, then apply explicitly'}
    text=json.dumps(state,indent=2)
    if a.output: Path(a.output).write_text(text+'\n',encoding='utf-8')
    print(text)
if __name__=='__main__':main()
