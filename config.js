window.APP_CONFIG = {
  supabaseUrl: "https://fgnvvzddhofqruhzaxoh.supabase.co",
  supabaseAnonKey: "sb_publishable_OWGtzbsF-jizCS9kf8cIlg_nrg7hLu6"
};

/*
 * Parche de compatibilidad para docente.html
 * Corrige el botón REVISAR CÓDIGO sin modificar el archivo principal.
 *
 * docente.html genera el onclick incluyendo el nombre del estudiante dentro
 * de un atributo HTML entre comillas dobles. Si el nombre se serializa con
 * comillas, el atributo puede quedar cortado y el botón no ejecuta la función.
 * Este listener captura el clic antes del onclick inline y llama directamente
 * a openCodeReview usando data-review y el nombre visible en la fila.
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
