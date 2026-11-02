import { prettyStatus } from "../lib/format";

const TONES: Record<string, string> = {
  ACTIVE: "bg-accent-soft text-teal-dark",
  APPROVED: "bg-accent-soft text-teal-dark",
  COMMUNITY_VERIFIED: "bg-teal-50 text-teal font-medium border border-teal/20",
  TRUSTED_WORKER: "bg-purple-50 text-purple-700 font-bold border border-purple-200",
  COMMUNITY_VERIFIED_PROBATION: "bg-amber-50 text-amber-800 font-medium border border-amber-300",
  REGISTERED: "bg-sky-50 text-sky-700 border border-sky-200",
  SUSPENDED: "bg-red-50 text-red-700 border border-red-200 font-semibold",
  REVOKED: "bg-zinc-100 text-zinc-600 border border-zinc-300 line-through",
  PASSED: "bg-accent-soft text-teal-dark font-medium",
  VERIFIED: "bg-accent-soft text-teal-dark font-medium",
  FAILED: "bg-danger-soft text-danger font-medium",
  PAID: "bg-accent-soft text-teal-dark",
  COMPLETED: "bg-accent-soft text-teal-dark",
  RESOLVED: "bg-accent-soft text-teal-dark",
  CLOSED: "bg-accent-soft text-teal-dark",
  PENDING: "bg-warning-soft text-warning",
  PENDING_MATCH: "bg-warning-soft text-warning",
  BROADCASTING: "bg-warning-soft text-warning",
  SUBMITTED: "bg-warning-soft text-warning",
  UNDER_REVIEW: "bg-amber-100 text-amber-900 border border-amber-300",
  IN_REVIEW: "bg-warning-soft text-warning",
  ACCEPTED: "bg-accent text-teal-dark",
  EN_ROUTE: "bg-accent text-teal-dark",
  ARRIVED: "bg-accent text-teal-dark",
  IN_PROGRESS: "bg-accent text-teal-dark",
  AWAITING_PAYMENT: "bg-warning-soft text-warning",
  AI_HANDLING: "bg-field text-muted",
  ESCALATED: "bg-warning-soft text-warning",
  DISABLED: "bg-danger-soft text-danger",
  REJECTED: "bg-danger-soft text-danger",
  CANCELLED: "bg-danger-soft text-danger",
  DISPUTED: "bg-danger-soft text-danger",
  OPEN: "bg-danger-soft text-danger",
  SUPER_ADMIN: "bg-teal text-white",
  ADMIN: "bg-teal text-white",
  HIGH: "bg-red-50 text-red-700 border border-red-200 font-bold",
  MEDIUM: "bg-amber-50 text-amber-700 border border-amber-200",
  LOW: "bg-emerald-50 text-emerald-700 border border-emerald-200",
};

export function StatusBadge({ value }: { value?: string | null }) {
  if (!value) return <span className="text-muted">—</span>;
  return (
    <span
      className={`inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold tracking-wide ${TONES[value] ?? "bg-field text-muted"}`}
    >
      {prettyStatus(value)}
    </span>
  );
}
