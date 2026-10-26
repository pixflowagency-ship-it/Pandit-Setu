import { getCurrentUser, clearSession } from "../auth.ts";
import { adminApi } from "../api.ts";
import { renderOverviewTab } from "./tabs/overview.ts";
import { renderPanditsTab } from "./tabs/pandits.ts";
import { renderConsultationsTab } from "./tabs/consultations.ts";
import { renderKundliTab } from "./tabs/kundli.ts";
import { renderSubscriptionsTab } from "./tabs/subscriptions.ts";
import { renderUiEditorTab } from "./tabs/ui_editor.ts";
import { renderUsersTab } from "./tabs/users.ts";
import { renderBookingsTab } from "./tabs/bookings.ts";
import { renderPoojasTab } from "./tabs/poojas.ts";

export type TabKey =
  | "overview"
  | "ui_editor"
  | "pandits"
  | "bookings"
  | "poojas"
  | "users"
  | "consultations"
  | "kundli"
  | "subscriptions";

export function renderDashboardView(container: HTMLElement, onLogout: () => void): void {
  const user = getCurrentUser();
  let currentTab: TabKey = "overview";

  container.innerHTML = `
    <!-- Top Executive Header -->
    <header class="portal-header">
      <div class="header-left">
        <div class="header-logo-icon">🚩</div>
        <div class="header-title-box">
          <h1>SARV MANGAL — Verification & Admin Desk</h1>
          <p>सर्व मंगल मांगल्ये शिवे सर्वार्थ साधिके • Central Operations Engine</p>
        </div>
      </div>
      <div class="header-right">
        <div class="user-badge">
          <div class="user-avatar">${(user?.name || "A")[0].toUpperCase()}</div>
          <div class="user-info">
            <div class="user-name">${user?.name || "Administrator"}</div>
            <div class="user-role">${user?.email || "admin@sarvmangal.app"}</div>
          </div>
        </div>
        <button id="logout-btn" class="btn btn-secondary btn-sm" title="End administrative session">
          <span>Sign Out</span>
        </button>
      </div>
    </header>

    <!-- Navigation Bar -->
    <nav class="portal-nav-bar flex-wrap">
      <button class="nav-tab active" data-tab="overview">
        <span>📊 System Overview</span>
      </button>
      <button class="nav-tab" data-tab="ui_editor">
        <span>🎨 App UI Editor & CMS</span>
      </button>
      <button class="nav-tab" data-tab="pandits">
        <span>🙏 Pandit KYC Queue</span>
      </button>
      <button class="nav-tab" data-tab="bookings">
        <span>🪔 Pooja Bookings</span>
      </button>
      <button class="nav-tab" data-tab="poojas">
        <span>🕉️ Pooja Catalogue</span>
      </button>
      <button class="nav-tab" data-tab="users">
        <span>👥 Users & Devotees</span>
      </button>
      <button class="nav-tab" data-tab="consultations">
        <span>📹 Consultations Desk</span>
      </button>
      <button class="nav-tab" data-tab="kundli">
        <span>📜 Kundli Orders</span>
      </button>
      <button class="nav-tab" data-tab="subscriptions">
        <span>⭐ Subscriptions</span>
      </button>
    </nav>

    <!-- Tab View Container -->
    <main class="portal-main" id="tab-viewport"></main>
  `;

  const logoutBtn = container.querySelector("#logout-btn") as HTMLButtonElement;
  const tabViewport = container.querySelector("#tab-viewport") as HTMLElement;
  const navTabs = container.querySelectorAll(".nav-tab");

  logoutBtn.addEventListener("click", async () => {
    logoutBtn.disabled = true;
    try {
      await adminApi.logout();
    } finally {
      clearSession();
      onLogout();
    }
  });

  function switchTab(tab: TabKey) {
    currentTab = tab;
    navTabs.forEach((btn) => {
      if (btn.getAttribute("data-tab") === tab) {
        btn.classList.add("active");
      } else {
        btn.classList.remove("active");
      }
    });

    switch (tab) {
      case "overview":
        renderOverviewTab(tabViewport);
        break;
      case "ui_editor":
        renderUiEditorTab(tabViewport);
        break;
      case "pandits":
        renderPanditsTab(tabViewport);
        break;
      case "bookings":
        renderBookingsTab(tabViewport);
        break;
      case "poojas":
        renderPoojasTab(tabViewport);
        break;
      case "users":
        renderUsersTab(tabViewport);
        break;
      case "consultations":
        renderConsultationsTab(tabViewport);
        break;
      case "kundli":
        renderKundliTab(tabViewport);
        break;
      case "subscriptions":
        renderSubscriptionsTab(tabViewport);
        break;
    }
  }


  navTabs.forEach((btn) => {
    btn.addEventListener("click", () => {
      const tab = btn.getAttribute("data-tab") as TabKey;
      if (tab && tab !== currentTab) {
        switchTab(tab);
      }
    });
  });

  // Initial tab render
  switchTab("overview");
}
