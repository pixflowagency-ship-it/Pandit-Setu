import "./style.css";
import { isAuthenticated } from "./auth.ts";
import { renderLoginView } from "./views/login.ts";
import { renderDashboardView } from "./views/dashboard.ts";

function initApp(): void {
  const appContainer = document.getElementById("app");
  if (!appContainer) return;

  function renderCurrentState(): void {
    if (isAuthenticated()) {
      renderDashboardView(appContainer!, () => {
        renderCurrentState();
      });
    } else {
      renderLoginView(appContainer!, () => {
        renderCurrentState();
      });
    }
  }

  window.addEventListener("sarv_auth_state_changed", () => {
    renderCurrentState();
  });

  renderCurrentState();
}

document.addEventListener("DOMContentLoaded", initApp);
