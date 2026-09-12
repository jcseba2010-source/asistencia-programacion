window.APP_CONFIG = {
  supabaseUrl: "https://fgnvvzddhofqruhzaxoh.supabase.co",
  supabaseAnonKey: "sb_publishable_OWGtzbsF-jizCS9kf8cIlg_nrg7hLu6"
};

/*
 * Parche de compatibilidad para docente.html
 * Corrige el botón REVISAR CÓDIGO sin modificar el archivo principal.
 */
document.addEventListener("click", function (event) {
  const button = event.target.closest && event.target.closest("button[data-review]");
  if (!button) return;

  const reviewId = Number(button.dataset.review || 0);
  if (!reviewId) return;

  event.preventDefault();
  event.stopPropagation();
  if (typeof event.stopImmediatePropagation === "function") {
    event.stopImmediatePropagation();
  }

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

function correctionBox(title, text) {
  const box = document.createElement("div");
  box.className = "teacher-correction-box";
  box.style.cssText = "margin-top:10px;padding:12px 14px;border:2px solid #16a34a;border-radius:10px;background:#f0fdf4;color:#14532d;white-space:pre-wrap;font-family:Arial,Helvetica,sans-serif;line-height:1.45";
  const h = document.createElement("div");
  h.style.cssText = "font-weight:800;margin-bottom:7px;color:#166534";
  h.textContent = "✅ CORRECCIÓN / RESPUESTA ESPERADA · " + title;
  const body = document.createElement("div");
  body.textContent = text;
  box.appendChild(h);
  box.appendChild(body);
  return box;
}

function renderCodeCorrections() {
  const r = (typeof currentCodeReview !== "undefined") ? currentCodeReview : null;
  if (!r) return;

  document.querySelectorAll(".teacher-correction-box").forEach(x => x.remove());

  const corrections = {
    p23: r.p23_correction || r.p23_expected || r.p23_solution ||
`La respuesta debe mostrar las validaciones solicitadas antes de continuar el proceso.
Debe usar condicionales y/o ciclos para impedir datos inválidos, repetir la captura cuando corresponda y conservar únicamente valores permitidos.

Para asignar el puntaje completo verifique:
• que valide los datos indicados en el enunciado;
• que no acepte valores fuera del rango permitido;
• que el programa vuelva a solicitar el dato cuando sea incorrecto;
• que la lógica permita continuar cuando el valor sea válido.`,

    p24: r.p24_correction || r.p24_expected || r.p24_solution ||
`La solución debe implementar correctamente la lógica de tarifas y el descuento solicitado mediante if / elif / else.

Estructura esperada:
1. Determinar la tarifa según la condición indicada.
2. Calcular el valor inicial.
3. Evaluar si cumple la condición para descuento.
4. Aplicar el descuento únicamente cuando corresponda.
5. Obtener y mostrar o retornar el valor final.

Debe existir una diferencia clara entre el valor antes del descuento y el total final.`,

    p25: r.p25_correction || r.p25_expected || r.p25_solution ||
`La solución integral debe usar ciclos anidados para recorrer correctamente los niveles solicitados en AUTO CLEAN.

Para el puntaje completo verifique:
• ciclo externo para el primer nivel del proceso;
• ciclo interno para repetir las operaciones de cada nivel;
• contadores y acumuladores correctamente inicializados y actualizados;
• reinicio de variables internas cuando comienza una nueva iteración externa;
• cálculo de los totales generales;
• informe final con los resultados acumulados.

La estructura debe resolver el proceso completo, no solamente una iteración aislada.`
  };

  const targets = [
    ["p23Answer", "P23", corrections.p23],
    ["p24Answer", "P24", corrections.p24],
    ["p25Answer", "P25", corrections.p25]
  ];

  targets.forEach(([id, title, text]) => {
    const answer = document.getElementById(id);
    if (!answer) return;
    answer.insertAdjacentElement("afterend", correctionBox(title, text));
  });
}

/*
 * Parche para GUARDAR CALIFICACIÓN.
 * La función existente en Supabase usa los parámetros:
 * p_review_id, p_p23_score, p_p24_score, p_p25_score, p_observation.
 * docente.html estaba enviando p23_score, p24_score y p25_score.
 */
document.addEventListener("click", async function (event) {
  const button = event.target.closest && event.target.closest('button[onclick*="saveCodeReview"]');
  if (!button) return;

  event.preventDefault();
  event.stopPropagation();
  if (typeof event.stopImmediatePropagation === "function") {
    event.stopImmediatePropagation();
  }

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

    if (error) {
      alert("No se pudo guardar: " + error.message);
      return;
    }

    if (data?.ok === false) {
      alert(data.message || "No se pudo guardar.");
      return;
    }

    alert(`Calificación guardada. Nota final: ${Number(data?.final_grade || 0).toFixed(2)} / 5.00`);

    if (typeof window.closeCodeReview === "function") window.closeCodeReview();
    if (typeof window.renderAll === "function") await window.renderAll();

  } catch (e) {
    console.error("saveCodeReview patch", e);
    alert("No se pudo guardar la calificación. Detalle: " + (e?.message || e));
  }
}, true);
