import { adminApi } from "../../api.ts";
import type { PanditApplication, ApprovedMantra } from "../../types.ts";

export async function renderPanditsTab(container: HTMLElement): Promise<void> {
  let currentFilter = "ALL";

  container.innerHTML = `
    <div class="view-header">
      <div>
        <h2 class="view-title">Pandit Onboarding & KYC Desk</h2>
        <p class="view-subtitle">Review credentials, verify Vedic certifications, evaluate Mantra video recordings, and authorize pandits for duty dispatch</p>
      </div>
      <div style="display: flex; gap: 8px;">
        <button id="manage-mantras-btn" class="btn btn-secondary btn-sm">
          <span>📜 Manage Mantras</span>
        </button>
        <button id="refresh-pandits-btn" class="btn btn-secondary btn-sm">
          <span>🔄 Refresh Queue</span>
        </button>
      </div>
    </div>

    <div class="table-card">
      <div class="table-toolbar">
        <div class="filter-group">
          <button class="filter-btn active" data-filter="ALL">All Applicants</button>
          <button class="filter-btn" data-filter="PENDING">Pending Verification</button>
          <button class="filter-btn" data-filter="MANTRA_PENDING">Mantra Video Queue</button>
          <button class="filter-btn" data-filter="APPROVED">Approved Pandits</button>
          <button class="filter-btn" data-filter="REJECTED">Rejected</button>
        </div>
      </div>

      <div id="pandits-table-container">
        <div class="state-box">
          <div class="spinner"></div>
          <p>Loading Pandit applications...</p>
        </div>
      </div>
    </div>

    <div id="modal-container"></div>
  `;

  const refreshBtn = container.querySelector("#refresh-pandits-btn") as HTMLButtonElement;
  const manageMantrasBtn = container.querySelector("#manage-mantras-btn") as HTMLButtonElement;
  const tableContainer = container.querySelector("#pandits-table-container") as HTMLElement;
  const modalContainer = container.querySelector("#modal-container") as HTMLElement;
  const filterBtns = container.querySelectorAll(".filter-btn");

  filterBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      filterBtns.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      currentFilter = btn.getAttribute("data-filter") || "ALL";
      loadPandits();
    });
  });

  async function loadPandits() {
    tableContainer.innerHTML = `
      <div class="state-box">
        <div class="spinner"></div>
        <p>Loading Pandit applications...</p>
      </div>
    `;

    try {
      const apiFilter = currentFilter === "MANTRA_PENDING" ? "PENDING" : currentFilter;
      const res = await adminApi.getPandits(apiFilter, 1, 100);
      let list = res.pandits || [];
      if (currentFilter === "MANTRA_PENDING") {
        list = list.filter(
          (p) =>
            p.mantraRecordingStatus === "PENDING" ||
            p.verificationStage?.includes("MANTRA") ||
            (p.verificationStatus === "PENDING" && p.mantraRecordingStatus !== "APPROVED")
        );
      }
      renderTable(tableContainer, list, openDetailModal, openApprovalModal);
    } catch (err: any) {
      tableContainer.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger);">Failed to load pandits: ${err.message}</p>
        </div>
      `;
    }
  }

  // Manage Mantras Modal
  async function openManageMantrasModal() {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog" style="max-width: 800px; max-height: 90vh; overflow-y: auto;">
          <div class="modal-header">
            <div>
              <h3 class="modal-title">Approved Vedic Mantra Library</h3>
              <p style="margin: 4px 0 0; font-size: 12px; color: var(--text-muted);">Configure prescribed Sanskrit recitation prompts for Pandit onboarding video verification.</p>
            </div>
            <button class="modal-close">&times;</button>
          </div>
          <div style="display: flex; justify-content: flex-end; margin-bottom: 12px;">
            <button id="add-mantra-btn" class="btn btn-primary btn-sm">+ Add New Mantra</button>
          </div>
          <div id="mantras-list-container">
            <div class="state-box">
              <div class="spinner"></div>
              <p>Loading approved mantras...</p>
            </div>
          </div>
        </div>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    const addBtn = modalContainer.querySelector("#add-mantra-btn") as HTMLButtonElement;
    addBtn.addEventListener("click", () => openMantraFormModal());

    await loadMantrasList();
  }

  async function loadMantrasList() {
    const listContainer = modalContainer.querySelector("#mantras-list-container") as HTMLElement;
    if (!listContainer) return;

    try {
      const mantras = await adminApi.getAdminMantras();
      if (!mantras || mantras.length === 0) {
        listContainer.innerHTML = `
          <div class="state-box">
            <p>No mantras currently configured in the database.</p>
          </div>
        `;
        return;
      }

      listContainer.innerHTML = `
        <div style="display: flex; flex-direction: column; gap: 12px;">
          ${mantras
            .map(
              (m) => `
            <div style="background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 8px; padding: 14px;">
              <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                  <div style="font-weight: 700; font-size: 15px; color: var(--primary);">${m.title}</div>
                  <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">ID: <code>${m.id}</code> • Order: ${m.displayOrder ?? 0} • Duration: ${m.minDurationSeconds}s – ${m.maxDurationSeconds}s</div>
                </div>
                <span class="badge ${m.isActive ? "badge-success" : "badge-secondary"}">
                  ${m.isActive ? "Active" : "Inactive"}
                </span>
              </div>
              <div style="margin-top: 8px; font-size: 14px; font-family: serif; color: var(--text-main); background: rgba(0,0,0,0.02); padding: 8px; border-radius: 4px;">
                ${m.sanskritText}
              </div>
              ${
                m.transliteration
                  ? `<div style="margin-top: 6px; font-size: 12px; color: var(--text-muted); font-style: italic;">${m.transliteration}</div>`
                  : ""
              }
              ${
                m.pronunciationGuidance
                  ? `<div style="margin-top: 6px; font-size: 12px; color: var(--primary);"><strong>Guidance:</strong> ${m.pronunciationGuidance}</div>`
                  : ""
              }
              <div style="display: flex; gap: 8px; margin-top: 10px;">
                <button class="btn btn-sm btn-secondary edit-mantra-btn" data-id="${m.id}">✏️ Edit</button>
                <button class="btn btn-sm ${m.isActive ? "btn-warning" : "btn-success"} toggle-mantra-btn" data-id="${m.id}" data-active="${m.isActive}">
                  ${m.isActive ? "Deactivate" : "Activate"}
                </button>
              </div>
            </div>
          `
            )
            .join("")}
        </div>
      `;

      listContainer.querySelectorAll(".edit-mantra-btn").forEach((btn) => {
        btn.addEventListener("click", () => {
          const id = btn.getAttribute("data-id")!;
          const mantra = mantras.find((x) => x.id === id);
          if (mantra) openMantraFormModal(mantra);
        });
      });

      listContainer.querySelectorAll(".toggle-mantra-btn").forEach((btn) => {
        btn.addEventListener("click", async () => {
          const id = btn.getAttribute("data-id")!;
          const currentActive = btn.getAttribute("data-active") === "true";
          const confirmMsg = currentActive
            ? "Deactivate this mantra? Pandits will no longer see it in the onboarding selection."
            : "Activate this mantra for Pandit onboarding video verification?";
          if (!confirm(confirmMsg)) return;

          const buttonEl = btn as HTMLButtonElement;
          buttonEl.disabled = true;
          try {
            await adminApi.updateAdminMantra(id, { isActive: !currentActive });
            await loadMantrasList();
          } catch (err: any) {
            alert(`Failed to update mantra status: ${err.message}`);
            buttonEl.disabled = false;
          }
        });
      });
    } catch (err: any) {
      listContainer.innerHTML = `
        <div class="state-box">
          <p style="color: var(--status-danger);">Failed to load mantras: ${err.message}</p>
        </div>
      `;
    }
  }

  function openMantraFormModal(existing?: ApprovedMantra) {
    const isEdit = !!existing;
    const formModalId = "mantra-form-modal";

    const existingModal = document.getElementById(formModalId);
    if (existingModal) existingModal.remove();

    const formWrapper = document.createElement("div");
    formWrapper.id = formModalId;
    formWrapper.className = "modal-backdrop";
    formWrapper.style.zIndex = "1050";
    formWrapper.innerHTML = `
      <div class="modal-dialog" style="max-width: 600px; max-height: 90vh; overflow-y: auto;">
        <div class="modal-header">
          <h3 class="modal-title">${isEdit ? "Edit Approved Mantra" : "Add New Approved Mantra"}</h3>
          <button class="modal-close" id="form-modal-close">&times;</button>
        </div>
        <form id="mantra-editor-form">
          ${
            !isEdit
              ? `<div class="form-group">
                  <label class="form-label" for="mantra-id">MANTRAL ID / SLUG (E.G. GAYATRI_MANTRA)</label>
                  <input type="text" id="mantra-id" class="form-input" placeholder="e.g. SHIV_TANDAV_STOTRAM" required />
                 </div>`
              : ""
          }
          <div class="form-group">
            <label class="form-label" for="mantra-title">MANTRAL TITLE (ENGLISH / DEVANAGARI)</label>
            <input type="text" id="mantra-title" class="form-input" value="${existing?.title || ""}" placeholder="e.g. Gayatri Mahamantra (गायत्री महामंत्र)" required />
          </div>
          <div class="form-group">
            <label class="form-label" for="mantra-sanskrit">SANSKRIT / DEVANAGARI TEXT (REQUIRED)</label>
            <textarea id="mantra-sanskrit" class="form-textarea" rows="3" placeholder="Paste approved Sanskrit Shloka/Devanagari text..." required>${existing?.sanskritText || ""}</textarea>
          </div>
          <div class="form-group">
            <label class="form-label" for="mantra-transliteration">ROMAN TRANSLITERATION (OPTIONAL)</label>
            <textarea id="mantra-transliteration" class="form-textarea" rows="2" placeholder="Om Bhur Bhuvah Swah...">${existing?.transliteration || ""}</textarea>
          </div>
          <div class="form-group">
            <label class="form-label" for="mantra-meaning">MEANING / SIGNIFICANCE (OPTIONAL)</label>
            <textarea id="mantra-meaning" class="form-textarea" rows="2" placeholder="English description of the sacred prayer...">${existing?.meaning || ""}</textarea>
          </div>
          <div class="form-group">
            <label class="form-label" for="mantra-guidance">PRONUNCIATION GUIDANCE (OPTIONAL)</label>
            <textarea id="mantra-guidance" class="form-textarea" rows="2" placeholder="e.g. Ensure clear Sandhi pauses and steady Gayatri Chhanda tempo...">${existing?.pronunciationGuidance || ""}</textarea>
          </div>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            <div class="form-group">
              <label class="form-label" for="mantra-min-sec">MIN DURATION (SEC)</label>
              <input type="number" id="mantra-min-sec" class="form-input" min="5" max="180" value="${existing?.minDurationSeconds ?? 10}" required />
            </div>
            <div class="form-group">
              <label class="form-label" for="mantra-max-sec">MAX DURATION (SEC)</label>
              <input type="number" id="mantra-max-sec" class="form-input" min="15" max="300" value="${existing?.maxDurationSeconds ?? 120}" required />
            </div>
          </div>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            <div class="form-group">
              <label class="form-label" for="mantra-order">DISPLAY ORDER</label>
              <input type="number" id="mantra-order" class="form-input" value="${existing?.displayOrder ?? 0}" />
            </div>
            <div class="form-group" style="display: flex; align-items: center; margin-top: 24px;">
              <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; font-size: 13px;">
                <input type="checkbox" id="mantra-active" ${existing?.isActive !== false ? "checked" : ""} />
                Active for Onboarding
              </label>
            </div>
          </div>
          <div class="modal-actions" style="margin-top: 16px;">
            <button type="button" class="btn btn-secondary" id="form-cancel-btn">Cancel</button>
            <button type="submit" class="btn btn-primary" id="form-submit-btn">Save Mantra</button>
          </div>
        </form>
      </div>
    `;

    document.body.appendChild(formWrapper);

    const closeForm = () => formWrapper.remove();
    formWrapper.querySelector("#form-modal-close")?.addEventListener("click", closeForm);
    formWrapper.querySelector("#form-cancel-btn")?.addEventListener("click", closeForm);

    const form = formWrapper.querySelector("#mantra-editor-form") as HTMLFormElement;
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const submitBtn = form.querySelector("#form-submit-btn") as HTMLButtonElement;
      submitBtn.disabled = true;
      submitBtn.textContent = "Saving...";

      const title = (form.querySelector("#mantra-title") as HTMLInputElement).value.trim();
      const sanskritText = (form.querySelector("#mantra-sanskrit") as HTMLTextAreaElement).value.trim();
      const transliteration = (form.querySelector("#mantra-transliteration") as HTMLTextAreaElement).value.trim();
      const meaning = (form.querySelector("#mantra-meaning") as HTMLTextAreaElement).value.trim();
      const pronunciationGuidance = (form.querySelector("#mantra-guidance") as HTMLTextAreaElement).value.trim();
      const minDurationSeconds = parseInt((form.querySelector("#mantra-min-sec") as HTMLInputElement).value, 10) || 10;
      const maxDurationSeconds = parseInt((form.querySelector("#mantra-max-sec") as HTMLInputElement).value, 10) || 120;
      const displayOrder = parseInt((form.querySelector("#mantra-order") as HTMLInputElement).value, 10) || 0;
      const isActive = (form.querySelector("#mantra-active") as HTMLInputElement).checked;

      try {
        if (isEdit) {
          await adminApi.updateAdminMantra(existing!.id, {
            title,
            sanskritText,
            transliteration,
            meaning,
            pronunciationGuidance,
            minDurationSeconds,
            maxDurationSeconds,
            displayOrder,
            isActive,
          });
        } else {
          const id = (form.querySelector("#mantra-id") as HTMLInputElement).value.trim().toUpperCase().replace(/[^A-Z0-9_]/g, "_");
          await adminApi.createAdminMantra({
            id,
            title,
            sanskritText,
            transliteration,
            meaning,
            pronunciationGuidance,
            minDurationSeconds,
            maxDurationSeconds,
            displayOrder,
            isActive,
          });
        }

        closeForm();
        await loadMantrasList();
      } catch (err: any) {
        alert(`Failed to save mantra: ${err.message}`);
        submitBtn.disabled = false;
        submitBtn.textContent = "Save Mantra";
      }
    });
  }

  manageMantrasBtn.addEventListener("click", openManageMantrasModal);

  async function openDetailModal(initialPandit: PanditApplication) {
    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog" style="max-width: 680px; max-height: 90vh; overflow-y: auto;">
          <div class="modal-header">
            <h3 class="modal-title">Pandit Application Dossier</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div class="state-box" id="dossier-loading">
            <div class="spinner"></div>
            <p>Loading latest dossier data...</p>
          </div>
          <div id="dossier-content" style="display: none;"></div>
        </div>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    try {
      const pandit = await adminApi.getPanditDetail(initialPandit.id);
      renderDossierContent(pandit);
    } catch {
      renderDossierContent(initialPandit);
    }
  }

  function renderDossierContent(pandit: PanditApplication) {
    const loadingEl = modalContainer.querySelector("#dossier-loading") as HTMLElement;
    const contentEl = modalContainer.querySelector("#dossier-content") as HTMLElement;
    if (loadingEl) loadingEl.style.display = "none";
    if (!contentEl) return;
    contentEl.style.display = "block";

    const mantraRecs = pandit.mantraRecordings || [];

    contentEl.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 14px; text-align: left;">
        <!-- Header Info -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 1px solid var(--border-color); padding-bottom: 12px;">
          <div>
            <h3 style="margin: 0; font-size: 18px;">${pandit.user.name}</h3>
            <p style="margin: 2px 0 0; color: var(--text-muted); font-size: 13px;">${pandit.user.phone} • ${pandit.user.email || "No email"}</p>
            <p style="margin: 2px 0 0; color: var(--text-muted); font-size: 12px;">Location: ${pandit.city || pandit.user.city || "Not specified"}</p>
          </div>
          <div style="text-align: right;">
            <span class="badge ${pandit.verificationStatus === "APPROVED" ? "badge-success" : pandit.verificationStatus === "REJECTED" ? "badge-danger" : "badge-warning"}">
              ${pandit.verificationStatus}
            </span>
            <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">
              Stage: ${pandit.verificationStage || "STAGE_1_COMPLETE"}
            </div>
          </div>
        </div>

        <!-- Professional Profile -->
        <div style="background: var(--bg-card); padding: 12px; border-radius: 6px; border: 1px solid var(--border-color);">
          <h4 style="margin: 0 0 6px; font-size: 14px;">Vedic Qualifications</h4>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size: 13px;">
            <div><strong>Experience:</strong> ${pandit.experienceYears || 0} years</div>
            <div><strong>Specialization:</strong> ${pandit.vedicSpecialization || "General Vedic"}</div>
            <div><strong>Languages:</strong> ${pandit.languages?.join(", ") || "Hindi, Sanskrit"}</div>
            <div><strong>Verification Method:</strong> <span class="badge badge-primary">🎥 Mantra Video</span></div>
          </div>
          <p style="margin: 8px 0 0; color: var(--text-muted); font-size: 13px;">${pandit.bio || "No bio provided"}</p>
        </div>

        <!-- Mantra Video Recitation Verification Section -->
        <div style="margin-top: 4px; padding: 14px; background: rgba(255, 145, 0, 0.05); border: 1px solid rgba(255, 145, 0, 0.2); border-radius: 8px;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <h4 style="margin: 0; font-size: 14px; color: var(--primary);">
              🎥 Mantra Video Recitation Verification (${mantraRecs.length})
            </h4>
            <span class="badge ${pandit.mantraRecordingStatus === "APPROVED" ? "badge-success" : pandit.mantraRecordingStatus === "REJECTED" ? "badge-danger" : pandit.mantraRecordingStatus === "RESUBMISSION_REQUIRED" ? "badge-warning" : "badge-secondary"}">
              Status: ${pandit.mantraRecordingStatus || "NOT_SUBMITTED"}
            </span>
          </div>

          ${
            mantraRecs.length === 0
              ? `<p style="font-size: 13px; color: var(--text-muted); margin: 6px 0;">No mantra video recording submissions found for this Pandit.</p>`
              : mantraRecs
                  .map(
                    (rec) => `
              <div style="background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 6px; padding: 12px; margin-top: 10px;">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;">
                  <div>
                    <div style="font-weight: 600; font-size: 14px;">${rec.mantraTitle}</div>
                    <div style="font-size: 11px; color: var(--text-muted);">
                      Submitted: ${new Date(rec.createdAt).toLocaleString()} • Duration: ${rec.durationSeconds ? `${rec.durationSeconds}s` : "Unknown"} • File: ${rec.fileName || "recitation.mp4"} (${Math.round((rec.fileSize || 0) / 1024)} KB)
                    </div>
                  </div>
                  <span class="badge ${rec.status === "APPROVED" ? "badge-success" : rec.status === "REJECTED" ? "badge-danger" : rec.status === "RESUBMISSION_REQUIRED" ? "badge-warning" : "badge-secondary"}">
                    ${rec.status}
                  </span>
                </div>

                <div style="margin: 8px 0;">
                  <video controls playsinline preload="metadata" style="width: 100%; max-height: 280px; border-radius: 6px; background: #000;" src="${adminApi.getMantraRecordingStreamUrl(pandit.id, rec.id)}">
                    <audio controls src="${adminApi.getMantraRecordingStreamUrl(pandit.id, rec.id)}">
                      Your browser does not support media playback.
                    </audio>
                  </video>
                </div>

                ${
                  rec.reviewerNotes
                    ? `<div style="font-size: 12px; margin-top: 4px; color: var(--text-muted);"><strong>Reviewer Notes:</strong> ${rec.reviewerNotes}</div>`
                    : ""
                }
                ${
                  rec.rejectionReason
                    ? `<div style="font-size: 12px; margin-top: 4px; color: var(--status-danger);"><strong>Feedback / Reason:</strong> ${rec.rejectionReason}</div>`
                    : ""
                }

                <div style="display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap;">
                  <button class="btn btn-sm btn-success review-mantra-btn" data-recording-id="${rec.id}" data-action="APPROVED">
                    ✓ Approve Recitation
                  </button>
                  <button class="btn btn-sm btn-warning review-mantra-btn" data-recording-id="${rec.id}" data-action="RESUBMISSION_REQUIRED">
                    ↺ Request Resubmission
                  </button>
                  <button class="btn btn-sm btn-danger review-mantra-btn" data-recording-id="${rec.id}" data-action="REJECTED">
                    ✕ Reject Recitation
                  </button>
                </div>
              </div>
            `
                  )
                  .join("")
          }
        </div>

        <!-- Uploaded Documents Section -->
        <div style="margin-top: 6px;">
          <h4 style="margin: 0 0 6px; font-size: 14px;">Uploaded KYC Documents (${pandit.documents?.length || 0})</h4>
          ${
            pandit.documents && pandit.documents.length > 0
              ? `<ul style="margin: 0; padding-left: 20px; font-size: 13px;">
                  ${pandit.documents
                    .map(
                      (d) =>
                        `<li style="margin-bottom: 6px;">
                          <strong>${d.docType || d.documentType}:</strong> <span class="badge ${(d.status || d.verificationStatus) === "VERIFIED" ? "badge-success" : (d.status || d.verificationStatus) === "REJECTED" ? "badge-danger" : "badge-warning"}">${d.status || d.verificationStatus}</span>
                          ${d.documentUrl ? `<a href="${d.documentUrl}" target="_blank" style="color: var(--primary-light); margin-left: 8px;">View Document ↗</a>` : ""}
                        </li>`
                    )
                    .join("")}
                </ul>`
              : "<p style='color: var(--text-muted); font-size: 13px; margin: 4px 0;'>No documents uploaded yet.</p>"
          }
        </div>
      </div>

      <div class="modal-actions" style="margin-top: 20px;">
        <button class="btn btn-secondary modal-close-btn">Close Dossier</button>
      </div>
    `;

    modalContainer.querySelectorAll(".modal-close-btn").forEach((el) => {
      el.addEventListener("click", () => {
        modalContainer.innerHTML = "";
      });
    });

    contentEl.querySelectorAll(".review-mantra-btn").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const recordingId = btn.getAttribute("data-recording-id")!;
        const action = btn.getAttribute("data-action") as "APPROVED" | "REJECTED" | "RESUBMISSION_REQUIRED";

        let notes: string | undefined;
        let rejectionReason: string | undefined;

        if (action === "RESUBMISSION_REQUIRED") {
          const feedback = prompt("Enter pronunciation guidance or instructions for what needs to be corrected in the replacement video:");
          if (!feedback || !feedback.trim()) {
            return;
          }
          notes = feedback.trim();
          rejectionReason = feedback.trim();
        } else if (action === "REJECTED") {
          const reason = prompt("Enter the reason for rejecting this recitation:");
          if (!reason || !reason.trim()) {
            return;
          }
          rejectionReason = reason.trim();
          notes = reason.trim();
        } else {
          const ok = confirm("Are you sure you want to approve this Vedic mantra video recitation?");
          if (!ok) return;
        }

        const buttonEl = btn as HTMLButtonElement;
        buttonEl.disabled = true;
        buttonEl.textContent = "Updating...";

        try {
          await adminApi.reviewMantraRecording(pandit.id, recordingId, action, notes, rejectionReason);
          alert(`Mantra video submission ${action.toLowerCase().replace('_', ' ')} successfully.`);
          const fresh = await adminApi.getPanditDetail(pandit.id);
          renderDossierContent(fresh);
          loadPandits();
        } catch (err: any) {
          alert(`Failed to update mantra review: ${err.message}`);
          buttonEl.disabled = false;
          buttonEl.textContent = action === "APPROVED" ? "✓ Approve Recitation" : action === "RESUBMISSION_REQUIRED" ? "↺ Request Resubmission" : "✕ Reject Recitation";
        }
      });
    });
  }

  function openApprovalModal(pandit: PanditApplication, action: "APPROVED" | "REJECTED") {
    const isMantraApproved = pandit.mantraRecordingStatus === "APPROVED";

    modalContainer.innerHTML = `
      <div class="modal-backdrop">
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">${action === "APPROVED" ? "Authorize Pandit Profile" : "Reject Pandit Application"}</h3>
            <button class="modal-close">&times;</button>
          </div>
          <div style="text-align: left;">
            <p style="margin-bottom: 12px;">Applicant: <strong>${pandit.user.name}</strong> (${pandit.user.phone})</p>
            
            ${
              action === "APPROVED" && !isMantraApproved
                ? `<div style="background: rgba(220, 53, 69, 0.1); border: 1px solid var(--status-danger); border-radius: 6px; padding: 10px; margin-bottom: 12px; font-size: 13px; color: var(--status-danger);">
                    ⚠️ <strong>Mantra Video Verification Pending</strong>: This applicant's mantra recitation video is currently <strong>${pandit.mantraRecordingStatus || "NOT SUBMITTED"}</strong>. In accordance with SARV MANGAL Vedic onboarding standards, administrators must review and approve their recitation video in the dossier before final authorization.
                   </div>`
                : ""
            }

            ${
              action === "REJECTED"
                ? `<div class="form-group">
                    <label class="form-label" for="rejection-reason">REJECTION REASON (REQUIRED)</label>
                    <textarea id="rejection-reason" class="form-textarea" rows="3" placeholder="Specify missing certification or document mismatch..."></textarea>
                   </div>`
                : `<p style="color: var(--text-muted); font-size: 13px;">Approving this applicant will enable their profile for duty dispatch, booking requests, and Dakshina settlements across SARV MANGAL.</p>`
            }
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary modal-close-btn">Cancel</button>
            <button id="confirm-decision-btn" class="btn ${action === "APPROVED" ? "btn-success" : "btn-danger"}" ${action === "APPROVED" && !isMantraApproved ? "disabled title='Mantra video must be approved first'" : ""}>
              Confirm ${action === "APPROVED" ? "Approval" : "Rejection"}
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
      if (action === "REJECTED") {
        const input = modalContainer.querySelector("#rejection-reason") as HTMLTextAreaElement;
        reason = input.value.trim();
        if (!reason) {
          alert("Please provide a rejection reason.");
          return;
        }
      }

      confirmBtn.disabled = true;
      confirmBtn.textContent = "Updating...";

      try {
        await adminApi.approvePandit(pandit.id, action, reason);
        modalContainer.innerHTML = "";
        loadPandits();
      } catch (err: any) {
        alert(`Failed to update status: ${err.message}`);
        confirmBtn.disabled = false;
        confirmBtn.textContent = `Confirm ${action === "APPROVED" ? "Approval" : "Rejection"}`;
      }
    });
  }

  refreshBtn.addEventListener("click", loadPandits);
  loadPandits();
}

function renderTable(
  container: HTMLElement,
  pandits: PanditApplication[],
  onDetail: (p: PanditApplication) => void,
  onDecision: (p: PanditApplication, action: "APPROVED" | "REJECTED") => void
): void {
  if (pandits.length === 0) {
    container.innerHTML = `
      <div class="state-box">
        <p>No Pandit applications found in this queue.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="table-responsive">
      <table class="data-table">
        <thead>
          <tr>
            <th>Applicant Name</th>
            <th>Phone / Contact</th>
            <th>Location</th>
            <th>Verification Method</th>
            <th>Mantra Video Status</th>
            <th>Overall Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${pandits
            .map(
              (p) => `
            <tr>
              <td>
                <div style="font-weight: 600;">${p.user.name}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${p.user.email || "No email"} • ${p.experienceYears || 0} yrs exp</div>
              </td>
              <td>${p.user.phone}</td>
              <td>${p.city || p.user.city || "—"}</td>
              <td>
                <span class="badge badge-primary">
                  🎥 Mantra Video
                </span>
              </td>
              <td>
                <span class="badge ${p.mantraRecordingStatus === "APPROVED" ? "badge-success" : p.mantraRecordingStatus === "REJECTED" ? "badge-danger" : p.mantraRecordingStatus === "RESUBMISSION_REQUIRED" ? "badge-warning" : "badge-secondary"}">
                  ${p.mantraRecordingStatus || "NOT_SUBMITTED"}
                </span>
              </td>
              <td>
                <span class="badge ${p.verificationStatus === "APPROVED" ? "badge-success" : p.verificationStatus === "REJECTED" ? "badge-danger" : "badge-warning"}">
                  ${p.verificationStatus}
                </span>
              </td>
              <td>
                <div style="display: flex; gap: 8px;">
                  <button class="btn btn-secondary btn-sm view-dossier-btn" data-id="${p.id}">Dossier</button>
                  ${
                    p.verificationStatus !== "APPROVED"
                      ? `<button class="btn btn-success btn-sm approve-btn" data-id="${p.id}">Approve</button>`
                      : ""
                  }
                  ${
                    p.verificationStatus !== "REJECTED"
                      ? `<button class="btn btn-danger btn-sm reject-btn" data-id="${p.id}">Reject</button>`
                      : ""
                  }
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

  container.querySelectorAll(".view-dossier-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const pandit = pandits.find((p) => p.id === id);
      if (pandit) onDetail(pandit);
    });
  });

  container.querySelectorAll(".approve-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const pandit = pandits.find((p) => p.id === id);
      if (pandit) onDecision(pandit, "APPROVED");
    });
  });

  container.querySelectorAll(".reject-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      const pandit = pandits.find((p) => p.id === id);
      if (pandit) onDecision(pandit, "REJECTED");
    });
  });
}
