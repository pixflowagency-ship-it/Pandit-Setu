import { adminApi } from "../../api.ts";
import type { AppUiConfigPayload, AppConfigVersionRecord } from "../../types.ts";

export async function renderUiEditorTab(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="tab-header flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">App UI Editor & CMS</h2>
        <p class="text-sm text-gray-500">Remotely customize mobile app layouts, hero banners, 6-box services, and themes without mobile app republishing.</p>
      </div>
      <div class="flex gap-3">
        <button id="view-versions-btn" class="btn btn-secondary">
          📜 Version History & Rollback
        </button>
        <button id="save-draft-btn" class="btn btn-secondary">
          💾 Save Draft
        </button>
        <button id="publish-live-btn" class="btn btn-primary">
          🚀 Publish Live to App
        </button>
      </div>
    </div>

    <div id="editor-status-banner" class="hidden mb-4 p-4 rounded-lg"></div>

    <div class="editor-grid">
      <!-- Left Column: Configuration Controls -->
      <div class="editor-controls-panel">
        <!-- Sub-tabs within Editor -->
        <div class="editor-nav-pills mb-4">
          <button class="pill-btn active" data-editor-pane="sections">Sections & Order</button>
          <button class="pill-btn" data-editor-pane="banners">Hero Slides</button>
          <button class="pill-btn" data-editor-pane="grid">6-Box Services</button>
          <button class="pill-btn" data-editor-pane="problem">Life Problems</button>
          <button class="pill-btn" data-editor-pane="theme">Theme & Brand</button>
        </div>

        <div id="editor-panes-container">
          <!-- Panes dynamically injected -->
          <div class="loading-spinner">Loading draft configuration...</div>
        </div>
      </div>

      <!-- Right Column: Live Smartphone Simulator -->
      <div class="editor-preview-panel">
        <div class="phone-frame-wrapper">
          <div class="phone-top-notch"></div>
          <div class="phone-screen" id="phone-screen">
            <!-- Dynamic Real-Time Screen Preview -->
          </div>
        </div>
      </div>
    </div>

    <!-- Version History Modal -->
    <div id="versions-modal" class="modal-backdrop hidden">
      <div class="modal-box max-w-2xl">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-gray-900">App UI Version History</h3>
          <button id="close-versions-modal" class="text-gray-400 hover:text-gray-600 font-bold text-xl">&times;</button>
        </div>
        <p class="text-sm text-gray-600 mb-4">Review all published layout iterations or instantly roll back to any previous working state.</p>
        <div id="versions-list-container" class="space-y-3 max-h-96 overflow-y-auto">
          <div class="loading-spinner">Loading version logs...</div>
        </div>
      </div>
    </div>
  `;

  // Fetch draft configuration
  let draftData: {
    id: string | null;
    version: number;
    isNewDraft: boolean;
    config: AppUiConfigPayload;
    updatedAt: string | null;
  };

  try {
    draftData = await adminApi.getAppConfigDraft();
  } catch (err: any) {
    container.innerHTML = `
      <div class="p-6 bg-red-50 border border-red-200 rounded-lg text-red-700">
        <h3 class="font-bold">Failed to load App UI Configuration</h3>
        <p>${err.message}</p>
      </div>
    `;
    return;
  }

  const currentConfig: AppUiConfigPayload = JSON.parse(JSON.stringify(draftData.config));
  let activePane = "sections";

  const panesContainer = container.querySelector("#editor-panes-container") as HTMLElement;
  const phoneScreen = container.querySelector("#phone-screen") as HTMLElement;
  const statusBanner = container.querySelector("#editor-status-banner") as HTMLElement;

  function showStatus(message: string, isError = false) {
    statusBanner.className = `mb-4 p-4 rounded-lg flex items-center justify-between ${
      isError ? "bg-red-50 text-red-700 border border-red-200" : "bg-green-50 text-green-700 border border-green-200"
    }`;
    statusBanner.innerHTML = `
      <span>${isError ? "⚠️" : "✓"} ${message}</span>
      <button onclick="this.parentElement.classList.add('hidden')" class="font-bold text-lg">&times;</button>
    `;
    statusBanner.classList.remove("hidden");
  }

  function updatePreview() {
    phoneScreen.style.backgroundColor = currentConfig.theme.backgroundColor || "#FFF8EE";

    // Sort sections by order
    const sortedSections = [...currentConfig.sections].sort((a, b) => a.order - b.order);

    let sectionsHtml = "";

    for (const section of sortedSections) {
      if (!section.enabled) continue;

      if (section.id === "hero_slideshow") {
        const firstSlide = currentConfig.heroSlides[0] || {
          title: "Vedic Poojas & Rituals",
          subtitle: "Book verified Acharyas",
          tag: "SPECIAL",
          imageUrl: "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900",
        };

        sectionsHtml += `
          <div class="preview-hero-slide mb-3" style="background-image: url('${firstSlide.imageUrl}');">
            <div class="preview-hero-overlay">
              <span class="preview-hero-tag" style="background-color: ${currentConfig.theme.accentColor}">${firstSlide.tag}</span>
              <h4 class="preview-hero-title">${firstSlide.title}</h4>
              <p class="preview-hero-subtitle">${firstSlide.subtitle}</p>
            </div>
          </div>
        `;
      } else if (section.id === "six_box_grid") {
        const enabledServices = currentConfig.serviceGrid
          .filter((s) => s.enabled)
          .sort((a, b) => a.order - b.order);

        sectionsHtml += `
          <div class="preview-section mb-3">
            <div class="preview-section-title">${section.title}</div>
            <div class="preview-services-grid">
              ${enabledServices
                .map(
                  (s) => `
                <div class="preview-service-card">
                  <div class="preview-service-icon" style="color: ${currentConfig.theme.primaryColor}">✦</div>
                  <div class="preview-service-name">${s.title}</div>
                  <div class="preview-service-sub">${s.subtitle}</div>
                  ${s.badge ? `<span class="preview-service-badge">${s.badge}</span>` : ""}
                </div>
              `
                )
                .join("")}
            </div>
          </div>
        `;
      } else if (section.id === "life_problems") {
        if (currentConfig.lifeProblemsBanner.enabled) {
          sectionsHtml += `
            <div class="preview-problem-banner mb-3" style="background: linear-gradient(135deg, ${currentConfig.theme.primaryColor}, ${currentConfig.theme.accentColor});">
              <div class="font-bold text-white text-xs">${currentConfig.lifeProblemsBanner.title}</div>
              <div class="text-white text-opacity-80 text-[10px] mb-2">${currentConfig.lifeProblemsBanner.subtitle}</div>
              <span class="preview-problem-btn">${currentConfig.lifeProblemsBanner.buttonText}</span>
            </div>
          `;
        }
      } else if (section.id === "upcoming_booking") {
        sectionsHtml += `
          <div class="preview-generic-box mb-3">
            <div class="font-bold text-xs text-orange-900">🪔 ${section.title}</div>
            <div class="text-[10px] text-gray-500">Griha Pravesh Pooja • 27 Oct, 9:00 AM</div>
          </div>
        `;
      } else {
        sectionsHtml += `
          <div class="preview-generic-box mb-3">
            <div class="font-bold text-xs text-gray-800">${section.title}</div>
            <div class="text-[10px] text-gray-400">Remotely enabled section</div>
          </div>
        `;
      }
    }

    phoneScreen.innerHTML = `
      <div class="preview-status-bar">
        <span>9:41</span>
        <span>📶 5G 🔋</span>
      </div>
      <div class="preview-app-bar" style="border-bottom: 2px solid ${currentConfig.theme.accentColor}">
        <div class="flex items-center gap-1">
          <span style="color: ${currentConfig.theme.primaryColor}; font-size: 16px;">🕉️</span>
          <div>
            <div class="font-extrabold text-xs" style="color: ${currentConfig.theme.primaryColor}">SARV MANGAL</div>
            <div class="text-[8px] text-gray-500">Vedic Rituals & Astrology</div>
          </div>
        </div>
        <div class="flex gap-1 items-center">
          <span class="preview-lang-pill">हिंदी</span>
          <span class="text-xs">🔔</span>
        </div>
      </div>
      <div class="preview-scroll-content">
        ${sectionsHtml}
      </div>
      <div class="preview-bottom-nav">
        <span style="color: ${currentConfig.theme.primaryColor}">🏠 Home</span>
        <span>📜 Poojas</span>
        <span>♈ Kundli</span>
        <span>🛍️ Samagri</span>
        <span>👤 Profile</span>
      </div>
    `;
  }

  function renderPane() {
    if (activePane === "sections") {
      const sorted = [...currentConfig.sections].sort((a, b) => a.order - b.order);
      panesContainer.innerHTML = `
        <div class="card p-4">
          <h3 class="text-lg font-bold mb-2">Home Screen Sections & Ordering</h3>
          <p class="text-sm text-gray-500 mb-4">Rearrange section positions or toggle visibility on the live mobile home screen.</p>
          <div class="space-y-3">
            ${sorted
              .map(
                (sec, index) => `
              <div class="flex items-center justify-between p-3 bg-gray-50 border rounded-lg" data-section-id="${sec.id}">
                <div class="flex items-center gap-3">
                  <div class="flex flex-col gap-1">
                    <button class="reorder-btn move-up" ${index === 0 ? "disabled" : ""} data-index="${index}">▲</button>
                    <button class="reorder-btn move-down" ${index === sorted.length - 1 ? "disabled" : ""} data-index="${index}">▼</button>
                  </div>
                  <div>
                    <input type="text" class="section-title-input font-bold text-gray-800 text-sm border-b border-dashed border-gray-300 focus:border-orange-500" data-field="title" value="${sec.title}">
                    <div class="text-xs text-gray-500 mt-1">
                      Hindi: <input type="text" class="section-titlehi-input text-xs border-b border-dashed border-gray-300 focus:border-orange-500" data-field="titleHi" value="${sec.titleHi}">
                    </div>
                  </div>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" class="section-toggle" ${sec.enabled ? "checked" : ""} data-section-id="${sec.id}">
                  <span class="toggle-slider"></span>
                </label>
              </div>
            `
              )
              .join("")}
          </div>
        </div>
      `;

      // Event listeners for reordering & toggling
      panesContainer.querySelectorAll(".reorder-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
          const target = e.currentTarget as HTMLElement;
          const idx = parseInt(target.getAttribute("data-index") || "0", 10);
          const isUp = target.classList.contains("move-up");
          const targetIdx = isUp ? idx - 1 : idx + 1;

          if (targetIdx >= 0 && targetIdx < sorted.length) {
            const temp = sorted[idx].order;
            sorted[idx].order = sorted[targetIdx].order;
            sorted[targetIdx].order = temp;
            currentConfig.sections = sorted;
            renderPane();
            updatePreview();
          }
        });
      });

      panesContainer.querySelectorAll(".section-toggle").forEach((chk) => {
        chk.addEventListener("change", (e) => {
          const target = e.currentTarget as HTMLInputElement;
          const secId = target.getAttribute("data-section-id");
          const sec = currentConfig.sections.find((s) => s.id === secId);
          if (sec) {
            sec.enabled = target.checked;
            updatePreview();
          }
        });
      });

      panesContainer.querySelectorAll(".section-title-input").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const target = e.currentTarget as HTMLInputElement;
          const row = target.closest("[data-section-id]");
          const secId = row?.getAttribute("data-section-id");
          const sec = currentConfig.sections.find((s) => s.id === secId);
          if (sec) {
            sec.title = target.value;
            updatePreview();
          }
        });
      });

      panesContainer.querySelectorAll(".section-titlehi-input").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const target = e.currentTarget as HTMLInputElement;
          const row = target.closest("[data-section-id]");
          const secId = row?.getAttribute("data-section-id");
          const sec = currentConfig.sections.find((s) => s.id === secId);
          if (sec) {
            sec.titleHi = target.value;
            updatePreview();
          }
        });
      });
    } else if (activePane === "banners") {
      panesContainer.innerHTML = `
        <div class="card p-4">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-bold">Hero Slideshow Banners</h3>
            <button id="add-slide-btn" class="btn btn-secondary text-xs">+ Add Slide</button>
          </div>
          <div class="space-y-4 max-h-[520px] overflow-y-auto pr-1">
            ${currentConfig.heroSlides
              .map(
                (slide, sIdx) => `
              <div class="p-3 bg-gray-50 border rounded-lg relative" data-slide-index="${sIdx}">
                <button class="delete-slide-btn absolute top-2 right-2 text-red-500 hover:text-red-700 text-sm font-bold" data-index="${sIdx}">✕</button>
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Title (English)</label>
                    <input type="text" class="input input-sm slide-title" value="${slide.title}">
                  </div>
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Title (Hindi)</label>
                    <input type="text" class="input input-sm slide-titlehi" value="${slide.titleHi}">
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Subtitle (English)</label>
                    <input type="text" class="input input-sm slide-sub" value="${slide.subtitle}">
                  </div>
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Tag Label</label>
                    <input type="text" class="input input-sm slide-tag" value="${slide.tag}">
                  </div>
                </div>
                <div>
                  <label class="text-[11px] font-bold text-gray-600">Image URL</label>
                  <input type="url" class="input input-sm slide-img" value="${slide.imageUrl}">
                </div>
              </div>
            `
              )
              .join("")}
          </div>
        </div>
      `;

      panesContainer.querySelector("#add-slide-btn")?.addEventListener("click", () => {
        currentConfig.heroSlides.push({
          id: `slide-${Date.now()}`,
          title: "New Sacred Pooja Banner",
          titleHi: "नया वैदिक अनुष्ठान बैनर",
          subtitle: "Book authentic Vedic rituals",
          subtitleHi: "प्रामाणिक वैदिक पूजा बुक करें",
          tag: "SPECIAL",
          tagHi: "विशेष",
          imageUrl: "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900",
          actionType: "POOJA",
          actionTarget: "67e77a47-8ffb-403a-bc64-c948ab5e2abc",
        });
        renderPane();
        updatePreview();
      });

      panesContainer.querySelectorAll(".delete-slide-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-index") || "0", 10);
          if (currentConfig.heroSlides.length > 1) {
            currentConfig.heroSlides.splice(idx, 1);
            renderPane();
            updatePreview();
          } else {
            alert("At least one hero banner is required.");
          }
        });
      });

      panesContainer.querySelectorAll(".slide-title").forEach((inp, idx) => {
        inp.addEventListener("input", (e) => {
          currentConfig.heroSlides[idx].title = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".slide-titlehi").forEach((inp, idx) => {
        inp.addEventListener("input", (e) => {
          currentConfig.heroSlides[idx].titleHi = (e.target as HTMLInputElement).value;
        });
      });

      panesContainer.querySelectorAll(".slide-sub").forEach((inp, idx) => {
        inp.addEventListener("input", (e) => {
          currentConfig.heroSlides[idx].subtitle = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".slide-tag").forEach((inp, idx) => {
        inp.addEventListener("input", (e) => {
          currentConfig.heroSlides[idx].tag = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".slide-img").forEach((inp, idx) => {
        inp.addEventListener("input", (e) => {
          currentConfig.heroSlides[idx].imageUrl = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });
    } else if (activePane === "grid") {
      panesContainer.innerHTML = `
        <div class="card p-4">
          <h3 class="text-lg font-bold mb-2">6-Box Sacred Service Grid</h3>
          <p class="text-sm text-gray-500 mb-4">Edit title labels, subtitles, and badges for the home screen service cards.</p>
          <div class="space-y-3">
            ${currentConfig.serviceGrid
              .map(
                (service, sIdx) => `
              <div class="p-3 bg-gray-50 border rounded-lg">
                <div class="flex justify-between items-center mb-2">
                  <span class="font-bold text-sm text-gray-800">${service.id.toUpperCase()}</span>
                  <label class="toggle-switch">
                    <input type="checkbox" class="grid-toggle" ${service.enabled ? "checked" : ""} data-idx="${sIdx}">
                    <span class="toggle-slider"></span>
                  </label>
                </div>
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Title (English)</label>
                    <input type="text" class="input input-sm grid-title" data-idx="${sIdx}" value="${service.title}">
                  </div>
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Title (Hindi)</label>
                    <input type="text" class="input input-sm grid-titlehi" data-idx="${sIdx}" value="${service.titleHi}">
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-2">
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Subtitle</label>
                    <input type="text" class="input input-sm grid-sub" data-idx="${sIdx}" value="${service.subtitle}">
                  </div>
                  <div>
                    <label class="text-[11px] font-bold text-gray-600">Badge</label>
                    <input type="text" class="input input-sm grid-badge" data-idx="${sIdx}" value="${service.badge || ""}">
                  </div>
                </div>
              </div>
            `
              )
              .join("")}
          </div>
        </div>
      `;

      panesContainer.querySelectorAll(".grid-toggle").forEach((chk) => {
        chk.addEventListener("change", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-idx") || "0", 10);
          currentConfig.serviceGrid[idx].enabled = (e.target as HTMLInputElement).checked;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".grid-title").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-idx") || "0", 10);
          currentConfig.serviceGrid[idx].title = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".grid-titlehi").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-idx") || "0", 10);
          currentConfig.serviceGrid[idx].titleHi = (e.target as HTMLInputElement).value;
        });
      });

      panesContainer.querySelectorAll(".grid-sub").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-idx") || "0", 10);
          currentConfig.serviceGrid[idx].subtitle = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });

      panesContainer.querySelectorAll(".grid-badge").forEach((inp) => {
        inp.addEventListener("input", (e) => {
          const idx = parseInt((e.currentTarget as HTMLElement).getAttribute("data-idx") || "0", 10);
          currentConfig.serviceGrid[idx].badge = (e.target as HTMLInputElement).value;
          updatePreview();
        });
      });
    } else if (activePane === "problem") {
      panesContainer.innerHTML = `
        <div class="card p-4">
          <h3 class="text-lg font-bold mb-2">Life Problems Consultation Banner</h3>
          <p class="text-sm text-gray-500 mb-4">Manage the quick call-to-action banner for devotee problem resolution.</p>
          <div class="space-y-3">
            <div class="flex items-center justify-between mb-3">
              <span class="font-bold text-sm">Banner Enabled</span>
              <label class="toggle-switch">
                <input type="checkbox" id="problem-enabled-toggle" ${currentConfig.lifeProblemsBanner.enabled ? "checked" : ""}>
                <span class="toggle-slider"></span>
              </label>
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Heading (English)</label>
              <input type="text" id="problem-title" class="input mt-1" value="${currentConfig.lifeProblemsBanner.title}">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Heading (Hindi)</label>
              <input type="text" id="problem-titlehi" class="input mt-1" value="${currentConfig.lifeProblemsBanner.titleHi}">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Subtitle (English)</label>
              <input type="text" id="problem-sub" class="input mt-1" value="${currentConfig.lifeProblemsBanner.subtitle}">
            </div>
            <div>
              <label class="text-xs font-bold text-gray-700">Button Text</label>
              <input type="text" id="problem-btn-text" class="input mt-1" value="${currentConfig.lifeProblemsBanner.buttonText}">
            </div>
          </div>
        </div>
      `;

      panesContainer.querySelector("#problem-enabled-toggle")?.addEventListener("change", (e) => {
        currentConfig.lifeProblemsBanner.enabled = (e.target as HTMLInputElement).checked;
        updatePreview();
      });

      panesContainer.querySelector("#problem-title")?.addEventListener("input", (e) => {
        currentConfig.lifeProblemsBanner.title = (e.target as HTMLInputElement).value;
        updatePreview();
      });

      panesContainer.querySelector("#problem-titlehi")?.addEventListener("input", (e) => {
        currentConfig.lifeProblemsBanner.titleHi = (e.target as HTMLInputElement).value;
      });

      panesContainer.querySelector("#problem-sub")?.addEventListener("input", (e) => {
        currentConfig.lifeProblemsBanner.subtitle = (e.target as HTMLInputElement).value;
        updatePreview();
      });

      panesContainer.querySelector("#problem-btn-text")?.addEventListener("input", (e) => {
        currentConfig.lifeProblemsBanner.buttonText = (e.target as HTMLInputElement).value;
        updatePreview();
      });
    } else if (activePane === "theme") {
      panesContainer.innerHTML = `
        <div class="card p-4">
          <h3 class="text-lg font-bold mb-2">Theme & Brand Colors</h3>
          <p class="text-sm text-gray-500 mb-4">Adjust approved brand palette tokens. Preview updates live in simulator.</p>
          <div class="space-y-4">
            <div class="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <div class="font-bold text-sm">Primary Brand Color</div>
                <div class="text-xs text-gray-500">Header icons, primary buttons, accents</div>
              </div>
              <input type="color" id="primary-color-picker" value="${currentConfig.theme.primaryColor}" class="w-10 h-10 rounded border cursor-pointer">
            </div>

            <div class="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <div class="font-bold text-sm">Accent Color</div>
                <div class="text-xs text-gray-500">Badges, highlights, active indicators</div>
              </div>
              <input type="color" id="accent-color-picker" value="${currentConfig.theme.accentColor}" class="w-10 h-10 rounded border cursor-pointer">
            </div>

            <div class="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <div class="font-bold text-sm">Background Tint</div>
                <div class="text-xs text-gray-500">Scaffold canvas background</div>
              </div>
              <input type="color" id="bg-color-picker" value="${currentConfig.theme.backgroundColor}" class="w-10 h-10 rounded border cursor-pointer">
            </div>
          </div>
        </div>
      `;

      panesContainer.querySelector("#primary-color-picker")?.addEventListener("input", (e) => {
        currentConfig.theme.primaryColor = (e.target as HTMLInputElement).value;
        updatePreview();
      });

      panesContainer.querySelector("#accent-color-picker")?.addEventListener("input", (e) => {
        currentConfig.theme.accentColor = (e.target as HTMLInputElement).value;
        updatePreview();
      });

      panesContainer.querySelector("#bg-color-picker")?.addEventListener("input", (e) => {
        currentConfig.theme.backgroundColor = (e.target as HTMLInputElement).value;
        updatePreview();
      });
    }
  }

  // Pill click handlers
  container.querySelectorAll(".pill-btn").forEach((pill) => {
    pill.addEventListener("click", (e) => {
      container.querySelectorAll(".pill-btn").forEach((p) => p.classList.remove("active"));
      const target = e.currentTarget as HTMLElement;
      target.classList.add("active");
      activePane = target.getAttribute("data-editor-pane") || "sections";
      renderPane();
    });
  });

  // Action: Save Draft
  container.querySelector("#save-draft-btn")?.addEventListener("click", async () => {
    try {
      const summary = prompt("Brief summary of draft changes (optional):", "Draft update");
      const res = await adminApi.saveAppConfigDraft(currentConfig, summary || undefined);
      showStatus(`Draft saved successfully (Draft ID: ${res.id})`);
    } catch (err: any) {
      showStatus(`Failed to save draft: ${err.message}`, true);
    }
  });

  // Action: Publish Live
  container.querySelector("#publish-live-btn")?.addEventListener("click", async () => {
    const confirmPublish = confirm("Are you sure you want to atomically publish these changes to all live mobile users?");
    if (!confirmPublish) return;

    const summary = prompt("Enter publication release note:", "Updated home layout and banners");
    try {
      // First ensure draft is saved
      await adminApi.saveAppConfigDraft(currentConfig, summary || undefined);
      // Publish
      const res = await adminApi.publishAppConfig(summary || undefined);
      showStatus(`🚀 Version ${res.version} is now LIVE for all users! (Published at ${new Date(res.publishedAt).toLocaleTimeString()})`);
    } catch (err: any) {
      showStatus(`Failed to publish: ${err.message}`, true);
    }
  });

  // Action: Version History & Rollback Modal
  const versionsModal = container.querySelector("#versions-modal") as HTMLElement;
  const versionsList = container.querySelector("#versions-list-container") as HTMLElement;

  container.querySelector("#view-versions-btn")?.addEventListener("click", async () => {
    versionsModal.classList.remove("hidden");
    versionsList.innerHTML = `<div class="loading-spinner">Loading version logs...</div>`;

    try {
      const { versions } = await adminApi.getAppConfigVersions();
      if (versions.length === 0) {
        versionsList.innerHTML = `<p class="text-sm text-gray-500">No version history recorded yet.</p>`;
        return;
      }

      versionsList.innerHTML = versions
        .map(
          (v: AppConfigVersionRecord) => `
        <div class="flex items-center justify-between p-3 border rounded-lg ${v.status === "PUBLISHED" ? "bg-orange-50 border-orange-300" : "bg-white"}">
          <div>
            <div class="flex items-center gap-2">
              <span class="font-bold text-sm text-gray-900">Version ${v.version}</span>
              <span class="badge ${v.status === "PUBLISHED" ? "badge-success" : "badge-neutral"}">${v.status}</span>
            </div>
            <div class="text-xs text-gray-600 mt-1">${v.changeSummary || "No notes"}</div>
            <div class="text-[10px] text-gray-400 mt-0.5">${v.publishedAt ? new Date(v.publishedAt).toLocaleString() : ""} • By ${v.publishedBy || "Admin"}</div>
          </div>
          ${
            v.status !== "PUBLISHED"
              ? `<button class="rollback-btn btn btn-secondary text-xs" data-version-id="${v.id}" data-version-num="${v.version}">Rollback Here</button>`
              : `<span class="text-xs text-green-700 font-bold">Active</span>`
          }
        </div>
      `
        )
        .join("");

      // Rollback handlers
      versionsList.querySelectorAll(".rollback-btn").forEach((btn) => {
        btn.addEventListener("click", async (e) => {
          const vId = (e.currentTarget as HTMLElement).getAttribute("data-version-id")!;
          const vNum = (e.currentTarget as HTMLElement).getAttribute("data-version-num")!;
          const confirmed = confirm(`Roll back active home configuration to Version ${vNum}?`);
          if (!confirmed) return;

          try {
            const res = await adminApi.rollbackAppConfig(vId);
            versionsModal.classList.add("hidden");
            showStatus(`Successfully rolled back! Now on Version ${res.version} (Restored from v${res.rolledBackFromVersion})`);
            // Reload draft & preview
            const fresh = await adminApi.getAppConfigDraft();
            Object.assign(currentConfig, fresh.config);
            renderPane();
            updatePreview();
          } catch (err: any) {
            alert(`Rollback failed: ${err.message}`);
          }
        });
      });
    } catch (err: any) {
      versionsList.innerHTML = `<p class="text-sm text-red-600">Failed to load versions: ${err.message}</p>`;
    }
  });

  container.querySelector("#close-versions-modal")?.addEventListener("click", () => {
    versionsModal.classList.add("hidden");
  });

  // Initial render
  renderPane();
  updatePreview();
}
