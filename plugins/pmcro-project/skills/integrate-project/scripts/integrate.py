from __future__ import annotations
import argparse,hashlib,json,re,shutil,sys
from pathlib import Path

CORE_PLUGINS=['pmcro','pmcro-orchestrator','pmcro-planner','pmcro-maker','pmcro-checker','pmcro-reflector','pmcro-governance','skill-creator','pmcro-project']
CONTROL_COPY=['routing.json','lifecycle.json','grants.json','capabilities.json','queue.json']
RUNTIME_DIRS=['.pmcro/trails','.pmcro/requests','.pmcro/runtime','.pmcro/queue/inbox','.pmcro/queue/processing','.pmcro/queue/delayed','.pmcro/queue/completed','.pmcro/queue/dead-letter','.pmcro/queue/state','.pmcro/queue/receipts','.pmcro/queue/tmp']

def load(p:Path):return json.loads(p.read_text(encoding='utf-8-sig'))
def dump(v):return (json.dumps(v,indent=2,ensure_ascii=False)+'\n').encode()
def pid(name:str):return re.sub(r'[^a-z0-9]+','-',name.lower()).strip('-') or 'project'
def desc(skill:Path):
    text=(skill/'SKILL.md').read_text(encoding='utf-8-sig');m=re.search(r'(?m)^description:\s*(.+)$',text)
    return m.group(1).strip().strip('"\'') if m else skill.name

def find_source(explicit:str|None)->Path:
    if explicit:
        p=Path(explicit).resolve()
        if (p/'.pmcro/control/project.json').is_file():return p
        raise SystemExit('source is not a PMCR-O agent repository')
    here=Path(__file__).resolve()
    for p in [here,*here.parents]:
        meta=p/'.pmcro/control/project.json'
        if meta.is_file():
            try:
                if load(meta).get('id')=='pmcro-agent':return p
            except Exception:pass
    raise SystemExit('pmcro-agent source root not found; pass --source')

def bytes_tree(source:Path,target_prefix:Path):
    out={}
    for p in sorted(x for x in source.rglob('*') if x.is_file()):out[target_prefix/p.relative_to(source)]=p.read_bytes()
    return out

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--target',required=True);ap.add_argument('--source');ap.add_argument('--apply',action='store_true');a=ap.parse_args()
    target=Path(a.target).resolve();source=find_source(a.source)
    if not target.is_dir():raise SystemExit('target directory does not exist')
    project=pid(target.name); managed={}
    # Canonical plugins and root plugin projection used by disclosure scripts.
    for plugin in CORE_PLUGINS:
        src=source/'.pmcro/plugins'/plugin
        if not src.is_dir():raise SystemExit(f'source missing core plugin: {plugin}')
        managed.update(bytes_tree(src,Path('.pmcro/plugins')/plugin));managed.update(bytes_tree(src,Path('plugins')/plugin))
    # Protocol + queue executable/config surfaces, excluding delivery state.
    for rel in ['.pmcro/protocol','.pmcro/queue/scripts','.pmcro/queue/schemas','.pmcro/queue/tests']:
        src=source/rel
        if src.is_dir():managed.update(bytes_tree(src,Path(rel)))
    for rel in ['.pmcro/queue/config.json','.pmcro/queue/README.md']:
        src=source/rel
        if src.is_file():managed[Path(rel)]=src.read_bytes()
    # Control plane customized to this project.
    for name in CONTROL_COPY:
        src=source/'.pmcro/control'/name
        if src.is_file():
            data=load(src)
            if isinstance(data,dict) and 'agent' in data:data['agent']=project+'-agent'
            managed[Path('.pmcro/control')/name]=dump(data)
    skills=[]
    for plugin in CORE_PLUGINS:
        for s in sorted((source/'.pmcro/plugins'/plugin/'skills').iterdir() if (source/'.pmcro/plugins'/plugin/'skills').is_dir() else []):
            if s.is_dir() and (s/'SKILL.md').is_file():skills.append({'id':s.name,'plugin':plugin,'description':desc(s)})
    catalog={'apiVersion':'pmcro.dev/v1','kind':'agent.catalog','id':project+'-agent','authority':'read-only discovery; execution requires route + grant + runtime','skills':skills}
    index={'apiVersion':'pmcro.dev/v1','kind':'agent.index','agent':project+'-agent','entries':[{'route':f'@{project}-agent /{x["plugin"]}:{x["id"]}','plugin':x['plugin'],'skill':x['id'],'description':x['description'],'path':f'.pmcro/plugins/{x["plugin"]}/skills/{x["id"]}'} for x in skills]}
    project_meta={'schema':'pmcro.agent-project/v1','id':project+'-agent','description':f'PMCR-O integrated project orchestrator for {target.name}.','derivedFrom':'pmcro-agent','template':'pmcro-agent','canonical':'.pmcro','projection':'.agents','orchestratorRole':'project-orchestrator','agentIsOrchestrator':True,'hostChain':'.claude/.grok/.cursor/.github -> .agents -> .pmcro','integrated':True,'requiredSkillShape':['SKILL.md','agents/','scripts/','references/','assets/','tests/'],'autonomousLoop':{'enabled':True,'questionGate':False,'onQuestion':'resolve-from-context-or-halt','phaseOrder':['orchestrate','plan','make','check','reflect']}}
    marketplace={'name':project+'-agent','owner':{'name':project},'metadata':{'description':project_meta['description']},'plugins':[{'name':p,'source':f'./plugins/{p}'} for p in CORE_PLUGINS]}
    manifest={'schema':'dotagents.manifest/v1','name':project+'-agent','owner':project,'invocationField':'plugin','canonical':'.pmcro','projection':'.agents','plugins':marketplace['plugins']}
    managed[Path('.pmcro/control/catalog.json')]=dump(catalog);managed[Path('.pmcro/control/index.json')]=dump(index);managed[Path('.pmcro/control/project.json')]=dump(project_meta);managed[Path('.pmcro/control/marketplace.json')]=dump(marketplace);managed[Path('.pmcro/control/dotagents.manifest.json')]=dump(manifest)
    # External domain registry by reference only.
    eco=source/'.pmcro/control/ecosystem.json';agents=[]
    if eco.is_file():
        for row in load(eco).get('agents',[]):
            if row.get('id') in {'pmcro-agent','agent-skills-template'}:continue
            resolved=None
            for candidate in [source.parent/row['id'],source.parent.parent/row['id']]:
                meta=candidate/'.pmcro/control/project.json'
                if meta.is_file():
                    try:
                        if load(meta).get('id')==row['id']:resolved=candidate;break
                    except Exception:pass
            agents.append({'id':row['id'],'role':row.get('role','domain-orchestrator'),'status':'CONFIRMED' if resolved else 'UNRESOLVED','localPath':str(resolved) if resolved else None})
    managed[Path('.pmcro/control/external-agents.json')]=dump({'schema':'pmcro.external-agents/v1','project':project+'-agent','resolution':'explicit path or connected marketplace required','agents':agents})
    managed[Path('.pmcro/agents')/(project+'-agent.json')]=dump({'apiVersion':'pmcro.dev/v1','kind':'agent','id':project+'-agent','role':'project-orchestrator','agentIsOrchestrator':True,'independentSurface':True,'independentChecker':False,'canonical':'.pmcro','catalog':'.agents/catalog.json'})
    # Materialized .agents + host views. Existing unrelated host files are preserved.
    projection_names=['catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json','capabilities.json','queue.json','external-agents.json']
    for name in projection_names:
        cpath=Path('.pmcro/control')/name
        if cpath in managed:content=managed[cpath]
        else:
            src=source/'.pmcro/control'/name
            if not src.is_file():continue
            data=load(src)
            if isinstance(data,dict) and 'agent' in data:data['agent']=project+'-agent'
            content=dump(data);managed[cpath]=content
        managed[Path('.agents')/name]=content
        for host in ['.claude','.grok','.cursor','.github']:managed[Path(host)/name]=content
    managed[Path('.agents/README.md')]=b'# .agents projection\n\nGenerated from `.pmcro`; no independent authority.\n'
    for host in ['.claude','.grok','.cursor','.github']:
        managed[Path(host)/'README.md']=(f'# {host} PMCR-O host surface\n\nAuthority: `{host} -> .agents -> .pmcro`.\n').encode()
        managed[Path(host)/'STRUCTURE.md']=(f'# Structure\n\n`{host} -> .agents -> .pmcro`\n').encode()
    # Project integration record.
    managed[Path('.pmcro/control/integration.json')]=dump({'schema':'pmcro.project.integration/v1','projectId':project+'-agent','source':'pmcro-agent','managedFiles':len(managed),'externalAgents':len(agents),'preserveUnknownFiles':True})
    conflicts=[];creates=[];same=[]
    for rel,content in managed.items():
        dest=target/rel
        if dest.is_file():
            if dest.read_bytes()==content:same.append(rel.as_posix())
            else:conflicts.append(rel.as_posix())
        elif dest.exists():conflicts.append(rel.as_posix())
        else:creates.append(rel.as_posix())
    result={'schema':'pmcro.project.integration.plan/v1','target':str(target),'projectId':project+'-agent','source':str(source),'apply':a.apply,'creates':creates,'unchanged':same,'conflicts':conflicts,'externalAgents':agents}
    if conflicts:
        print(json.dumps(result,indent=2));raise SystemExit('integration conflicts must be reconciled before apply')
    if not a.apply:
        print(json.dumps(result,indent=2));return
    for rel,content in managed.items():
        dest=target/rel
        if dest.exists():continue
        dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(content)
    for rel in RUNTIME_DIRS:(target/rel).mkdir(parents=True,exist_ok=True)
    # Generated skill projections contain only discovery docs + agent declarations.
    for row in skills:
        src=target/'.pmcro/plugins'/row['plugin']/'skills'/row['id']
        for base in [target/'.agents/skills'/row['plugin']/row['id'],target/'.claude/skills'/row['plugin']/row['id'],target/'.grok/skills'/row['plugin']/row['id'],target/'.cursor/skills'/row['plugin']/row['id'],target/'.github/skills'/row['plugin']/row['id']]:
            base.mkdir(parents=True,exist_ok=True);shutil.copy2(src/'SKILL.md',base/'SKILL.md')
            if (src/'agents').is_dir() and not (base/'agents').exists():shutil.copytree(src/'agents',base/'agents')
    print(json.dumps({**result,'status':'PASS','applied':True},indent=2))
if __name__=='__main__':main()
