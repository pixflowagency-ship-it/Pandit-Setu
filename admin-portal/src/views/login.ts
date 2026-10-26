import { adminApi } from "../api.ts";
import { setSession } from "../auth.ts";

export function renderLoginView(container: HTMLElement, onLoginSuccess: () => void): void {
  container.innerHTML = `
    <div class="login-container">
      <div class="login-card">
        <div class="brand-badge">
          <span>🚩</span>
          <span>SARV MANGAL CENTRAL DESK</span>
        </div>
        <h1 class="login-title">Administrator Sign In</h1>
        <p class="login-shloka">सर्व मंगल मांगल्ये शिवे सर्वार्थ साधिके</p>
        <p class="login-subtitle">Enter privileged credentials to access operational verification desks.</p>

        <div id="login-alert" style="display: none;"></div>

        <form id="login-form">
          <div class="form-group">
            <label class="form-label" for="admin-email">ADMIN EMAIL / ID</label>
            <input 
              id="admin-email" 
              type="email" 
              class="form-input" 
              placeholder="admin@sarvmangal.app" 
              required 
              autocomplete="email"
            />
          </div>

          <div class="form-group">
            <label class="form-label" for="admin-password">PASSWORD</label>
            <div class="input-wrapper">
              <input 
                id="admin-password" 
                type="password" 
                class="form-input" 
                placeholder="••••••••••••" 
                required 
                autocomplete="current-password"
              />
              <button type="button" id="toggle-password" class="password-toggle">Show</button>
            </div>
          </div>

          <button type="submit" id="login-submit-btn" class="btn btn-primary" style="width: 100%; margin-top: 8px;">
            <span>Authenticate Privileged Session</span>
          </button>
        </form>
      </div>
    </div>
  `;

  const form = container.querySelector("#login-form") as HTMLFormElement;
  const emailInput = container.querySelector("#admin-email") as HTMLInputElement;
  const passwordInput = container.querySelector("#admin-password") as HTMLInputElement;
  const toggleBtn = container.querySelector("#toggle-password") as HTMLButtonElement;
  const submitBtn = container.querySelector("#login-submit-btn") as HTMLButtonElement;
  const alertBox = container.querySelector("#login-alert") as HTMLElement;

  toggleBtn.addEventListener("click", () => {
    const isPass = passwordInput.type === "password";
    passwordInput.type = isPass ? "text" : "password";
    toggleBtn.textContent = isPass ? "Hide" : "Show";
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    alertBox.style.display = "none";
    submitBtn.disabled = true;
    submitBtn.innerHTML = `<span class="spinner" style="width: 16px; height: 16px; margin: 0; border-width: 2px;"></span> Authenticating...`;

    try {
      const email = emailInput.value.trim();
      const password = passwordInput.value;

      const res = await adminApi.login(email, password);
      setSession(res.token, res.user);
      onLoginSuccess();
    } catch (err: any) {
      alertBox.className = "alert-banner alert-error";
      alertBox.textContent = `Authentication Failed: ${err.message || "Invalid email or password"}`;
      alertBox.style.display = "flex";
      submitBtn.disabled = false;
      submitBtn.innerHTML = `<span>Authenticate Privileged Session</span>`;
    }
  });
}
