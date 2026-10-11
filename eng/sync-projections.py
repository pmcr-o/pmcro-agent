from pathlib import Path
import json,shutil,sys
R=Path(__file__).resolve().parents[1]; APPLY='--apply' in sys.argv
if not APPLY: print('DRY-RUN: regenerate host projections from .pmcro; pass --apply'); raise SystemExit(0)
def cp(s,d):
 d.parent.mkdir(parents=True,exist_ok=True)
 if s.is_dir(): shutil.copytree(s,d)
 else: shutil.copy2(s,d)
for x in ['.agents','.claude','.grok','.cursor']:
 p=R/x
 if p.exists(): shutil.rmtree(p)
g=R/'.github'
for n in ['agents','skills']:
 p=g/n
 if p.exists(): shutil.rmtree(p)
for n in ['catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json','queue.json','capabilities.json','ecosystem.json','run-surfaces.json','README.md','STRUCTURE.md','ACTIVATE.md']:
 p=g/n
 if p.exists(): p.unlink()
a=R/'.agents'; a.mkdir()
for n in ['catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json','queue.json','capabilities.json','ecosystem.json','run-surfaces.json']:
 s=R/'.pmcro/control'/n
 if s.is_file(): cp(s,a/n)
cp(R/'.pmcro/control/marketplace.json',a/'plugins/marketplace.json');cp(R/'.pmcro/agents',a/'agents')
cat=json.loads((R/'.pmcro/control/catalog.json').read_text(encoding='utf-8-sig'))
for row in cat['skills']:
 s=R/'.pmcro/plugins'/row['plugin']/'skills'/row['id']; d=a/'skills'/row['plugin']/row['id']; d.mkdir(parents=True,exist_ok=True); cp(s/'SKILL.md',d/'SKILL.md')
 if (s/'agents').is_dir(): cp(s/'agents',d/'agents')
 (d/'projection.json').write_text(json.dumps({'canonical':f".pmcro/plugins/{row['plugin']}/skills/{row['id']}",'generated':True,'authority':False},indent=2)+'\n',encoding='utf-8')
(a/'README.md').write_text('# .agents projection\n\nGenerated from `.pmcro`; no independent authority.\n',encoding='utf-8')
for host in ['.claude','.grok','.cursor','.github']:
 h=R/host; h.mkdir(parents=True,exist_ok=True)
 for n in ['catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json','queue.json','capabilities.json','ecosystem.json','run-surfaces.json']:
  if (a/n).is_file():cp(a/n,h/n)
 cp(a/'agents',h/'agents');cp(a/'skills',h/'skills')
 (h/'README.md').write_text(f'# {host} host surface\n\nAuthority: `{host} -> .agents -> .pmcro`.\n\nProjection is not activation. Read `ACTIVATE.md` to enter and continuously run PMCR-O.\n',encoding='utf-8')
 (h/'ACTIVATE.md').write_text(f'# Activate PMCR-O on {host}

I AM the Orchestrator.

Enter this repository as one bounded PMCR-O I. Authority chain: `{host} -> .agents -> .pmcro`.

Phase transitions are automatic. Never ask the human to invoke the next phase, agent, or cycle. Legacy/manual phase-gating instructions are non-authoritative when they conflict with `AGENTS.md` or `.pmcro/protocol/host-activation.json`.

After REFLECT, consume the earned next seed in a new ORCHESTRATE cycle while bounds remain. On reconnect, resume from durable queue/trail state without requiring the human to restate an already-recorded seed.
',encoding='utf-8')
 (h/'STRUCTURE.md').write_text(f'# Structure\n\n`{host} -> .agents -> .pmcro`\n',encoding='utf-8')
print('SYNC-PASS')
