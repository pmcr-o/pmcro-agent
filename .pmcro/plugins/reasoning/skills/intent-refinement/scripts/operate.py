import argparse,json,re,sys
from pathlib import Path
REQ=['schema','rootIntentRef','ownerPhase','invokedBy','rawIntent','workingIntent','requestedOutcome','validatedClaims','unresolvedFragments','explicitConstraints','assumptions','changes','authorityGranted','executionPerformed']
def validate(x):
    for k in REQ:
        if k not in x: raise ValueError('missing '+k)
    if x['schema']!='pmcro.intent-refinement/v1': raise ValueError('schema')
    if x['ownerPhase']!='ORCHESTRATE' or x['invokedBy']!='orchestrator': raise ValueError('intent refinement must be owned/invoked by ORCHESTRATE')
    raw=x['rawIntent']
    if not isinstance(raw,str) or not raw: raise ValueError('rawIntent')
    if not isinstance(x['workingIntent'],str) or not x['workingIntent']: raise ValueError('workingIntent')
    claims=x['validatedClaims']
    if not isinstance(claims,list) or not claims: raise ValueError('validatedClaims')
    ids=set()
    for c in claims:
        if not isinstance(c,dict) or c.get('status')!='CONFIRMED': raise ValueError('claim status must be CONFIRMED')
        cid=c.get('claimId',''); start=c.get('sourceStart'); end=c.get('sourceEnd'); excerpt=c.get('sourceExcerpt',''); interpretation=c.get('interpretation','')
        if not cid or cid in ids: raise ValueError('claimId'); ids.add(cid)
        if not isinstance(start,int) or not isinstance(end,int) or start<0 or end<=start or end>len(raw): raise ValueError('claim source bounds')
        if raw[start:end] != excerpt: raise ValueError('claim exact source grounding')
        if not interpretation: raise ValueError('claim interpretation')
    for k in ['unresolvedFragments','explicitConstraints','assumptions','changes']:
        if not isinstance(x[k],list) or any(not isinstance(v,str) for v in x[k]): raise ValueError(k)
    if x['authorityGranted'] is not False: raise ValueError('intent refinement cannot grant authority')
    if x['executionPerformed'] is not False: raise ValueError('intent refinement cannot execute')
    rs=str(x.get('rationaleSummary','')).lower()
    if 'chain-of-thought' in rs or 'hidden reasoning' in rs: raise ValueError('private reasoning claim forbidden')
    return x
def conservative_refine(raw,root):
    working=re.sub(r'\s+',' ',raw).strip()
    changes=[] if working==raw else ['Collapsed whitespace only; no semantic inference performed by deterministic wrapper.']
    return {'schema':'pmcro.intent-refinement/v1','rootIntentRef':root,'ownerPhase':'ORCHESTRATE','invokedBy':'orchestrator','rawIntent':raw,'workingIntent':working,'requestedOutcome':working,'validatedClaims':[{'claimId':'claim-001','sourceStart':0,'sourceEnd':len(raw),'sourceExcerpt':raw,'interpretation':working,'status':'CONFIRMED'}],'unresolvedFragments':['Semantic decomposition remains unresolved until an agent/model emits smaller exact-source-grounded CONFIRMED claims.'],'explicitConstraints':[],'assumptions':[],'changes':changes,'rationaleSummary':'Conservative ingress refinement preserves the entire source as one exact CONFIRMED claim; deterministic cleanup does not pretend to be semantic understanding.','authorityGranted':False,'executionPerformed':False}
p=argparse.ArgumentParser();p.add_argument('operation',choices=['validate','refine']);p.add_argument('--input');p.add_argument('--raw-file');p.add_argument('--root-intent-ref');p.add_argument('--output');a=p.parse_args()
try:
    if a.operation=='validate':
        if not a.input: raise ValueError('--input required')
        x=json.loads(Path(a.input).read_text(encoding='utf-8-sig'));validate(x);print(json.dumps({'status':'PASS','ownerPhase':x['ownerPhase'],'rootIntentRef':x['rootIntentRef'],'workingIntent':x['workingIntent'],'validatedClaims':len(x['validatedClaims'])},ensure_ascii=False))
    else:
        if not a.raw_file or not a.root_intent_ref or not a.output: raise ValueError('--raw-file, --root-intent-ref, --output required')
        raw=Path(a.raw_file).read_text(encoding='utf-8-sig');x=conservative_refine(raw,a.root_intent_ref);validate(x);Path(a.output).parent.mkdir(parents=True,exist_ok=True);Path(a.output).write_text(json.dumps(x,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');print(json.dumps({'status':'PASS','output':a.output,'workingIntent':x['workingIntent'],'validatedClaims':len(x['validatedClaims'])},ensure_ascii=False))
    sys.exit(0)
except Exception as e:
    print('FAIL '+str(e),file=sys.stderr);sys.exit(1)