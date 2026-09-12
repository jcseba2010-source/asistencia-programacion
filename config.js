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

function renderCodeCorrections() {
  const r = (typeof currentCodeReview !== "undefined") ? currentCodeReview : null;
  if (!r) return;
  document.querySelectorAll(".teacher-correction-box").forEach(x => x.remove());

  const p23 = `# P23 - Validaciones\n# Estructura de referencia para AUTO CLEAN\n\nwhile True:\n    print("TIPO DE VEHÍCULO")\n    print("1. Automóvil")\n    print("2. Camioneta")\n    tipo_vehiculo = int(input("Seleccione el tipo de vehículo: "))\n\n    if tipo_vehiculo == 1 or tipo_vehiculo == 2:\n        break\n    else:\n        print("Dato inválido. Intente nuevamente.")\n\nwhile True:\n    print("TIPO DE SERVICIO")\n    print("1. Servicio básico")\n    print("2. Servicio completo")\n    tipo_servicio = int(input("Seleccione el tipo de servicio: "))\n\n    if tipo_servicio == 1 or tipo_servicio == 2:\n        break\n    else:\n        print("Dato inválido. Intente nuevamente.")`;

  const p24 = `# P24 - Tarifas, condicional y descuento\n\n# La tarifa se determina según vehículo y servicio\nif tipo_vehiculo == 1:\n    if tipo_servicio == 1:\n        tarifa = tarifa_auto_basico\n    else:\n        tarifa = tarifa_auto_completo\nelse:\n    if tipo_servicio == 1:\n        tarifa = tarifa_camioneta_basico\n    else:\n        tarifa = tarifa_camioneta_completo\n\nvalor_inicial = tarifa\n\n# Condicional sencillo para aplicar descuento\nif aplica_descuento:\n    descuento = valor_inicial * porcentaje_descuento\nelse:\n    descuento = 0\n\nvalor_final = valor_inicial - descuento\n\nprint("Valor inicial:", valor_inicial)\nprint("Descuento:", descuento)\nprint("Valor final:", valor_final)`;

  const p25 = `# P25 - Solución integral con ciclos anidados\n\ntotal_servicios = 0\ntotal_recaudado = 0\n\nfor dia in range(1, dias_trabajo + 1):\n    total_dia = 0\n\n    for servicio in range(1, servicios_por_dia + 1):\n        # En cada servicio se realizan las validaciones de P23\n        # y el cálculo de tarifa/descuento de P24.\n\n        valor_final = calcular_servicio()\n\n        total_servicios += 1\n        total_dia += valor_final\n        total_recaudado += valor_final\n\n    print("Día", dia, "- Total:", total_dia)\n\nprint("===== INFORME FINAL AUTO CLEAN =====")\nprint("Total de servicios:", total_servicios)\nprint("Total recaudado:", total_recaudado)`;

  const targets = [
    ["p23Answer", "P23", p23, "Compare la respuesta del estudiante con esta estructura desarrollada de validación."],
    ["p24Answer", "P24", p24, "La lógica debe calcular tarifa, aplicar la condición de descuento y obtener el valor final."],
    ["p25Answer", "P25", p25, "Debe existir un ciclo externo, otro interno, acumuladores e informe final." ]
  ];

  targets.forEach(([id, title, code, note]) => {
    const answer = document.getElementById(id);
    if (!answer) return;
    answer.insertAdjacentElement("afterend", codeCorrectionBox(title, code, note));
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
   MODO SEGURO V2
   - Una salida NO envía automáticamente el examen.
   - La salida queda registrada como infracción.
   - Al regresar se mantiene una pantalla de bloqueo hasta volver a pantalla completa.
   - El envío queda reservado al botón FINALIZAR Y ENVIAR.
   ============================================================ */
window.addEventListener('load', function(){
  if (typeof window.registerViolation !== 'function') return;

  window.registerViolation = async function(reason){
    try{
      if(typeof examStarted==='undefined' || !examStarted || typeof current==='undefined' || !current || (typeof submitting!=='undefined' && submitting)) return;
      if(typeof leaveIncidentOpen!=='undefined' && leaveIncidentOpen) return;
      if(typeof leaveIncidentOpen!=='undefined') leaveIncidentOpen=true;

      const result=await client.rpc('report_exam_violation',{
        p_access_token:current.access_token,
        p_device_id:deviceId,
        p_reason:reason
      });

      if(result.error){
        console.warn('No se pudo registrar la infracción:',result.error.message);
      }

      const n=Number(result.data?.violations||0);
      const counter=document.getElementById('violations');
      if(counter) counter.textContent=n;

      const lock=document.getElementById('lockscreen');
      if(lock){
        lock.style.display='flex';
        const p=lock.querySelector('p');
        if(p) p.textContent=`Se registró una salida del examen (${n}). La evaluación NO fue enviada. Regresa a pantalla completa para continuar.`;
      }

      const submit=document.getElementById('submitBtn');
      if(submit) submit.disabled=true;
    }catch(e){
      console.error('Modo seguro V2:',e);
    }
  };

  const oldReturn=window.returnToExam;
  window.returnToExam=async function(){
    try{
      if(typeof enterFullscreen==='function') await enterFullscreen();
      if(!document.fullscreenElement){
        alert('Debes volver a pantalla completa para continuar la evaluación.');
        return;
      }
      const lock=document.getElementById('lockscreen');
      if(lock) lock.style.display='none';
      if(typeof leaveIncidentOpen!=='undefined') leaveIncidentOpen=false;
      const submit=document.getElementById('submitBtn');
      if(submit) submit.disabled=false;
    }catch(e){
      if(typeof oldReturn==='function') return oldReturn();
    }
  };
});
