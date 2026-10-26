import { getToken, clearSession } from "./auth.ts";
import type {
  AdminUser,
  AdminStats,
  PanditApplication,
  ConsultationRecord,
  KundliOrderRecord,
  SubscriptionRecord,
  ApprovedMantra,
} from "./types.ts";

export const API_BASE = (import.meta as any).env?.VITE_API_URL || "http://localhost:5000/api/v1";

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  if (response.status === 401 || response.status === 403) {
    if (!endpoint.includes("/admin/auth/login")) {
      clearSession();
      window.dispatchEvent(new CustomEvent("sarv_auth_state_changed"));
    }
  }

  const payload: ApiResponse<T> = await response.json();

  if (!response.ok || !payload.success) {
    const errorMsg = payload.error?.message || `HTTP ${response.status} Server Error`;
    throw new Error(errorMsg);
  }

  return payload.data as T;
}

export const adminApi = {
  // Authentication
  async login(email: string, password: string): Promise<{ token: string; user: AdminUser }> {
    return request<{ token: string; user: AdminUser }>("/admin/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
  },

  async logout(): Promise<void> {
    try {
      await request<void>("/admin/auth/logout", { method: "POST" });
    } catch {
      // Ignore network errors or expired token during logout
    }
  },

  async getMe(): Promise<{ user: AdminUser }> {
    return request<{ user: AdminUser }>("/admin/auth/me");
  },

  async getHealth(): Promise<{ status: string }> {
    return request<{ status: string }>("/admin/health");
  },

  // Overview Stats
  async getStats(): Promise<AdminStats> {
    return request<AdminStats>("/admin/stats");
  },

  // Pandit Verification Desk
  async getPandits(status: string = "ALL", page: number = 1, limit: number = 50): Promise<{ pandits: PanditApplication[]; total: number }> {
    return request<{ pandits: PanditApplication[]; total: number }>(`/admin/pandits?status=${status}&page=${page}&limit=${limit}`);
  },

  async getPanditDetail(panditId: string): Promise<PanditApplication> {
    return request<PanditApplication>(`/admin/pandits/${panditId}`);
  },

  async approvePandit(panditId: string, status: "APPROVED" | "REJECTED", rejectionReason?: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/pandits/${panditId}/approval`, {
      method: "PATCH",
      body: JSON.stringify({ status, rejectionReason }),
    });
  },

  async verifyDocument(documentId: string, status: "VERIFIED" | "REJECTED", rejectionReason?: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/documents/${documentId}/verify`, {
      method: "PATCH",
      body: JSON.stringify({ status, rejectionReason }),
    });
  },

  async verifyVideo(panditId: string, status: "VERIFIED" | "REJECTED", notes?: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/pandits/${panditId}/video-verify`, {
      method: "PATCH",
      body: JSON.stringify({ status, notes }),
    });
  },

  async reviewMantraRecording(
    panditId: string,
    recordingId: string,
    status: "APPROVED" | "REJECTED" | "RESUBMISSION_REQUIRED",
    notes?: string,
    rejectionReason?: string
  ): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(
      `/admin/pandits/${panditId}/mantra-recordings/${recordingId}/review`,
      {
        method: "PATCH",
        body: JSON.stringify({ status, notes, rejectionReason }),
      }
    );
  },

  getMantraRecordingStreamUrl(panditId: string, recordingId: string): string {
    const token = getToken();
    return `${API_BASE}/admin/pandits/${panditId}/mantra-recordings/${recordingId}/stream${
      token ? `?token=${encodeURIComponent(token)}` : ""
    }`;
  },

  // Approved Mantras Desk
  async getAdminMantras(): Promise<ApprovedMantra[]> {
    return request<ApprovedMantra[]>("/admin/mantras");
  },

  async createAdminMantra(data: Partial<ApprovedMantra>): Promise<ApprovedMantra> {
    return request<ApprovedMantra>("/admin/mantras", {
      method: "POST",
      body: JSON.stringify(data),
    });
  },

  async updateAdminMantra(id: string, data: Partial<ApprovedMantra>): Promise<ApprovedMantra> {
    return request<ApprovedMantra>(`/admin/mantras/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  },

  async deleteAdminMantra(id: string): Promise<void> {
    await request<void>(`/admin/mantras/${id}`, {
      method: "DELETE",
    });
  },

  // Consultations Desk
  async getConsultations(page: number = 1, limit: number = 50): Promise<{ consultations: ConsultationRecord[]; total: number }> {
    return request<{ consultations: ConsultationRecord[]; total: number }>(`/admin/consultations?page=${page}&limit=${limit}`);
  },

  async scheduleConsultation(id: string, scheduledAt: string, meetingLink: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/consultations/${id}/schedule`, {
      method: "PATCH",
      body: JSON.stringify({ scheduledAt, meetingLink }),
    });
  },

  async assignConsultation(id: string, panditId: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/consultations/${id}/assignment`, {
      method: "PATCH",
      body: JSON.stringify({ panditId }),
    });
  },

  async updateConsultationStatus(id: string, status: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/consultations/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    });
  },

  // Kundli Orders Desk
  async getKundliOrders(page: number = 1, limit: number = 50): Promise<{ orders: KundliOrderRecord[]; total: number }> {
    return request<{ orders: KundliOrderRecord[]; total: number }>(`/admin/kundli-orders?page=${page}&limit=${limit}`);
  },

  async decisionKundliOrder(id: string, decision: "ACCEPT" | "REJECT", rejectionReason?: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/kundli-orders/${id}/decision`, {
      method: "PATCH",
      body: JSON.stringify({ decision, rejectionReason }),
    });
  },

  async assignKundliOrder(id: string, panditId: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/kundli-orders/${id}/assignment`, {
      method: "PATCH",
      body: JSON.stringify({ panditId }),
    });
  },

  async updateKundliStatus(id: string, status: string, trackingNumber?: string, courierPartner?: string): Promise<{ success: boolean }> {
    return request<{ success: boolean }>(`/admin/kundli-orders/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status, trackingNumber, courierPartner }),
    });
  },

  // Subscriptions Oversight
  async getSubscriptions(status: string = "ALL", page: number = 1, limit: number = 50): Promise<{ subscriptions: SubscriptionRecord[]; total: number }> {
    return request<{ subscriptions: SubscriptionRecord[]; total: number }>(`/admin/subscriptions?status=${status}&page=${page}&limit=${limit}`);
  },
};
