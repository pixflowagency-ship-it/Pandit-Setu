import { adminApi } from "../../api.ts";
import type { AdminStats } from "../../types.ts";

export async function renderOverviewTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="view-header">
      <div>
        <h2 class="view-title">System & Operations Overview</h2>
        <p class="view-subtitle">Live health status and lifecycle queues across SARV MANGAL platform</p>
      </div>
      <button id="refresh-overview-btn" class="btn btn-secondary btn-sm">
        <span>🔄 Refresh Live Metrics</span>
      </button>
    </div>

    <div id="overview-content">
      <div class="state-box">
        <div class="spinner"></div>
        <p>Querying operational metrics from backend cluster...</p>
      </div>
    </div>
  `;

  const refreshBtn = container.querySelector("#refresh-overview-btn") as HTMLButtonElement;
  const content = container.querySelector("#overview-content") as HTMLElement;

  async function loadData() {
    try {
      content.innerHTML = `
        <div class="state-box">
          <div class="spinner"></div>
          <p>Querying operational metrics from backend cluster...</p>
        </div>
      `;
      const [stats, health] = await Promise.all([
        adminApi.getStats(),
        adminApi.getHealth().catch(() => ({ status: "unknown" })),
      ]);

      renderMetrics(content, stats, health.status);
    } catch (err: any) {
      content.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger); margin-bottom: 12px;">Failed to load system metrics: ${err.message}</p>
          <button id="retry-load-btn" class="btn btn-secondary btn-sm">Retry Query</button>
        </div>
      `;
      content.querySelector("#retry-load-btn")?.addEventListener("click", loadData);
    }
  }

  refreshBtn.addEventListener("click", loadData);
  loadData();
}

function renderMetrics(container: HTMLElement, stats: AdminStats, healthStatus: string): void {
  const isHealthy = healthStatus === "ok";

  container.innerHTML = `
    <div class="metrics-grid">
      <!-- Health Card -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">API Cluster Health</span>
          <div class="metric-icon">⚡</div>
        </div>
        <div class="metric-value" style="color: ${isHealthy ? "var(--status-success)" : "var(--status-danger)"};">
          ${isHealthy ? "OPERATIONAL" : "DEGRADED"}
        </div>
        <div class="metric-meta">
          <span>Protected Route: /api/v1/admin/health</span>
        </div>
      </div>

      <!-- Pandit KYC Card -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">Pandit KYC Queue</span>
          <div class="metric-icon">🙏</div>
        </div>
        <div class="metric-value">${stats.pandits.pending}</div>
        <div class="metric-meta">
          <span style="color: var(--status-success); font-weight: 600;">${stats.pandits.approved} Approved</span> • 
          <span style="color: var(--status-danger); font-weight: 600;">${stats.pandits.rejected} Rejected</span>
        </div>
      </div>

      <!-- Vedic Consultations -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">Consultation Desk</span>
          <div class="metric-icon">📹</div>
        </div>
        <div class="metric-value">${stats.consultations.total}</div>
        <div class="metric-meta">
          <span style="color: var(--status-warning); font-weight: 600;">${stats.consultations.pending} Pending Action</span> • 
          <span>Persistent DB Record</span>
        </div>
      </div>

      <!-- Handmade Kundli Desk -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">Kundli Orders</span>
          <div class="metric-icon">📜</div>
        </div>
        <div class="metric-value">${stats.kundliOrders.total}</div>
        <div class="metric-meta">
          <span style="color: var(--status-warning); font-weight: 600;">${stats.kundliOrders.pending} Action Needed</span> • 
          <span>Astrological Delivery</span>
        </div>
      </div>

      <!-- Pooja Bookings -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">Pooja Ritual Bookings</span>
          <div class="metric-icon">🪔</div>
        </div>
        <div class="metric-value">${stats.bookings.total}</div>
        <div class="metric-meta">
          <span style="color: var(--status-success); font-weight: 600;">${stats.bookings.completed} Completed</span> • 
          <span>${stats.bookings.pending} Pending</span>
        </div>
      </div>

      <!-- Recurring Subscriptions -->
      <div class="metric-card">
        <div class="metric-header">
          <span class="metric-title">Active Devotee Plans</span>
          <div class="metric-icon">⭐</div>
        </div>
        <div class="metric-value">${stats.subscriptions.active}</div>
        <div class="metric-meta">
          <span>${stats.subscriptions.total} Total Devotee Subscriptions</span>
        </div>
      </div>
    </div>
  `;
}
