from pathlib import Path
import json,re,sys
R=Path(__file__).resolve().parents[1]; passed=[];fail=[]
def ok(v,m):(passed if v else fail).append(m);print(('PASS ' if v else 'FAIL ')+m)
def j(p):return json.loads(p.read_text(encoding='utf-8-sig'))
meta=j(R/'.pmcro/control/project.json');ok(meta['id']=='pmcro-agent' and meta['orchestratorRole']=='global-orchestrator','global orchestrator identity')
life=j(R/'.pmcro/control/lifecycle.json');ok(life['autonomous'] and not life['questionGate'] and life['checker']['independent'] and not life['checker']['makerMaySelfApprove'],'autonomous independent checker')
route=j(R/'.pmcro/control/routing.json');ok(not route['questionGate'] and not route['unresolvedAmbiguity']['askUser'],'no clarification gate')
ext=j(R/'.pmcro/protocol/marketplace-extension.json');ok(ext['mode']=='autonomous-bounded' and not ext['questionGate'],'marketplace extension outer loop')
cat=j(R/'.pmcro/control/catalog.json')
for row in cat['skills']:
 s=R/'.pmcro/plugins'/row['plugin']/'skills'/row['id'];ok((s/'SKILL.md').is_file(),f"{row['plugin']}/{row['id']} SKILL.md")
 for d in ['agents','scripts','references','assets','tests']:ok((s/d).is_dir() and any(x.is_file() for x in (s/d).rglob('*')),f"{row['plugin']}/{row['id']} {d}")
for n in ['catalog.json','index.json','routing.json','lifecycle.json','grants.json','project.json','queue.json','capabilities.json','ecosystem.json','run-surfaces.json']:
 c=R/'.pmcro/control'/n
 if not c.is_file(): continue
 ok((R/'.agents'/n).read_bytes()==c.read_bytes(),f'.agents/{n} exact projection')
 for h in ['.claude','.grok','.cursor','.github']:ok((R/h/n).read_bytes()==c.read_bytes(),f'{h}/{n} exact host projection')
for plugin in sorted(x for x in (R/'.pmcro/plugins').iterdir() if x.is_dir()):
 ok((R/'plugins'/plugin.name).is_dir(),f'root plugin projection {plugin.name}')
q=R/'.pmcro/queue/scripts';ok(all((q/n).is_file() for n in ['enqueue.ps1','claim.ps1','ack.ps1','nack.ps1','recover.ps1']),'durable queue scripts')
ag=j(R/'.pmcro/protocol/agent-agreement.schema.json');ok(ag['sharedMutableTrail'] is False and ag['receiverCreatesLocalTrail'] is True,'local trail ownership')
s=j(R/'.pmcro/control/run-surfaces.json');ok(any(x['id']=='grok' and x['status']=='PROJECTED' for x in s['surfaces']),'Grok documented as projected host')
print(f'SUMMARY pass={len(passed)} fail={len(fail)}');raise SystemExit(1 if fail else 0)
