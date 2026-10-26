import { adminApi } from "../../api.ts";
import type { SubscriptionRecord } from "../../types.ts";

export async function renderSubscriptionsTab(container: HTMLElement): Promise<void> {
  let currentFilter = "ALL";

  container.innerHTML = `
    <div class="view-header">
      <div>
        <h2 class="view-title">Devotee Subscriptions Oversight</h2>
        <p class="view-subtitle">Monitor recurring monthly pooja subscriptions, recurring Dakshina pledges, and billing states</p>
      </div>
      <button id="refresh-subscriptions-btn" class="btn btn-secondary btn-sm">
        <span>🔄 Refresh Subscriptions</span>
      </button>
    </div>

    <div class="table-card">
      <div class="table-toolbar">
        <div class="filter-group">
          <button class="filter-btn active" data-filter="ALL">All Plans</button>
          <button class="filter-btn" data-filter="ACTIVE">Active Recurring</button>
          <button class="filter-btn" data-filter="PENDING">Pending Auth</button>
          <button class="filter-btn" data-filter="HALTED">Halted / Past Due</button>
        </div>
      </div>

      <div id="subscriptions-table-container">
        <div class="state-box">
          <div class="spinner"></div>
          <p>Querying devotee subscriptions...</p>
        </div>
      </div>
    </div>
  `;

  const refreshBtn = container.querySelector("#refresh-subscriptions-btn") as HTMLButtonElement;
  const tableContainer = container.querySelector("#subscriptions-table-container") as HTMLElement;
  const filterBtns = container.querySelectorAll(".filter-btn");

  filterBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      filterBtns.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      currentFilter = btn.getAttribute("data-filter") || "ALL";
      loadData();
    });
  });

  async function loadData() {
    tableContainer.innerHTML = `
      <div class="state-box">
        <div class="spinner"></div>
        <p>Querying devotee subscriptions...</p>
      </div>
    `;

    try {
      const res = await adminApi.getSubscriptions(currentFilter, 1, 100);
      renderTable(tableContainer, res.subscriptions);
    } catch (err: any) {
      tableContainer.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger);">Failed to load subscriptions: ${err.message}</p>
        </div>
      `;
    }
  }

  refreshBtn.addEventListener("click", loadData);
  loadData();
}

function renderTable(container: HTMLElement, subs: SubscriptionRecord[]): void {
  if (subs.length === 0) {
    container.innerHTML = `
      <div class="state-box">
        <p>No devotee subscriptions found under this filter.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="table-responsive">
      <table class="data-table">
        <thead>
          <tr>
            <th>Subscription Ref</th>
            <th>Plan Code</th>
            <th>Monthly Amount</th>
            <th>Status</th>
            <th>Enrollment Date</th>
          </tr>
        </thead>
        <tbody>
          ${subs
            .map(
              (s) => `
            <tr>
              <td>
                <div style="font-weight: 600;">${s.id.slice(0, 8)}...</div>
                <div style="font-size: 11px; color: var(--text-muted);">${s.userPhone || s.userId.slice(0, 8)}</div>
              </td>
              <td>${s.planId}</td>
              <td style="font-weight: 600; color: var(--primary-light);">₹${((s.amount || 0) / 100).toFixed(2)}</td>
              <td>
                <span class="badge ${s.status === "ACTIVE" ? "badge-success" : s.status === "HALTED" || s.status === "CANCELLED" ? "badge-danger" : "badge-warning"}">
                  ${s.status}
                </span>
              </td>
              <td>${new Date(s.createdAt).toLocaleDateString()}</td>
            </tr>
          `
            )
            .join("")}
        </tbody>
      </table>
    </div>
  `;
}
