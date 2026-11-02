export type Role = "CUSTOMER" | "WORKER" | "ADMIN" | "SUPER_ADMIN";
export type AccountStatus = "ACTIVE" | "DISABLED";
export type VerificationStatus =
  | "PENDING"
  | "REGISTERED"
  | "COMMUNITY_VERIFIED_PROBATION"
  | "COMMUNITY_VERIFIED"
  | "TRUSTED_WORKER"
  | "UNDER_REVIEW"
  | "SUSPENDED"
  | "REVOKED"
  | "APPROVED"
  | "REJECTED";

export type BadgeState = "ACTIVE" | "UNDER_REVIEW" | "SUSPENDED" | "REVOKED";
export type BadgeType = "IDENTITY_VERIFIED" | "COMMUNITY_VERIFIED" | "CERTIFICATE_VERIFIED" | "TRUSTED_WORKER";
export type SkillRiskTier = "LOW" | "MEDIUM" | "HIGH";
export type EvidenceType = "IDENTITY" | "PREVIOUS_WORK" | "PREVIOUS_CUSTOMER" | "PREVIOUS_EMPLOYER" | "PRACTICAL_CHECK" | "OTHER";
export type EvidenceStatus = "PENDING" | "PASSED" | "FAILED" | "VERIFIED";

export type WorkerReference = {
  id: string;
  workerId: string;
  name: string;
  phone: string;
  relationship: string;
  yearsKnown?: string | null;
  workObserved?: string | null;
  verified: boolean;
  verifiedAt?: string | null;
  answers?: Record<string, unknown> | null;
  createdAt?: string;
};

export type VerificationEvidence = {
  id: string;
  workerId: string;
  evidenceType: EvidenceType;
  title?: string | null;
  description?: string | null;
  fileUrl?: string | null;
  status: EvidenceStatus;
  reviewedBy?: string | null;
  reviewedAt?: string | null;
  adminNote?: string | null;
  createdAt: string;
};

export type WorkerBadge = {
  id: string;
  badgeType: BadgeType;
  badgeState: BadgeState;
  issuedAt: string;
  revokedAt?: string | null;
  adminNote?: string | null;
};

export type DetailedSkill = {
  categoryId: string;
  name: string;
  riskTier?: SkillRiskTier;
  practicalCheckPassed?: boolean;
  yearsOfExperience?: number;
};

export type PlatformProbationConfig = {
  probationJobCountRequired: number;
  probationMinRating: number;
  probationJobValueCap: number;
  probationMaxConcurrentJobs: number;
};

export type CertificationStatus = "PENDING" | "APPROVED" | "REJECTED";
export type PricingType = "FIXED" | "HOURLY";
export type BookingStatus =
  | "PENDING_MATCH"
  | "BROADCASTING"
  | "ACCEPTED"
  | "EN_ROUTE"
  | "ARRIVED"
  | "IN_PROGRESS"
  | "AWAITING_PAYMENT"
  | "COMPLETED"
  | "CANCELLED"
  | "DISPUTED";
export type IssueStatus = "OPEN" | "IN_REVIEW" | "RESOLVED" | "CLOSED";
export type WelfareClaimStatus = "SUBMITTED" | "UNDER_REVIEW" | "APPROVED" | "REJECTED" | "PAID";
export type SupportConversationStatus = "AI_HANDLING" | "ESCALATED" | "RESOLVED";
export type SupportSender = "USER" | "AI" | "AGENT";
export type AnnouncementAudience = "workers" | "customers" | "all";

export type SessionUser = {
  id: string;
  phone: string;
  role: Role;
  status?: AccountStatus;
  customerProfile?: { name?: string | null } | null;
  workerProfile?: { name?: string | null } | null;
};

export type AuthSession = {
  accessToken: string;
  refreshToken: string;
  expiresIn?: string;
  user: SessionUser;
};

export type Page<T> = {
  items: T[];
  page: number;
  limit: number;
  total: number;
};

export type AdminStats = {
  totalUsers: number;
  totalCustomers: number;
  totalWorkers: number;
  pendingVerifications: number;
  activeBookings: number;
  completedBookings: number;
  openDisputes: number;
  openClaims: number;
  escalatedSupport: number;
  revenue: number;
};

export type RevenuePoint = { date: string; revenue: number };
export type BookingPoint = { date: string; count: number };
export type DemandPoint = { categoryId?: string; category: string; count: number };

export type LiveMapMarker = {
  id: string;
  bookingId: string;
  lat: number;
  lng: number;
  status: BookingStatus;
  workerName: string;
  customerName: string;
  category: string;
  city?: string;
  updatedAt?: string;
};

export type Society = {
  id: string;
  name: string;
  federationId: string;
  federation?: Federation;
};

export type Federation = {
  id: string;
  name: string;
  region: string;
  societies?: Society[];
};

export type Certification = {
  id: string;
  docUrl: string;
  status: CertificationStatus;
  adminNote?: string | null;
  createdAt: string;
};

export type WorkerRow = {
  id: string;
  userId: string;
  name: string;
  phone: string;
  email?: string | null;
  skills: string[];
  skillIds?: string[];
  skillsDetailed?: DetailedSkill[];
  verificationStatus: VerificationStatus;
  badgeState?: BadgeState;
  verificationNote?: string | null;
  probationJobCount?: number;
  probationStartDate?: string | null;
  society: Society;
  societyId: string;
  rating: number;
  ratingAverage?: number;
  reviewCount?: number;
  status: AccountStatus;
  isOnline?: boolean;
  certifications?: Certification[];
  badges?: WorkerBadge[];
  evidences?: VerificationEvidence[];
  references?: WorkerReference[];
  jobEligible?: boolean;
  isProbation?: boolean;
  isTrusted?: boolean;
  isCertificateVerified?: boolean;
};

export type ServiceRow = {
  id: string;
  name: string;
  slug: string;
  basePricing: number | string;
  pricingType: PricingType;
  icon?: string | null;
  disabled?: boolean;
  commissionRate?: number | string;
  parentId?: string | null;
  children?: ServiceRow[];
};

export type UserRow = {
  id: string;
  name: string;
  phone: string;
  role: Role;
  status: AccountStatus;
  joinDate: string;
  createdAt?: string;
};

export type BookingRow = {
  id: string;
  status: BookingStatus;
  createdAt: string;
  scheduledAt?: string | null;
  isEmergency?: boolean;
  cancelReason?: string | null;
  serviceCategory?: { id: string; name: string };
  address?: {
    line1?: string;
    city?: string;
    state?: string;
    pincode?: string;
    lat?: number | null;
    lng?: number | null;
  };
  payment?: { amount: number | string; status: string } | null;
  customer?: {
    id: string;
    phone: string;
    customerProfile?: { name?: string | null } | null;
  };
  worker?: {
    id: string;
    phone: string;
    workerProfile?: { name?: string | null; ratingAverage?: number } | null;
  } | null;
  issues?: DisputeRow[];
  reviews?: Array<{ rating: number; comment?: string | null; direction: string }>;
};

export type DisputeRow = {
  id: string;
  bookingId: string;
  category: string;
  description: string;
  status: IssueStatus;
  adminNote?: string | null;
  resolvedAt?: string | null;
  createdAt: string;
  booking?: {
    id?: string;
    serviceCategory?: { name: string };
    customer?: { phone: string; customerProfile?: { name?: string | null } | null };
    worker?: { phone: string; workerProfile?: { name?: string | null } | null } | null;
  };
  reporter?: { id: string; phone: string; role: Role; customerProfile?: { name?: string | null } | null };
};

export type WelfareClaimRow = {
  id: string;
  category: string;
  description: string;
  status: WelfareClaimStatus;
  adminNote?: string | null;
  createdAt: string;
  welfare?: {
    worker?: {
      name: string;
      user?: { phone: string };
    };
  };
};

export type SupportMessage = {
  id: string;
  conversationId?: string;
  sender: SupportSender;
  content: string;
  createdAt: string;
};

export type SupportConversation = {
  id: string;
  userId: string;
  status: SupportConversationStatus;
  assignedAgentId?: string | null;
  createdAt: string;
  updatedAt: string;
  user?: {
    id: string;
    phone: string;
    role: Role;
    customerProfile?: { name?: string | null } | null;
    workerProfile?: { name?: string | null } | null;
  };
  messages?: SupportMessage[];
};

export type AnnouncementRow = {
  id: string;
  audience: string;
  title: string;
  message: string;
  createdBy: string;
  createdAt: string;
};
