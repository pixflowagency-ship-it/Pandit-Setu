import { adminApi } from "../../api.ts";
import type { ConsultationRecord } from "../../types.ts";

export async function renderConsultationsTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="view-header">
      <div>
        <h2 class="view-title">Vedic Consultations Desk</h2>
        <p class="view-subtitle">Coordinate astrological consultations, assign certified scholars, and manage video schedules</p>
      </div>
      <button id="refresh-consultations-btn" class="btn btn-secondary btn-sm">
        <span>🔄 Refresh Queue</span>
      </button>
    </div>

    <div class="table-card">
      <div id="consultations-table-container">
        <div class="state-box">
          <div class="spinner"></div>
          <p>Querying consultations...</p>
        </div>
      </div>
    </div>

    <div id="modal-container"></div>
  `;

  const refreshBtn = container.querySelector("#refresh-consultations-btn") as HTMLButtonElement;
  const tableContainer = container.querySelector("#consultations-table-container") as HTMLElement;
  const modalContainer = container.querySelector("#modal-container") as HTMLElement;

  async function loadData() {
    tableContainer.innerHTML = `
      <div class="state-box">
        <div class="spinner"></div>
        <p>Querying consultations...</p>
      </div>
    `;

    try {
      const res = await adminApi.getConsultations(1, 100);
      renderTable(tableContainer, res.consultations, openScheduleModal, openStatusModal);
    } catch (err: any) {
      tableContainer.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger);">Failed to load consultations: ${err.message}</p>
        </div>
      `;
    }
  }

  function openScheduleModal(item: ConsultationRecord) {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">Schedule Vedic Consultation</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div style="text-align: left;">
            <p style="margin-bottom: 16px;">Consultation #: <strong>${item.consultationNumber}</strong></p>
            <div class="form-group">
              <label class="form-label" for="scheduled-at">CONFIRMED DATE & TIME (ISO / DATETIME)</label>
              <input id="scheduled-at" type="datetime-local" class="form-input" required />
            </div>
            <div class="form-group">
              <label class="form-label" for="meeting-link">AGORA / SECURE MEETING URL</label>
              <input id="meeting-link" type="url" class="form-input" placeholder="https://agora.io/channel/..." required />
            </div>
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary modal-close-btn">Cancel</button>
            <button id="confirm-schedule-btn" class="btn btn-primary">Save Schedule</button>
          </div>
        </div>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close, .modal-close-btn").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    const confirmBtn = modalContainer.querySelector("#confirm-schedule-btn") as HTMLButtonElement;
    confirmBtn.addEventListener("click", async () => {
      const dateVal = (modalContainer.querySelector("#scheduled-at") as HTMLInputElement).value;
      const linkVal = (modalContainer.querySelector("#meeting-link") as HTMLInputElement).value;

      if (!dateVal || !linkVal) {
        alert("Please provide both confirmed date/time and meeting URL.");
        return;
      }

      confirmBtn.disabled = true;
      confirmBtn.textContent = "Saving...";

      try {
        await adminApi.scheduleConsultation(item.id, new Date(dateVal).toISOString(), linkVal);
        modalContainer.innerHTML = "";
        loadData();
      } catch (err: any) {
        alert(`Failed to schedule: ${err.message}`);
        confirmBtn.disabled = false;
        confirmBtn.textContent = "Save Schedule";
      }
    });
  }

  function openStatusModal(item: ConsultationRecord) {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">Update Consultation Lifecycle</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div style="text-align: left;">
            <p style="margin-bottom: 16px;">Consultation #: <strong>${item.consultationNumber}</strong></p>
            <div class="form-group">
              <label class="form-label" for="status-select">NEW STATUS</label>
              <select id="status-select" class="form-select">
                <option value="SCHEDULED">SCHEDULED</option>
                <option value="IN_PROGRESS">IN_PROGRESS</option>
                <option value="COMPLETED">COMPLETED</option>
                <option value="CANCELLED">CANCELLED</option>
              </select>
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
      const statusVal = (modalContainer.querySelector("#status-select") as HTMLSelectElement).value;
      confirmBtn.disabled = true;
      confirmBtn.textContent = "Updating...";

      try {
        await adminApi.updateConsultationStatus(item.id, statusVal);
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
  consultations: ConsultationRecord[],
  onSchedule: (c: ConsultationRecord) => void,
  onStatus: (c: ConsultationRecord) => void
): void {
  if (consultations.length === 0) {
    container.innerHTML = `
      <div class="state-box">
        <p>No consultation requests found in the desk queue.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="table-responsive">
      <table class="data-table">
        <thead>
          <tr>
            <th>Consultation #</th>
            <th>Preferred Timing</th>
            <th>Topic</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${consultations
            .map(
              (c) => `
            <tr>
              <td>
                <div style="font-weight: 600;">${c.consultationNumber}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${new Date(c.createdAt).toLocaleDateString()}</div>
              </td>
              <td>
                <div>${c.preferredDate || "—"}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${c.preferredTime || "—"}</div>
              </td>
              <td>${c.topic || "General Astro Consultation"}</td>
              <td>
                <span class="badge ${c.status === "COMPLETED" ? "badge-success" : c.status === "CANCELLED" ? "badge-danger" : "badge-warning"}">
                  ${c.status}
                </span>
              </td>
              <td>
                <div style="display: flex; gap: 8px;">
                  <button class="btn btn-secondary btn-sm schedule-btn" data-id="${c.id}">Schedule</button>
                  <button class="btn btn-secondary btn-sm status-btn" data-id="${c.id}">Update Status</button>
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

  container.querySelectorAll(".schedule-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const c = consultations.find((item) => item.id === id);
      if (c) onSchedule(c);
    });
  });

  container.querySelectorAll(".status-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const c = consultations.find((item) => item.id === id);
      if (c) onStatus(c);
    });
  });
}
