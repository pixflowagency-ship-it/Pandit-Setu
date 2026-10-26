export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: "ADMIN";
  phone: string;
}

export interface AdminStats {
  pandits: {
    pending: number;
    approved: number;
    rejected: number;
    total: number;
  };
  bookings: {
    total: number;
    completed: number;
    pending: number;
  };
  subscriptions: {
    total: number;
    active: number;
  };
  productOrders: {
    total: number;
  };
  consultations: {
    total: number;
    pending: number;
    persistentRecords: boolean;
  };
  kundliOrders: {
    total: number;
    pending: number;
    persistentRecords: boolean;
  };
}

export interface PanditDocument {
  id: string;
  docType?: string;
  documentType?: string;
  verificationStatus?: "PENDING" | "VERIFIED" | "REJECTED";
  status?: "PENDING" | "VERIFIED" | "REJECTED";
  documentUrl?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  rejectionReason?: string;
  createdAt: string;
}

export interface MantraRecording {
  id: string;
  mantraId: string;
  mantraTitle: string;
  durationSeconds?: number;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  status: "PENDING" | "APPROVED" | "REJECTED" | "RESUBMISSION_REQUIRED";
  rejectionReason?: string;
  reviewerNotes?: string;
  reviewedAt?: string;
  createdAt: string;
}

export interface ApprovedMantra {
  id: string;
  title: string;
  sanskritText: string;
  transliteration?: string;
  meaning?: string;
  pronunciationGuidance?: string;
  minDurationSeconds: number;
  maxDurationSeconds: number;
  isActive: boolean;
  displayOrder: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface PanditApplication {
  id: string;
  userId: string;
  verificationStatus: "PENDING" | "APPROVED" | "REJECTED";
  verificationMethod?: "MANTRA_VIDEO" | "MANTRA_RECORDING" | "VIDEO_CALL";
  verificationStage?: string;
  mantraRecordingStatus?: "NOT_SUBMITTED" | "PENDING" | "APPROVED" | "REJECTED" | "RESUBMISSION_REQUIRED";
  isVerified: boolean;
  experienceYears?: number;
  vedicSpecialization?: string;
  city?: string;
  bio?: string;
  specializations?: string[];
  languages?: string[];
  videoVerificationStatus?: string;
  videoCallStatus?: string;
  videoScheduledAt?: string;
  rejectionReason?: string;
  createdAt: string;
  user: {
    id: string;
    name: string;
    phone: string;
    email?: string;
    city?: string;
  };
  documents?: PanditDocument[];
  mantraRecordings?: MantraRecording[];
}

export interface ConsultationRecord {
  id: string;
  consultationNumber: string;
  status: "REQUESTED" | "SCHEDULED" | "IN_PROGRESS" | "COMPLETED" | "CANCELLED";
  preferredDate: string;
  preferredTime: string;
  topic: string;
  assignedPanditId?: string;
  meetingLink?: string;
  createdAt: string;
  userName?: string;
  userPhone?: string;
}

export interface KundliOrderRecord {
  id: string;
  orderNumber: string;
  status: "PAYMENT_CONFIRMED" | "PROCESSING" | "PREPARING" | "DISPATCHED" | "DELIVERED" | "CANCELLED";
  devoteeName: string;
  dob: string;
  tob: string;
  pob: string;
  gotra: string;
  language: string;
  assignedPanditId?: string;
  createdAt: string;
  userPhone?: string;
}

export interface SubscriptionRecord {
  id: string;
  userId: string;
  planId: string;
  status: "ACTIVE" | "PENDING" | "HALTED" | "CANCELLED" | "COMPLETED";
  amount: number;
  createdAt: string;
  userName?: string;
  userPhone?: string;
}
