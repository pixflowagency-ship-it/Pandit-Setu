import { adminApi } from "../../api.ts";
import type { AdminBookingRecord } from "../../types.ts";

export async function renderBookingsTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="tab-header flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Pooja Bookings Management Desk</h2>
        <p class="text-sm text-gray-500">Track and manage the end-to-end lifecycle of all online and home ritual bookings.</p>
      </div>
    </div>

    <!-- Status Filters -->
    <div class="card p-4 mb-6 flex items-center justify-between">
      <div class="flex gap-2">
        <button class="status-filter-btn btn btn-primary" data-status="ALL">All Bookings</button>
        <button class="status-filter-btn btn btn-secondary" data-status="PENDING">Pending</button>
        <button class="status-filter-btn btn btn-secondary" data-status="ACCEPTED">Accepted</button>
        <button class="status-filter-btn btn btn-secondary" data-status="CONFIRMED">Confirmed</button>
        <button class="status-filter-btn btn btn-secondary" data-status="IN_PROGRESS">In Progress</button>
        <button class="status-filter-btn btn btn-secondary" data-status="COMPLETED">Completed</button>
        <button class="status-filter-btn btn btn-secondary" data-status="CANCELLED">Cancelled</button>
      </div>
    </div>

    <!-- Bookings Table Container -->
    <div class="card overflow-hidden">
      <div id="bookings-table-container">
        <div class="loading-spinner">Loading bookings queue...</div>
      </div>
      <div id="bookings-pagination" class="p-4 border-t flex justify-between items-center text-sm text-gray-600"></div>
    </div>

    <!-- Update Status Modal -->
    <div id="booking-modal" class="modal-backdrop hidden">
      <div class="modal-box max-w-md">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-gray-900">Update Booking Lifecycle Status</h3>
          <button id="close-booking-modal" class="text-gray-400 hover:text-gray-600 font-bold text-xl">&times;</button>
        </div>
        <form id="booking-status-form" class="space-y-4">
          <input type="hidden" id="edit-booking-id">
          <div>
            <label class="text-sm font-medium text-gray-700">New Status</label>
            <select id="edit-booking-status" class="input mt-1 w-full">
              <option value="PENDING">PENDING</option>
              <option value="ACCEPTED">ACCEPTED</option>
              <option value="CONFIRMED">CONFIRMED</option>
              <option value="IN_PROGRESS">IN_PROGRESS</option>
              <option value="COMPLETED">COMPLETED</option>
              <option value="CANCELLED">CANCELLED</option>
            </select>
          </div>
          <div>
            <label class="text-sm font-medium text-gray-700">Audit Notes / Reason</label>
            <textarea id="edit-booking-notes" class="input mt-1 w-full" rows="3" placeholder="Enter administrative notes for this status change..."></textarea>
          </div>
          <div class="flex justify-end gap-3">
            <button type="button" id="cancel-booking-btn" class="btn btn-secondary">Cancel</button>
            <button type="submit" class="btn btn-primary">Save Status</button>
          </div>
        </form>
      </div>
    </div>
  `;

  let currentStatus = "ALL";
  let currentPage = 1;

  const tableContainer = container.querySelector("#bookings-table-container") as HTMLElement;
  const paginationContainer = container.querySelector("#bookings-pagination") as HTMLElement;
  const modal = container.querySelector("#booking-modal") as HTMLElement;
  const statusForm = container.querySelector("#booking-status-form") as HTMLFormElement;
  const editIdInput = container.querySelector("#edit-booking-id") as HTMLInputElement;
  const editStatusSelect = container.querySelector("#edit-booking-status") as HTMLSelectElement;
  const editNotesInput = container.querySelector("#edit-booking-notes") as HTMLTextAreaElement;

  async function loadBookings() {
    tableContainer.innerHTML = `<div class="loading-spinner">Loading bookings queue...</div>`;

    try {
      const res = await adminApi.getBookings(currentStatus, currentPage, 20);

      if (res.items.length === 0) {
        tableContainer.innerHTML = `<div class="p-8 text-center text-gray-500">No bookings found for status "${currentStatus}".</div>`;
        paginationContainer.innerHTML = "";
        return;
      }

      tableContainer.innerHTML = `
        <table class="table w-full">
          <thead>
            <tr>
              <th>Pooja Ritual</th>
              <th>Devotee (Yajman)</th>
              <th>Mode</th>
              <th>Schedule</th>
              <th>Amount</th>
              <th>Payment</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            ${res.items
              .map(
                (b: AdminBookingRecord) => `
              <tr class="hover:bg-gray-50">
                <td class="font-bold text-gray-900">${b.poojaTitle || "Vedic Pooja"}</td>
                <td>
                  <div class="font-medium">${b.yajmanName || "Devotee"}</div>
                  <div class="text-xs text-gray-400">${b.yajmanPhone || "—"}</div>
                </td>
                <td>
                  <span class="badge ${b.mode === "ONLINE" ? "badge-info" : "badge-neutral"}">${b.mode}</span>
                </td>
                <td class="text-xs text-gray-600">${new Date(b.bookingTime).toLocaleString()}</td>
                <td class="font-bold">₹${b.totalAmount}</td>
                <td>
                  <span class="badge ${b.paymentStatus === "PAID" ? "badge-success" : "badge-warning"}">${b.paymentStatus}</span>
                </td>
                <td>
                  <span class="badge ${
                    b.status === "COMPLETED"
                      ? "badge-success"
                      : b.status === "CANCELLED"
                      ? "badge-danger"
                      : b.status === "IN_PROGRESS"
                      ? "badge-primary"
                      : "badge-neutral"
                  }">
                    ${b.status}
                  </span>
                </td>
                <td>
                  <button class="btn btn-secondary text-xs update-booking-btn" data-booking-id="${b.id}" data-current-status="${b.status}">
                    Update Status
                  </button>
                </td>
              </tr>
            `
              )
              .join("")}
          </tbody>
        </table>
      `;

      paginationContainer.innerHTML = `
        <span>Showing ${(currentPage - 1) * 20 + 1} to ${Math.min(currentPage * 20, res.pagination.total)} of ${res.pagination.total} bookings</span>
        <div class="flex gap-2">
          <button id="prev-b-btn" class="btn btn-secondary text-xs" ${currentPage <= 1 ? "disabled" : ""}>Previous</button>
          <span class="px-3 py-1 font-bold">Page ${currentPage} of ${res.pagination.totalPages}</span>
          <button id="next-b-btn" class="btn btn-secondary text-xs" ${currentPage >= res.pagination.totalPages ? "disabled" : ""}>Next</button>
        </div>
      `;

      paginationContainer.querySelector("#prev-b-btn")?.addEventListener("click", () => {
        if (currentPage > 1) {
          currentPage--;
          loadBookings();
        }
      });

      paginationContainer.querySelector("#next-b-btn")?.addEventListener("click", () => {
        if (currentPage < res.pagination.totalPages) {
          currentPage++;
          loadBookings();
        }
      });

      tableContainer.querySelectorAll(".update-booking-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
          const target = e.currentTarget as HTMLElement;
          const bId = target.getAttribute("data-booking-id")!;
          const currStatus = target.getAttribute("data-current-status")!;
          editIdInput.value = bId;
          editStatusSelect.value = currStatus;
          editNotesInput.value = "";
          modal.classList.remove("hidden");
        });
      });
    } catch (err: any) {
      tableContainer.innerHTML = `<div class="p-6 text-red-600">Error loading bookings: ${err.message}</div>`;
    }
  }

  // Filter clicks
  container.querySelectorAll(".status-filter-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      container.querySelectorAll(".status-filter-btn").forEach((b) => {
        b.classList.remove("btn-primary");
        b.classList.add("btn-secondary");
      });
      const target = e.currentTarget as HTMLElement;
      target.classList.remove("btn-secondary");
      target.classList.add("btn-primary");
      currentStatus = target.getAttribute("data-status") || "ALL";
      currentPage = 1;
      loadBookings();
    });
  });

  statusForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const bId = editIdInput.value;
    const newStatus = editStatusSelect.value;
    const notes = editNotesInput.value.trim();

    try {
      await adminApi.updateBookingStatus(bId, newStatus, notes || undefined);
      modal.classList.add("hidden");
      loadBookings();
    } catch (err: any) {
      alert(`Failed to update status: ${err.message}`);
    }
  });

  container.querySelector("#close-booking-modal")?.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  container.querySelector("#cancel-booking-btn")?.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  loadBookings();
}
