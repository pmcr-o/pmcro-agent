const tutorials={grok:{title:'Grok',body:`<ol><li>Read <span class="kbd">.grok/ACTIVATE.md</span>, then <span class="kbd">.agents/project.json</span> and <span class="kbd">.agents/catalog.json</span>.</li><li>Seed <span class="kbd">@pmcro-agent /pmcro-orchestrator:orchestrate</span>.</li><li>Never invent a capability; route from the catalog.</li><li>Inspect the local trail, checker verdict, and reflection.</li></ol>`},terminal:{title:'PowerShell / terminal',body:`<div class="code">pwsh -NoProfile -File .pmcro/plugins/pmcro-orchestrator/skills/orchestrate/scripts/loop-cycle.ps1 \
  -Marketplace . -RunId learn-001 -Source intent \
  -Goal "Demonstrate one bounded PMCR-O governance capability cycle." \
  -Plugin pmcro-governance -Skill govern</div>`},claude:{title:'Claude',body:`<p>Read <span class="kbd">.claude/ACTIVATE.md</span>. It activates the same continuous PMCR-O runtime through <span class="kbd">.agents</span>, which points to canonical <span class="kbd">.pmcro</span>. Use the same catalog and phase order.</p>`},cursor:{title:'Cursor',body:`<p>Read <span class="kbd">.cursor/README.md</span>, select a registered route, and keep CHECK independent from MAKE.</p>`}};document.querySelectorAll('.tab').forEach(b=>b.onclick=()=>{document.querySelectorAll('.tab').forEach(x=>x.classList.remove('active'));b.classList.add('active');const t=tutorials[b.dataset.t];document.getElementById('tutorial').innerHTML='<h3>'+t.title+'</h3>'+t.body});document.querySelector('.tab').click();

async function loadLearning(){
  let data;
  try{const r=await fetch('data/progress.local.json',{cache:'no-store'});if(!r.ok)throw new Error();data=await r.json()}
  catch(_){data=await fetch('data/progress.template.json',{cache:'no-store'}).then(r=>r.json())}
  const grid=document.getElementById('learning-grid');if(!grid)return;
  grid.innerHTML=data.modules.map(m=>`<div class="card"><span class="status ${String(m.state).toLowerCase()}">${m.state}</span><h3>${m.id} · ${m.title}</h3><p class="muted">${m.teaches||''}</p></div>`).join('');
}
loadLearning();
