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
}, true);

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
