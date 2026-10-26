import { adminApi } from "../../api.ts";
import type { AdminPoojaRecord } from "../../types.ts";

export async function renderPoojasTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="tab-header flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Services & Pooja Catalogue</h2>
        <p class="text-sm text-gray-500">Configure Vedic rituals, base dakshina prices, samagri kits, and required Acharyas.</p>
      </div>
      <button id="create-pooja-btn" class="btn btn-primary">+ Add New Pooja</button>
    </div>

    <!-- Poojas Grid Container -->
    <div id="poojas-container" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="loading-spinner">Loading catalogue...</div>
    </div>

    <!-- Create / Edit Pooja Modal -->
    <div id="pooja-modal" class="modal-backdrop hidden">
      <div class="modal-box max-w-xl">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-gray-900" id="pooja-modal-title">Pooja Configuration</h3>
          <button id="close-pooja-modal" class="text-gray-400 hover:text-gray-600 font-bold text-xl">&times;</button>
        </div>
        <form id="pooja-form" class="space-y-4">
          <input type="hidden" id="form-pooja-id">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-xs font-bold text-gray-700">Pooja Title</label>
              <input type="text" id="pooja-title-input" class="input mt-1" required placeholder="e.g., Satyanarayan Katha">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">URL Slug</label>
              <input type="text" id="pooja-slug-input" class="input mt-1" required placeholder="e.g., satyanarayan-katha">
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-xs font-bold text-gray-700">Category</label>
              <input type="text" id="pooja-category-input" class="input mt-1" placeholder="e.g., Ghar & Jeevan">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Duration (Display)</label>
              <input type="text" id="pooja-duration-input" class="input mt-1" placeholder="e.g., 2-3 Hours">
            </div>
          </div>

          <div class="grid grid-cols-3 gap-3">
            <div>
              <label class="text-xs font-bold text-gray-700">Base Price (₹)</label>
              <input type="number" id="pooja-price-input" class="input mt-1" required min="0" step="50">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Samagri Price (₹)</label>
              <input type="number" id="pooja-samagri-input" class="input mt-1" min="0" step="50" value="0">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Duration (Mins)</label>
              <input type="number" id="pooja-mins-input" class="input mt-1" required min="15" value="120">
            </div>
          </div>

          <div>
            <label class="text-xs font-bold text-gray-700">Cover Image URL</label>
            <input type="url" id="pooja-img-input" class="input mt-1" placeholder="https://images.unsplash.com/...">
          </div>

          <div>
            <label class="text-xs font-bold text-gray-700">Description</label>
            <textarea id="pooja-desc-input" class="input mt-1 w-full" rows="3" placeholder="Significance and overview of the ritual..."></textarea>
          </div>

          <div class="flex items-center gap-2">
            <input type="checkbox" id="pooja-active-input" checked>
            <label for="pooja-active-input" class="text-sm font-medium text-gray-700">Active in User Catalogue</label>
          </div>

          <div class="flex justify-end gap-3 pt-2">
            <button type="button" id="cancel-pooja-btn" class="btn btn-secondary">Cancel</button>
            <button type="submit" class="btn btn-primary">Save Pooja</button>
          </div>
        </form>
      </div>
    </div>
  `;

  const containerEl = container.querySelector("#poojas-container") as HTMLElement;
  const modal = container.querySelector("#pooja-modal") as HTMLElement;
  const form = container.querySelector("#pooja-form") as HTMLFormElement;
  const modalTitle = container.querySelector("#pooja-modal-title") as HTMLElement;

  const idInput = container.querySelector("#form-pooja-id") as HTMLInputElement;
  const titleInput = container.querySelector("#pooja-title-input") as HTMLInputElement;
  const slugInput = container.querySelector("#pooja-slug-input") as HTMLInputElement;
  const categoryInput = container.querySelector("#pooja-category-input") as HTMLInputElement;
  const durationInput = container.querySelector("#pooja-duration-input") as HTMLInputElement;
  const priceInput = container.querySelector("#pooja-price-input") as HTMLInputElement;
  const samagriInput = container.querySelector("#pooja-samagri-input") as HTMLInputElement;
  const minsInput = container.querySelector("#pooja-mins-input") as HTMLInputElement;
  const imgInput = container.querySelector("#pooja-img-input") as HTMLInputElement;
  const descInput = container.querySelector("#pooja-desc-input") as HTMLTextAreaElement;
  const activeInput = container.querySelector("#pooja-active-input") as HTMLInputElement;

  let poojasList: AdminPoojaRecord[] = [];

  async function loadPoojas() {
    containerEl.innerHTML = `<div class="loading-spinner">Loading catalogue...</div>`;

    try {
      const res = await adminApi.getPoojas(undefined, 1, 50);
      poojasList = res.items;

      if (poojasList.length === 0) {
        containerEl.innerHTML = `<div class="col-span-3 p-8 text-center text-gray-500">No poojas registered in catalogue. Click "Add New Pooja" to create one.</div>`;
        return;
      }

      containerEl.innerHTML = poojasList
        .map(
          (p) => `
        <div class="card overflow-hidden flex flex-col justify-between">
          <div>
            ${
              p.imageUrl
                ? `<div class="h-40 bg-cover bg-center" style="background-image: url('${p.imageUrl}')"></div>`
                : `<div class="h-40 bg-orange-100 flex items-center justify-center text-4xl">🕉️</div>`
            }
            <div class="p-4">
              <div class="flex justify-between items-start mb-2">
                <span class="badge ${p.isActive ? "badge-success" : "badge-neutral"}">${p.isActive ? "Active" : "Hidden"}</span>
                <span class="text-xs text-gray-400">${p.category || "General"}</span>
              </div>
              <h3 class="font-bold text-lg text-gray-900 mb-1">${p.title}</h3>
              <p class="text-xs text-gray-500 mb-3 line-clamp-2">${p.description || "Authentic Vedic ceremony"}</p>
              <div class="flex justify-between items-center text-sm font-bold border-t pt-2">
                <div>
                  <span class="text-gray-400 text-xs">Dakshina:</span>
                  <span class="text-orange-600">₹${p.basePrice}</span>
                </div>
                ${
                  p.samagriPrice && p.samagriPrice !== "0.00"
                    ? `
                  <div>
                    <span class="text-gray-400 text-xs">Samagri:</span>
                    <span class="text-gray-700">₹${p.samagriPrice}</span>
                  </div>
                `
                    : ""
                }
              </div>
            </div>
          </div>
          <div class="p-4 border-t bg-gray-50 flex justify-between items-center">
            <span class="text-xs text-gray-500">⏱️ ${p.duration || `${p.durationMinutes}m`}</span>
            <button class="btn btn-secondary text-xs edit-pooja-btn" data-id="${p.id}">Edit Ritual</button>
          </div>
        </div>
      `
        )
        .join("");

      containerEl.querySelectorAll(".edit-pooja-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
          const id = (e.currentTarget as HTMLElement).getAttribute("data-id")!;
          const p = poojasList.find((item) => item.id === id);
          if (p) {
            modalTitle.textContent = "Edit Pooja Ritual";
            idInput.value = p.id;
            titleInput.value = p.title;
            slugInput.value = p.slug;
            categoryInput.value = p.category || "";
            durationInput.value = p.duration || "";
            priceInput.value = String(p.basePrice);
            samagriInput.value = String(p.samagriPrice || 0);
            minsInput.value = String(p.durationMinutes);
            imgInput.value = p.imageUrl || "";
            descInput.value = p.description || "";
            activeInput.checked = p.isActive;
            modal.classList.remove("hidden");
          }
        });
      });
    } catch (err: any) {
      containerEl.innerHTML = `<div class="col-span-3 p-6 text-red-600">Failed to load catalogue: ${err.message}</div>`;
    }
  }

  container.querySelector("#create-pooja-btn")?.addEventListener("click", () => {
    modalTitle.textContent = "Create New Vedic Pooja";
    idInput.value = "";
    form.reset();
    activeInput.checked = true;
    modal.classList.remove("hidden");
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const poojaId = idInput.value;

    const payload: Partial<AdminPoojaRecord> = {
      title: titleInput.value.trim(),
      slug: slugInput.value.trim(),
      category: categoryInput.value.trim() || undefined,
      duration: durationInput.value.trim() || undefined,
      basePrice: priceInput.value,
      samagriPrice: samagriInput.value,
      durationMinutes: parseInt(minsInput.value, 10),
      imageUrl: imgInput.value.trim() || undefined,
      description: descInput.value.trim() || undefined,
      isActive: activeInput.checked,
    };

    try {
      if (poojaId) {
        await adminApi.updatePooja(poojaId, payload);
      } else {
        await adminApi.createPooja(payload);
      }
      modal.classList.add("hidden");
      loadPoojas();
    } catch (err: any) {
      alert(`Error saving pooja: ${err.message}`);
    }
  });

  container.querySelector("#close-pooja-modal")?.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  container.querySelector("#cancel-pooja-btn")?.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  loadPoojas();
}
