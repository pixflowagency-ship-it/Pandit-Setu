import { adminApi } from "../../api.ts";
import type { KundliOrderRecord } from "../../types.ts";

export async function renderKundliTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="view-header">
      <div>
        <h2 class="view-title">Handmade Kundli Orders Desk</h2>
        <p class="view-subtitle">Fulfill astrological charts, coordinate Vedic pandit handwritten calculations, and track courier dispatches</p>
      </div>
      <button id="refresh-kundli-btn" class="btn btn-secondary btn-sm">
        <span>🔄 Refresh Orders</span>
      </button>
    </div>

    <div class="table-card">
      <div id="kundli-table-container">
        <div class="state-box">
          <div class="spinner"></div>
          <p>Querying handmade Kundli orders...</p>
        </div>
      </div>
    </div>

    <div id="modal-container"></div>
  `;

  const refreshBtn = container.querySelector("#refresh-kundli-btn") as HTMLButtonElement;
  const tableContainer = container.querySelector("#kundli-table-container") as HTMLElement;
  const modalContainer = container.querySelector("#modal-container") as HTMLElement;

  async function loadData() {
    tableContainer.innerHTML = `
      <div class="state-box">
        <div class="spinner"></div>
        <p>Querying handmade Kundli orders...</p>
      </div>
    `;

    try {
      const res = await adminApi.getKundliOrders(1, 100);
      renderTable(tableContainer, res.orders, openDecisionModal, openDispatchModal);
    } catch (err: any) {
      tableContainer.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger);">Failed to load Kundli orders: ${err.message}</p>
        </div>
      `;
    }
  }

  function openDecisionModal(item: KundliOrderRecord, decision: "ACCEPT" | "REJECT") {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">${decision === "ACCEPT" ? "Accept Kundli Order" : "Reject Kundli Order"}</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div style="text-align: left;">
            <p style="margin-bottom: 12px;">Order #: <strong>${item.orderNumber}</strong></p>
            <p style="margin-bottom: 12px;">Devotee: <strong>${item.devoteeName}</strong> (Gotra: ${item.gotra || "—"})</p>
            ${
              decision === "REJECT"
                ? `<div class="form-group">
                    <label class="form-label" for="kundli-reject-reason">REJECTION REASON (REQUIRED)</label>
                    <textarea id="kundli-reject-reason" class="form-textarea" rows="3" placeholder="Provide reason for refund/rejection..."></textarea>
                   </div>`
                : `<p style="color: var(--text-muted); font-size: 13px;">Accepting moves this order to processing and enables Pandit assignment for astrological preparation.</p>`
            }
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary modal-close-btn">Cancel</button>
            <button id="confirm-decision-btn" class="btn ${decision === "ACCEPT" ? "btn-success" : "btn-danger"}">
              Confirm ${decision === "ACCEPT" ? "Acceptance" : "Rejection"}
            </button>
          </div>
        </div>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close, .modal-close-btn").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    const confirmBtn = modalContainer.querySelector("#confirm-decision-btn") as HTMLButtonElement;
    confirmBtn.addEventListener("click", async () => {
      let reason: string | undefined;
      if (decision === "REJECT") {
        const input = modalContainer.querySelector("#kundli-reject-reason") as HTMLTextAreaElement;
        reason = input.value.trim();
        if (!reason) {
          alert("Please provide a rejection reason.");
          return;
        }
      }

      confirmBtn.disabled = true;
      confirmBtn.textContent = "Updating...";

      try {
        await adminApi.decisionKundliOrder(item.id, decision, reason);
        modalContainer.innerHTML = "";
        loadData();
      } catch (err: any) {
        alert(`Failed to record decision: ${err.message}`);
        confirmBtn.disabled = false;
        confirmBtn.textContent = `Confirm ${decision === "ACCEPT" ? "Acceptance" : "Rejection"}`;
      }
    });
  }

  function openDispatchModal(item: KundliOrderRecord) {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">Update Kundli Fulfillment Status</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div style="text-align: left;">
            <p style="margin-bottom: 16px;">Order #: <strong>${item.orderNumber}</strong> (${item.devoteeName})</p>
            <div class="form-group">
              <label class="form-label" for="kundli-status-select">STATUS</label>
              <select id="kundli-status-select" class="form-select">
                <option value="PREPARING">PREPARING (Handmade Calculations)</option>
                <option value="DISPATCHED">DISPATCHED (In Courier Transit)</option>
                <option value="DELIVERED">DELIVERED</option>
                <option value="CANCELLED">CANCELLED</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label" for="courier-partner">COURIER PARTNER (OPTIONAL)</label>
              <input id="courier-partner" type="text" class="form-input" placeholder="BlueDart / Delhivery / India Post" />
            </div>
            <div class="form-group">
              <label class="form-label" for="tracking-num">TRACKING AWB NUMBER (OPTIONAL)</label>
              <input id="tracking-num" type="text" class="form-input" placeholder="AWB-9876543210" />
            </div>
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary modal-close-btn">Cancel</button>
            <button id="confirm-status-btn" class="btn btn-primary">Update Status</button>
          </div>
        </div>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close, .modal-close-btn").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    const confirmBtn = modalContainer.querySelector("#confirm-status-btn") as HTMLButtonElement;
    confirmBtn.addEventListener("click", async () => {
      const statusVal = (modalContainer.querySelector("#kundli-status-select") as HTMLSelectElement).value;
      const courier = (modalContainer.querySelector("#courier-partner") as HTMLInputElement).value.trim();
      const tracking = (modalContainer.querySelector("#tracking-num") as HTMLInputElement).value.trim();

      confirmBtn.disabled = true;
      confirmBtn.textContent = "Updating...";

      try {
        await adminApi.updateKundliStatus(item.id, statusVal, tracking || undefined, courier || undefined);
        modalContainer.innerHTML = "";
        loadData();
      } catch (err: any) {
        alert(`Failed to update status: ${err.message}`);
        confirmBtn.disabled = false;
        confirmBtn.textContent = "Update Status";
      }
    });
  }

  refreshBtn.addEventListener("click", loadData);
  loadData();
}

function renderTable(
  container: HTMLElement,
  orders: KundliOrderRecord[],
  onDecision: (item: KundliOrderRecord, d: "ACCEPT" | "REJECT") => void,
  onDispatch: (item: KundliOrderRecord) => void
): void {
  if (orders.length === 0) {
    container.innerHTML = `
      <div class="state-box">
        <p>No Kundli orders found in the queue.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="table-responsive">
      <table class="data-table">
        <thead>
          <tr>
            <th>Order #</th>
            <th>Devotee Details</th>
            <th>Birth Data (DOB / POB / Gotra)</th>
            <th>Language</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${orders
            .map(
              (o) => `
            <tr>
              <td>
                <div style="font-weight: 600;">${o.orderNumber}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${new Date(o.createdAt).toLocaleDateString()}</div>
              </td>
              <td>
                <div style="font-weight: 600;">${o.devoteeName}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${o.userPhone || "—"}</div>
              </td>
              <td>
                <div>${o.dob} at ${o.tob || "—"}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${o.pob || "—"} (Gotra: ${o.gotra || "—"})</div>
              </td>
              <td>${o.language}</td>
              <td>
                <span class="badge ${o.status === "DELIVERED" ? "badge-success" : o.status === "CANCELLED" ? "badge-danger" : "badge-warning"}">
                  ${o.status}
                </span>
              </td>
              <td>
                <div style="display: flex; gap: 8px;">
                  <button class="btn btn-success btn-sm accept-btn" data-id="${o.id}">Accept</button>
                  <button class="btn btn-danger btn-sm reject-btn" data-id="${o.id}">Reject</button>
                  <button class="btn btn-secondary btn-sm dispatch-btn" data-id="${o.id}">Fulfillment</button>
                </div>
              </td>
            </tr>
          `
            )
            .join("")}
        </tbody>
      </table>
    </div>
  `;

  container.querySelectorAll(".accept-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const item = orders.find((o) => o.id === id);
      if (item) onDecision(item, "ACCEPT");
    });
  });

  container.querySelectorAll(".reject-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const item = orders.find((o) => o.id === id);
      if (item) onDecision(item, "REJECT");
    });
  });

  container.querySelectorAll(".dispatch-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const item = orders.find((o) => o.id === id);
      if (item) onDispatch(item);
    });
  });
}
