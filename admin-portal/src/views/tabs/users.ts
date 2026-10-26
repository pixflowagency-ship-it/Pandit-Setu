import { adminApi } from "../../api.ts";
import type { AdminUserRecord } from "../../types.ts";

export async function renderUsersTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="tab-header flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Users & Accounts Management</h2>
        <p class="text-sm text-gray-500">Monitor devotees, registered Pandits, and administrative accounts with real-time profile lookup.</p>
      </div>
    </div>

    <!-- Filters & Search Toolbar -->
    <div class="card p-4 mb-6 flex flex-wrap gap-4 items-center justify-between">
      <div class="flex items-center gap-3 flex-1 min-w-[280px]">
        <input type="text" id="user-search-input" class="input flex-1" placeholder="Search by name, phone, or email...">
        <button id="search-users-btn" class="btn btn-primary">Search</button>
      </div>
      <div class="flex items-center gap-3">
        <label class="text-sm font-medium text-gray-700">Role Filter:</label>
        <select id="user-role-select" class="input py-2">
          <option value="ALL">All Roles</option>
          <option value="YAJMAN">Yajmans (Devotees)</option>
          <option value="PANDIT">Pandits (Acharyas)</option>
          <option value="ADMIN">Administrators</option>
        </select>
      </div>
    </div>

    <!-- Users Table Container -->
    <div class="card overflow-hidden">
      <div id="users-table-container">
        <div class="loading-spinner">Loading users registry...</div>
      </div>
      <div id="users-pagination" class="p-4 border-t flex justify-between items-center text-sm text-gray-600"></div>
    </div>

    <!-- User Detail Modal -->
    <div id="user-detail-modal" class="modal-backdrop hidden">
      <div class="modal-box max-w-xl">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-gray-900" id="detail-user-name">User Profile</h3>
          <button id="close-user-modal" class="text-gray-400 hover:text-gray-600 font-bold text-xl">&times;</button>
        </div>
        <div id="detail-user-body" class="space-y-4">
          <div class="loading-spinner">Loading details...</div>
        </div>
      </div>
    </div>
  `;

  let currentSearch = "";
  let currentRole = "ALL";
  let currentPage = 1;

  const tableContainer = container.querySelector("#users-table-container") as HTMLElement;
  const paginationContainer = container.querySelector("#users-pagination") as HTMLElement;
  const searchInput = container.querySelector("#user-search-input") as HTMLInputElement;
  const roleSelect = container.querySelector("#user-role-select") as HTMLSelectElement;
  const modal = container.querySelector("#user-detail-modal") as HTMLElement;
  const detailBody = container.querySelector("#detail-user-body") as HTMLElement;
  const detailName = container.querySelector("#detail-user-name") as HTMLElement;

  async function loadUsers() {
    tableContainer.innerHTML = `<div class="loading-spinner">Loading users registry...</div>`;

    try {
      const res = await adminApi.getUsers(currentSearch || undefined, currentRole, currentPage, 20);

      if (res.items.length === 0) {
        tableContainer.innerHTML = `<div class="p-8 text-center text-gray-500">No users found matching current filters.</div>`;
        paginationContainer.innerHTML = "";
        return;
      }

      tableContainer.innerHTML = `
        <table class="table w-full">
          <thead>
            <tr>
              <th>Name</th>
              <th>Phone</th>
              <th>Email</th>
              <th>City</th>
              <th>Role</th>
              <th>Registered</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            ${res.items
              .map(
                (u: AdminUserRecord) => `
              <tr class="hover:bg-gray-50">
                <td class="font-bold text-gray-900">${u.name}</td>
                <td>${u.phone}</td>
                <td class="text-gray-500">${u.email || "—"}</td>
                <td>${u.city || "—"}</td>
                <td>
                  <span class="badge ${
                    u.role === "ADMIN" ? "badge-primary" : u.role === "PANDIT" ? "badge-warning" : "badge-neutral"
                  }">
                    ${u.role}
                  </span>
                </td>
                <td class="text-xs text-gray-400">${new Date(u.createdAt).toLocaleDateString()}</td>
                <td>
                  <button class="btn btn-secondary text-xs view-user-btn" data-user-id="${u.id}">View Details</button>
                </td>
              </tr>
            `
              )
              .join("")}
          </tbody>
        </table>
      `;

      paginationContainer.innerHTML = `
        <span>Showing ${(currentPage - 1) * 20 + 1} to ${Math.min(currentPage * 20, res.pagination.total)} of ${res.pagination.total} users</span>
        <div class="flex gap-2">
          <button id="prev-page-btn" class="btn btn-secondary text-xs" ${currentPage <= 1 ? "disabled" : ""}>Previous</button>
          <span class="px-3 py-1 font-bold">Page ${currentPage} of ${res.pagination.totalPages}</span>
          <button id="next-page-btn" class="btn btn-secondary text-xs" ${currentPage >= res.pagination.totalPages ? "disabled" : ""}>Next</button>
        </div>
      `;

      paginationContainer.querySelector("#prev-page-btn")?.addEventListener("click", () => {
        if (currentPage > 1) {
          currentPage--;
          loadUsers();
        }
      });

      paginationContainer.querySelector("#next-page-btn")?.addEventListener("click", () => {
        if (currentPage < res.pagination.totalPages) {
          currentPage++;
          loadUsers();
        }
      });

      tableContainer.querySelectorAll(".view-user-btn").forEach((btn) => {
        btn.addEventListener("click", async (e) => {
          const uId = (e.currentTarget as HTMLElement).getAttribute("data-user-id")!;
          openUserDetail(uId);
        });
      });
    } catch (err: any) {
      tableContainer.innerHTML = `<div class="p-6 text-red-600">Error loading users: ${err.message}</div>`;
    }
  }

  async function openUserDetail(userId: string) {
    modal.classList.remove("hidden");
    detailBody.innerHTML = `<div class="loading-spinner">Loading user history...</div>`;

    try {
      const data = await adminApi.getUserDetail(userId);
      detailName.textContent = `${data.user.name} (${data.user.role})`;

      detailBody.innerHTML = `
        <div class="grid grid-cols-2 gap-3 text-sm p-3 bg-gray-50 rounded-lg">
          <div><span class="text-gray-500">Phone:</span> <strong>${data.user.phone}</strong></div>
          <div><span class="text-gray-500">Email:</span> <strong>${data.user.email || "—"}</strong></div>
          <div><span class="text-gray-500">City:</span> <strong>${data.user.city || "—"}</strong></div>
          <div><span class="text-gray-500">Gotra:</span> <strong>${data.user.gotra || "—"}</strong></div>
          <div><span class="text-gray-500">Zodiac:</span> <strong>${data.user.zodiac || "—"}</strong></div>
          <div><span class="text-gray-500">Address:</span> <strong>${data.user.address || "—"}</strong></div>
        </div>

        ${
          data.panditProfile
            ? `
          <div class="p-3 bg-orange-50 border border-orange-200 rounded-lg">
            <h4 class="font-bold text-orange-900 mb-2">Pandit Credentials</h4>
            <div class="text-xs text-orange-800 space-y-1">
              <div>Experience: <strong>${data.panditProfile.experienceYears || 0} years</strong></div>
              <div>Vedic Specialization: <strong>${data.panditProfile.vedicSpecialization || "General"}</strong></div>
              <div>Verification Status: <strong>${data.panditProfile.verificationStatus}</strong></div>
              <div>Mantra Status: <strong>${data.panditProfile.mantraRecordingStatus || "NOT_SUBMITTED"}</strong></div>
            </div>
          </div>
        `
            : ""
        }

        <div>
          <h4 class="font-bold text-sm text-gray-800 mb-2">Recent Pooja Bookings (${data.recentBookings.length})</h4>
          ${
            data.recentBookings.length === 0
              ? `<p class="text-xs text-gray-500">No bookings on record.</p>`
              : `
            <div class="space-y-2">
              ${data.recentBookings
                .map(
                  (b: any) => `
                <div class="p-2 bg-gray-50 border rounded text-xs flex justify-between items-center">
                  <div>
                    <span class="font-bold">${b.poojaTitle || "Vedic Pooja"}</span>
                    <span class="text-gray-500"> • ${b.mode}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold">₹${b.totalAmount}</span>
                    <span class="badge badge-neutral">${b.status}</span>
                  </div>
                </div>
              `
                )
                .join("")}
            </div>
          `
          }
        </div>
      `;
    } catch (err: any) {
      detailBody.innerHTML = `<div class="p-4 text-red-600">Failed to load details: ${err.message}</div>`;
    }
  }

  container.querySelector("#close-user-modal")?.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  container.querySelector("#search-users-btn")?.addEventListener("click", () => {
    currentSearch = searchInput.value.trim();
    currentPage = 1;
    loadUsers();
  });

  searchInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      currentSearch = searchInput.value.trim();
      currentPage = 1;
      loadUsers();
    }
  });

  roleSelect.addEventListener("change", () => {
    currentRole = roleSelect.value;
    currentPage = 1;
    loadUsers();
  });

  loadUsers();
}
