window.APP_CONFIG = {
  supabaseUrl: "https://fgnvvzddhofqruhzaxoh.supabase.co",
  supabaseAnonKey: "sb_publishable_OWGtzbsF-jizCS9kf8cIlg_nrg7hLu6"
};

/* Botón REVISAR CÓDIGO: evita que el nombre del estudiante rompa el onclick. */
document.addEventListener("click", function (event) {
  const button = event.target.closest && event.target.closest("button[data-review]");
  if (!button) return;
  const reviewId = Number(button.dataset.review || 0);
  if (!reviewId) return;
  event.preventDefault();
  event.stopPropagation();
  if (typeof event.stopImmediatePropagation === "function") event.stopImmediatePropagation();

  const row = button.closest("tr");
  const cells = row ? row.querySelectorAll("td") : [];
  const studentName = cells.length > 1 ? cells[1].textContent.trim() : "";
  if (typeof window.openCodeReview !== "function") {
    alert("La ventana REVISAR CÓDIGO todavía no está disponible. Recarga la página e inténtalo nuevamente.");
    return;
  }
  window.openCodeReview(reviewId, studentName);
  setTimeout(renderCodeCorrections, 0);
  setTimeout(renderTeacherCodePhotos, 150);
}, true);

function codeCorrectionBox(title, code, note) {
  const box = document.createElement("div");
  box.className = "teacher-correction-box";
  box.style.cssText = "margin-top:12px;padding:14px;border:2px solid #16a34a;border-radius:12px;background:#f0fdf4;color:#14532d";

  const h = document.createElement("div");
  h.style.cssText = "font-weight:900;margin-bottom:9px;color:#166534;font-size:16px";
  h.textContent = "✅ DESARROLLO CORRECTO EN PYTHON · " + title;
  box.appendChild(h);

  if (note) {
    const n = document.createElement("div");
    n.style.cssText = "margin-bottom:9px;line-height:1.4";
    n.textContent = note;
    box.appendChild(n);
  }

  const pre = document.createElement("pre");
  pre.style.cssText = "margin:0;background:#0f172a;color:#e2e8f0;padding:14px;border-radius:10px;overflow:auto;white-space:pre;font-family:Consolas,Monaco,monospace;font-size:14px;line-height:1.45";
  pre.textContent = code;
  box.appendChild(pre);
  return box;
}

function getWrittenCorrection(questionText){
  const t=String(questionText||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
  if(t.includes('valida') || t.includes('tipo de vehiculo')){
    return {
      qno:23,
      title:'P23 - Validaciones',
      code:`while True:\n    print("TIPO DE VEHÍCULO")\n    print("1. Automóvil")\n    print("2. Camioneta")\n    tipo_vehiculo = int(input("Seleccione el tipo de vehículo: "))\n\n    if tipo_vehiculo == 1 or tipo_vehiculo == 2:\n        break\n    else:\n        print("Dato inválido. Intente nuevamente.")\n\nwhile True:\n    print("TIPO DE SERVICIO")\n    print("1. Servicio básico")\n    print("2. Servicio completo")\n    tipo_servicio = int(input("Seleccione el tipo de servicio: "))\n\n    if tipo_servicio == 1 or tipo_servicio == 2:\n        break\n    else:\n        print("Dato inválido. Intente nuevamente.")`
    };
  }
  if(t.includes('tarifa') || t.includes('descuento')){
    return {
      qno:24,
      title:'P24 - Tarifas y descuento',
      code:`if tipo_vehiculo == 1:\n    if tipo_servicio == 1:\n        tarifa = tarifa_auto_basico\n    else:\n        tarifa = tarifa_auto_completo\nelse:\n    if tipo_servicio == 1:\n        tarifa = tarifa_camioneta_basico\n    else:\n        tarifa = tarifa_camioneta_completo\n\nvalor_inicial = tarifa\n\nif aplica_descuento:\n    descuento = valor_inicial * porcentaje_descuento\nelse:\n    descuento = 0\n\nvalor_final = valor_inicial - descuento\n\nprint("Valor inicial:", valor_inicial)\nprint("Descuento:", descuento)\nprint("Valor final:", valor_final)`
    };
  }
  return {
    qno:25,
    title:'P25 - Ciclos anidados e informe final',
    code:`total_servicios = 0\ntotal_recaudado = 0\n\nfor dia in range(1, dias_trabajo + 1):\n    total_dia = 0\n\n    for servicio in range(1, servicios_por_dia + 1):\n        valor_final = calcular_servicio()\n        total_servicios += 1\n        total_dia += valor_final\n        total_recaudado += valor_final\n\n    print("Día", dia, "- Total:", total_dia)\n\nprint("===== INFORME FINAL AUTO CLEAN =====")\nprint("Total de servicios:", total_servicios)\nprint("Total recaudado:", total_recaudado)`
  };
}

function renderCodeCorrections() {
  const r = (typeof currentCodeReview !== "undefined") ? currentCodeReview : null;
  if (!r) return;
  document.querySelectorAll(".teacher-correction-box").forEach(x => x.remove());

  const refs=[
    ["p23Answer",getWrittenCorrection('valida tipo de vehiculo')],
    ["p24Answer",getWrittenCorrection('tarifa descuento')],
    ["p25Answer",getWrittenCorrection('ciclos anidados')]
  ];
  refs.forEach(([id,c])=>{
    const answer=document.getElementById(id);
    if(!answer)return;
    answer.insertAdjacentElement('afterend',codeCorrectionBox('P'+c.qno,c.code,'Compare la respuesta del estudiante con el desarrollo correcto.'));
  });
}

/* GUARDAR CALIFICACIÓN: usa los nombres reales de parámetros de Supabase. */
document.addEventListener("click", async function (event) {
  const button = event.target.closest && event.target.closest('button[onclick*="saveCodeReview"]');
  if (!button) return;
  event.preventDefault();
  event.stopPropagation();
  if (typeof event.stopImmediatePropagation === "function") event.stopImmediatePropagation();

  try {
    if (typeof currentCodeReview === "undefined" || !currentCodeReview) {
      alert("No hay una revisión de código seleccionada.");
      return;
    }

    const p23 = Number(document.getElementById("p23Score")?.value || 0);
    const p24 = Number(document.getElementById("p24Score")?.value || 0);
    const p25 = Number(document.getElementById("p25Score")?.value || 0);
    const observation = document.getElementById("reviewObservation")?.value.trim() || "";

    if (p23 < 0 || p23 > 0.75) return alert("P23 debe estar entre 0 y 0.75.");
    if (p24 < 0 || p24 > 1.00) return alert("P24 debe estar entre 0 y 1.00.");
    if (p25 < 0 || p25 > 1.25) return alert("P25 debe estar entre 0 y 1.25.");

    button.disabled = true;
    const oldText = button.textContent;
    button.textContent = "GUARDANDO...";

    const { data, error } = await client.rpc("admin_save_exam_code_review", {
      p_review_id: Number(currentCodeReview.review_id),
      p_p23_score: p23,
      p_p24_score: p24,
      p_p25_score: p25,
      p_observation: observation
    });

    button.disabled = false;
    button.textContent = oldText;

    if (error) return alert("No se pudo guardar: " + error.message);
    if (data?.ok === false) return alert(data.message || "No se pudo guardar.");

    alert(`Calificación guardada. Nota final: ${Number(data?.final_grade || 0).toFixed(2)} / 5.00`);
    if (typeof window.closeCodeReview === "function") window.closeCodeReview();
    if (typeof window.renderAll === "function") await window.renderAll();
  } catch (e) {
    console.error("saveCodeReview patch", e);
    alert("No se pudo guardar la calificación. Detalle: " + (e?.message || e));
  }
}, true);

/* ============================================================
   FOTOS DEL DESARROLLO EN PAPEL - P23, P24, P25
   ============================================================ */
window.__examPhotoUploads = 0;

function detectCodeQuestionNo(card){
  const t=String(card?.textContent||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
  if(t.includes('valida') || t.includes('tipo de vehiculo')) return 23;
  if(t.includes('tarifa') || t.includes('descuento')) return 24;
  return 25;
}

function addPhotoControls(){
  const questions=document.getElementById('questions');
  if(!questions || typeof current==='undefined' || !current) return;
  questions.querySelectorAll('.code-question').forEach(card=>{
    if(card.querySelector('.paper-photo-box')) return;
    const qno=detectCodeQuestionNo(card);
    const box=document.createElement('div');
    box.className='paper-photo-box';
    box.style.cssText='margin-top:12px;padding:12px;border:2px dashed #0b57d0;border-radius:12px;background:#eef6ff';
    box.innerHTML=`<div style="font-weight:900;margin-bottom:7px">📷 DESARROLLO EN PAPEL · P${qno}</div>
      <div style="font-size:13px;margin-bottom:8px">Opcional: toma una foto clara o selecciona una imagen. Máximo 5 MB.</div>
      <input type="file" accept="image/jpeg,image/png,image/webp" capture="environment" data-qno="${qno}" style="width:100%">
      <div class="photo-status" style="font-size:13px;margin-top:8px"></div>
      <img class="photo-preview" alt="Vista previa" style="display:none;max-width:100%;max-height:320px;margin-top:10px;border-radius:10px;border:1px solid #cbd5e1">`;
    card.appendChild(box);
    const input=box.querySelector('input[type=file]');
    input.addEventListener('change', async ()=>{
      const file=input.files?.[0];
      const status=box.querySelector('.photo-status');
      const preview=box.querySelector('.photo-preview');
      if(!file) return;
      if(!['image/jpeg','image/png','image/webp'].includes(file.type)){
        input.value=''; status.textContent='Formato no permitido.'; return;
      }
      if(file.size>5242880){
        input.value=''; status.textContent='La imagen supera 5 MB.'; return;
      }
      preview.src=URL.createObjectURL(file); preview.style.display='block';
      window.__examPhotoUploads++;
      const submit=document.getElementById('submitBtn'); if(submit) submit.disabled=true;
      status.textContent='Subiendo foto...';
      try{
        const ext=(file.name.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,'');
        const ced=String(document.getElementById('cedula')?.value||current.cedula||'').trim();
        const examId=Number(current.exam_id||0);
        const grp=String(current.group_name||current.group||'');
        const safeCed=ced.replace(/[^0-9A-Za-z_-]/g,'_');
        const path=`${examId}/${safeCed}/p${qno}_${Date.now()}.${ext}`;
        const up=await client.storage.from('exam-code-photos').upload(path,file,{contentType:file.type,upsert:false});
        if(up.error) throw up.error;
        const reg=await client.rpc('save_exam_code_photo',{
          p_exam_id:examId,
          p_cedula:ced,
          p_group_name:grp,
          p_question_no:qno,
          p_storage_path:path,
          p_mime_type:file.type,
          p_size_bytes:file.size
        });
        if(reg.error) throw reg.error;
        if(reg.data?.ok===false) throw new Error(reg.data.message||'No se pudo registrar la foto.');
        status.textContent='✅ Foto guardada correctamente.';
      }catch(e){
        console.error('Foto examen',e);
        status.textContent='❌ No se pudo guardar la foto: '+(e?.message||e);
      }finally{
        window.__examPhotoUploads=Math.max(0,window.__examPhotoUploads-1);
        if(submit) submit.disabled=false;
      }
    });
  });
}

window.addEventListener('load',()=>{
  const q=document.getElementById('questions');
  if(q){
    new MutationObserver(()=>addPhotoControls()).observe(q,{childList:true,subtree:true});
    setTimeout(addPhotoControls,500);
  }
});

document.addEventListener('click',function(e){
  const b=e.target.closest && e.target.closest('#submitBtn');
  if(!b) return;
  if(window.__examPhotoUploads>0){
    e.preventDefault(); e.stopPropagation();
    if(typeof e.stopImmediatePropagation==='function') e.stopImmediatePropagation();
    alert('Espera a que termine de subir la foto antes de enviar la evaluación.');
  }
},true);

/* Mostrar las fotos dentro de REVISAR CÓDIGO */
async function renderTeacherCodePhotos(){
  try{
    const r=(typeof currentCodeReview!=='undefined')?currentCodeReview:null;
    if(!r || typeof client==='undefined') return;
    document.querySelectorAll('.teacher-photo-box').forEach(x=>x.remove());
    const resp=await client.rpc('admin_list_exam_code_photos');
    if(resp.error) return console.warn('Fotos examen:',resp.error.message);
    const examId=Number(r.exam_id||0), ced=String(r.cedula||'');
    const photos=(resp.data||[]).filter(p=>Number(p.exam_id)===examId && String(p.cedula)===ced);
    for(const p of photos){
      const signed=await client.storage.from('exam-code-photos').createSignedUrl(p.storage_path,3600);
      if(signed.error || !signed.data?.signedUrl) continue;
      const target=document.getElementById('p'+p.question_no+'Answer');
      if(!target) continue;
      const box=document.createElement('div');
      box.className='teacher-photo-box';
      box.style.cssText='margin-top:10px;padding:12px;border:2px solid #2563eb;border-radius:12px;background:#eff6ff';
      box.innerHTML=`<div style="font-weight:900;margin-bottom:8px">📷 DESARROLLO EN PAPEL · P${p.question_no}</div>
        <a href="${signed.data.signedUrl}" target="_blank" rel="noopener" style="font-weight:800">🔎 ABRIR FOTO EN TAMAÑO GRANDE</a><br>
        <img src="${signed.data.signedUrl}" alt="Desarrollo P${p.question_no}" style="max-width:100%;max-height:420px;margin-top:10px;border-radius:10px">`;
      const corr=target.nextElementSibling;
      if(corr && corr.classList.contains('teacher-correction-box')) corr.insertAdjacentElement('afterend',box);
      else target.insertAdjacentElement('afterend',box);
    }
  }catch(e){ console.warn('renderTeacherCodePhotos',e); }
}

/* ============================================================
   VER EXAMEN COMPLETO - PANEL DOCENTE
   ============================================================ */
function escapeExamHtml(s){
  return String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));
}

function ensureFullExamModal(){
  if(document.getElementById('fullExamModal')) return;
  const modal=document.createElement('div');
  modal.id='fullExamModal';
  modal.style.cssText='display:none;position:fixed;inset:0;background:#071936cc;z-index:10000;overflow:auto;padding:24px';
  modal.innerHTML=`<div style="max-width:1050px;margin:auto;background:#fff;border-radius:16px;padding:22px;box-shadow:0 20px 60px #0005">
    <div style="display:flex;justify-content:space-between;gap:12px;align-items:center"><h2 style="margin:0">👁 EXAMEN COMPLETO DEL ESTUDIANTE</h2><button id="closeFullExamBtn" class="secondary">CERRAR</button></div>
    <div id="fullExamContent" style="margin-top:18px"></div>
  </div>`;
  document.body.appendChild(modal);
  document.getElementById('closeFullExamBtn').onclick=()=>{modal.style.display='none';};
}

function injectFullExamButtons(){
  const body=document.getElementById('examResultsBody');
  if(!body) return;
  body.querySelectorAll('tr').forEach(row=>{
    if(row.querySelector('.view-full-exam-btn')) return;
    const del=row.querySelector('button[onclick*="deleteExamAttempt("]');
    if(!del) return;
    const m=(del.getAttribute('onclick')||'').match(/deleteExamAttempt\((\d+)\)/);
    if(!m) return;
    const b=document.createElement('button');
    b.type='button'; b.className='secondary view-full-exam-btn'; b.dataset.resultId=m[1];
    b.textContent='👁 VER EXAMEN COMPLETO';
    del.parentElement.insertBefore(b,del);
  });
}

window.addEventListener('load',()=>{
  const body=document.getElementById('examResultsBody');
  if(body){
    new MutationObserver(()=>injectFullExamButtons()).observe(body,{childList:true,subtree:true});
    setTimeout(injectFullExamButtons,1000);
  }
});

document.addEventListener('click',async function(e){
  const b=e.target.closest && e.target.closest('.view-full-exam-btn');
  if(!b) return;
  e.preventDefault();
  await openFullExam(Number(b.dataset.resultId));
});

async function openFullExam(resultId){
  ensureFullExamModal();
  const modal=document.getElementById('fullExamModal');
  const content=document.getElementById('fullExamContent');
  modal.style.display='block';
  content.innerHTML='<p>Cargando examen...</p>';
  try{
    if(typeof db==='undefined') throw new Error('Los resultados todavía no están cargados.');
    const r=(db.examResults||[]).find(x=>Number(x.id)===Number(resultId));
    if(!r) throw new Error('No se encontró el resultado del estudiante.');

    const ex=await client.from('exams').select('id,title,subject,questions').eq('id',Number(r.exam_id)).maybeSingle();
    if(ex.error) throw ex.error;
    const baseQuestions=Array.isArray(ex.data?.questions)?ex.data.questions:[];

    let attempts=[];
    try{
      const ar=await client.rpc('admin_list_exam_attempts');
      if(!ar.error) attempts=ar.data||[];
    }catch(_e){}
    const attempt=attempts.find(a=>Number(a.exam_id)===Number(r.exam_id)&&String(a.cedula)===String(r.cedula));
    let order=attempt?.question_order;
    if(typeof order==='string'){
      try{order=JSON.parse(order);}catch(_e){order=null;}
    }
    const questions=Array.isArray(order)&&order.length
      ? order.map(i=>baseQuestions[Number(i)]).filter(Boolean)
      : baseQuestions;
    let answers=r.answers;
    if(typeof answers==='string'){
      try{answers=JSON.parse(answers);}catch(_e){answers=[];}
    }
    if(!Array.isArray(answers)) answers=[];

    let photoRows=[];
    try{
      const pr=await client.rpc('admin_list_exam_code_photos');
      if(!pr.error) photoRows=(pr.data||[]).filter(p=>Number(p.exam_id)===Number(r.exam_id)&&String(p.cedula)===String(r.cedula));
    }catch(_e){}
    const photoUrls={};
    for(const p of photoRows){
      const signed=await client.storage.from('exam-code-photos').createSignedUrl(p.storage_path,3600);
      if(!signed.error && signed.data?.signedUrl) photoUrls[Number(p.question_no)]=signed.data.signedUrl;
    }

    let html=`<div style="padding:12px;background:#eef6ff;border-radius:12px;margin-bottom:16px"><b>${escapeExamHtml(r.student_name||r.cedula)}</b> · Cédula ${escapeExamHtml(r.cedula)} · Grupo ${escapeExamHtml(r.group_name||'')}<br><b>${escapeExamHtml(ex.data?.title||'Evaluación')}</b> · Nota ${Number(r.grade??r.score??0).toFixed(2)}</div>`;
    questions.forEach((q,i)=>{
      const ans=answers[i];
      html+=`<div style="border:1px solid #dbe5ef;border-radius:12px;padding:14px;margin:12px 0"><div style="font-weight:900;margin-bottom:9px">${i+1}. ${escapeExamHtml(q?.q||'Pregunta')}</div>`;
      if(q?.description) html+=`<div style="margin-bottom:10px;color:#475569">${escapeExamHtml(q.description)}</div>`;
      if(q?.type==='code'){
        const corr=getWrittenCorrection(q?.q||'');
        html+=`<div style="font-size:12px;font-weight:800;color:#475569">✍️ RESPUESTA ESCRITA DEL ESTUDIANTE</div><pre style="white-space:pre-wrap;background:#111827;color:#f8fafc;padding:12px;border-radius:9px;overflow:auto">${escapeExamHtml(ans||'Sin respuesta')}</pre>`;
        html+=`<div style="margin-top:12px;padding:12px;border:2px solid #16a34a;border-radius:10px;background:#f0fdf4"><div style="font-weight:900;color:#166534;margin-bottom:8px">✅ CORRECCIÓN / DESARROLLO CORRECTO · ${escapeExamHtml(corr.title)}</div><pre style="margin:0;white-space:pre-wrap;background:#0f172a;color:#e2e8f0;padding:12px;border-radius:9px;overflow:auto">${escapeExamHtml(corr.code)}</pre></div>`;
        if(photoUrls[corr.qno]){
          html+=`<div style="margin-top:12px;padding:12px;border:2px solid #2563eb;border-radius:10px;background:#eff6ff"><div style="font-weight:900;margin-bottom:8px">📷 DESARROLLO EN PAPEL · P${corr.qno}</div><a href="${photoUrls[corr.qno]}" target="_blank" rel="noopener" style="font-weight:800">🔎 ABRIR FOTO EN TAMAÑO GRANDE</a><br><img src="${photoUrls[corr.qno]}" alt="Desarrollo en papel P${corr.qno}" style="max-width:100%;max-height:420px;margin-top:10px;border-radius:10px"></div>`;
        }
      }else{
        const opts=Array.isArray(q?.o)?q.o:[];
        const idx=Number(ans);
        const chosen=Number.isInteger(idx)&&idx>=0&&idx<opts.length?opts[idx]:ans;
        const correctIdx=Number(q?.a);
        const correct=Number.isInteger(correctIdx)&&correctIdx>=0&&correctIdx<opts.length?opts[correctIdx]:'';
        html+=`<div><b>Respuesta del estudiante:</b> ${escapeExamHtml(chosen??'Sin respuesta')}</div>`;
        if(correct!=='') html+=`<div style="margin-top:6px;color:#166534"><b>✅ Respuesta correcta:</b> ${escapeExamHtml(correct)}</div>`;
      }
      html+='</div>';
    });
    content.innerHTML=html;
  }catch(e){
    console.error('openFullExam',e);
    content.innerHTML='<div style="padding:14px;background:#fdecec;color:#991b1b;border-radius:10px">No se pudo abrir el examen completo: '+escapeExamHtml(e?.message||e)+'</div>';
  }
}
