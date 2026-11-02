import { CheckCircle2, ExternalLink, Filter, Pencil, ShieldAlert, ShieldCheck } from "lucide-react";
import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { Modal } from "../components/Modal";
import { PageHeader } from "../components/PageHeader";
import { StatusBadge } from "../components/StatusBadge";
import { api, getAccessToken, unwrapList, unwrapPage } from "../lib/api";
import { formatPhone } from "../lib/format";
import type {
  Certification,
  EvidenceStatus,
  Federation,
  ServiceRow,
  Society,
  WorkerRow,
} from "../types";

function flattenServices(rows: ServiceRow[]): ServiceRow[] {
  return rows.flatMap((row) => [row, ...(row.children ?? [])]);
}

function selectedSkillIds(worker: WorkerRow, categories: ServiceRow[]): string[] {
  if (worker.skillIds?.length) return worker.skillIds;
  const names = new Set((worker.skills ?? []).map((name) => name.toLowerCase()));
  return categories.filter((category) => names.has(category.name.toLowerCase())).map((category) => category.id);
}

const STATUS_FILTERS = [
  { label: "All Workers", value: "ALL" },
  { label: "Registered", value: "REGISTERED" },
  { label: "Under Review", value: "UNDER_REVIEW" },
  { label: "Probation", value: "COMMUNITY_VERIFIED_PROBATION" },
  { label: "Community Verified", value: "COMMUNITY_VERIFIED" },
  { label: "Trusted Worker", value: "TRUSTED_WORKER" },
  { label: "Suspended", value: "SUSPENDED" },
];

export function WorkersPage() {
  const [workers, setWorkers] = useState<WorkerRow[]>([]);
  const [societies, setSocieties] = useState<Society[]>([]);
  const [categories, setCategories] = useState<ServiceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [active, setActive] = useState<WorkerRow | null>(null);
  const [skillsFor, setSkillsFor] = useState<WorkerRow | null>(null);
  const [checkedSkills, setCheckedSkills] = useState<Set<string>>(new Set());
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [officerNote, setOfficerNote] = useState("");
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    if (!getAccessToken()) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const [workerPayload, societyPayload, federationPayload, servicePayload] = await Promise.all([
        api<unknown>("/admin/workers", { query: { limit: 100 } }),
        api<unknown>("/admin/societies").catch(() => []),
        api<unknown>("/admin/federations").catch(() => []),
        api<unknown>("/admin/services").catch(() => api<unknown>("/services")).catch(() => []),
      ]);
      setWorkers(unwrapPage<WorkerRow>(workerPayload).items);
      setCategories(flattenServices(unwrapList<ServiceRow>(servicePayload)));
      const fromSocieties = unwrapPage<Society>(societyPayload).items;
      if (fromSocieties.length) {
        setSocieties(fromSocieties);
      } else {
        const federations = unwrapPage<Federation>(federationPayload).items;
        setSocieties(federations.flatMap((f) => f.societies ?? []));
      }
      setError(null);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const filteredWorkers = useMemo(() => {
    if (statusFilter === "ALL") return workers;
    if (statusFilter === "SUSPENDED") {
      return workers.filter((w) => w.badgeState === "SUSPENDED" || w.verificationStatus === "SUSPENDED");
    }
    return workers.filter((w) => w.verificationStatus === statusFilter);
  }, [workers, statusFilter]);

  const allSelected = filteredWorkers.length > 0 && selected.size === filteredWorkers.length;

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function bulk(action: "approve" | "reject") {
    if (selected.size === 0) return;
    setBusy(true);
    try {
      await api("/admin/workers/bulk-verify", {
        method: "POST",
        body: { workerIds: [...selected], action },
      });
      setSelected(new Set());
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  function applyWorker(updated: WorkerRow) {
    setWorkers((prev) =>
      prev.map((row) => (row.id === updated.id || row.userId === updated.userId ? { ...row, ...updated } : row)),
    );
    setActive((current) =>
      current && (current.id === updated.id || current.userId === updated.userId)
        ? { ...current, ...updated }
        : current,
    );
  }

  function openSkills(worker: WorkerRow) {
    setSkillsFor(worker);
    setCheckedSkills(new Set(selectedSkillIds(worker, categories)));
  }

  function toggleSkill(categoryId: string) {
    setCheckedSkills((prev) => {
      const next = new Set(prev);
      if (next.has(categoryId)) next.delete(categoryId);
      else next.add(categoryId);
      return next;
    });
  }

  async function saveSkills(event: FormEvent) {
    event.preventDefault();
    if (!skillsFor) return;
    setBusy(true);
    try {
      const updated = await api<WorkerRow>(`/admin/workers/${skillsFor.id}/skills`, {
        method: "PATCH",
        body: { categoryIds: [...checkedSkills] },
      });
      applyWorker(updated);
      setSkillsFor(null);
      setError(null);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  async function assignSociety(workerId: string, societyId: string) {
    try {
      await api(`/admin/workers/${workerId}/society`, {
        method: "PATCH",
        body: { societyId },
      });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  async function openWorker(worker: WorkerRow) {
    try {
      const detail = await api<WorkerRow>(`/admin/workers/${worker.id}`);
      setActive(detail);
      setOfficerNote(detail.verificationNote || "");
    } catch {
      setActive(worker);
      setOfficerNote(worker.verificationNote || "");
    }
  }

  async function patchOfficerAction(
    action: "approve_probation" | "approve_full" | "request_info" | "suspend" | "restore" | "revoke" | "reject",
  ) {
    if (!active) return;
    setBusy(true);
    try {
      const updated = await api<WorkerRow>(`/admin/workers/${active.id}/verify`, {
        method: "PATCH",
        body: { action, note: officerNote.trim() || undefined },
      });
      applyWorker(updated);
      setActive(updated);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  async function patchEvidence(evidenceId: string, status: EvidenceStatus) {
    if (!active) return;
    setBusy(true);
    try {
      await api(`/admin/workers/${active.id}/evidence/${evidenceId}`, {
        method: "PATCH",
        body: { status },
      });
      const detail = await api<WorkerRow>(`/admin/workers/${active.id}`);
      applyWorker(detail);
      setActive(detail);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  async function toggleReferenceVerified(refId: string, currentVerified: boolean) {
    if (!active) return;
    setBusy(true);
    try {
      await api(`/admin/workers/${active.id}/references/${refId}`, {
        method: "PATCH",
        body: { verified: !currentVerified },
      });
      const detail = await api<WorkerRow>(`/admin/workers/${active.id}`);
      applyWorker(detail);
      setActive(detail);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  async function patchCert(cert: Certification, status: "APPROVED" | "REJECTED") {
    if (!active) return;
    setBusy(true);
    try {
      await api(`/admin/workers/${active.id}/certifications/${cert.id}`, {
        method: "PATCH",
        body: { status },
      });
      const detail = await api<WorkerRow>(`/admin/workers/${active.id}`);
      applyWorker(detail);
      setActive(detail);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  const societyOptions = useMemo(
    () => societies.map((s) => ({ id: s.id, label: s.federation ? `${s.name} · ${s.federation.name}` : s.name })),
    [societies],
  );

  return (
    <div>
      <PageHeader
        title="Workers"
        subtitle="Community Skill Verification, Capability Gate & Area Officer Oversight"
        actions={
          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={busy || selected.size === 0}
              onClick={() => void bulk("approve")}
              className="rounded-md bg-teal px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
            >
              Bulk approve
            </button>
            <button
              type="button"
              disabled={busy || selected.size === 0}
              onClick={() => void bulk("reject")}
              className="rounded-md border border-danger px-3 py-1.5 text-xs font-semibold text-danger disabled:opacity-50"
            >
              Bulk reject
            </button>
          </div>
        }
      />
      <ErrorText error={error} />

      {/* Filter Tabs */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <span className="flex items-center gap-1 text-xs font-medium text-muted mr-1">
          <Filter size={13} /> Filter:
        </span>
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.value}
            type="button"
            onClick={() => setStatusFilter(f.value)}
            className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
              statusFilter === f.value
                ? "bg-teal text-white shadow-sm"
                : "bg-white text-muted border border-border hover:bg-field"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="overflow-hidden rounded-lg border border-border bg-white shadow-sm">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="w-10 px-3 py-2.5">
                <input
                  type="checkbox"
                  checked={allSelected}
                  onChange={() =>
                    setSelected(allSelected ? new Set() : new Set(filteredWorkers.map((w) => w.id)))
                  }
                />
              </th>
              <th className="px-3 py-2.5">Worker Name</th>
              <th className="px-3 py-2.5">Phone</th>
              <th className="px-3 py-2.5">Primary Trade & Risk</th>
              <th className="px-3 py-2.5">Verification Status</th>
              <th className="px-3 py-2.5">Job Gate</th>
              <th className="px-3 py-2.5">Society</th>
              <th className="px-3 py-2.5">Rating</th>
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={8} /> : null}
            {!loading && filteredWorkers.length === 0 ? (
              <tr>
                <td colSpan={8} className="p-4">
                  <EmptyState message="No workers matching this filter." />
                </td>
              </tr>
            ) : null}
            {filteredWorkers.map((worker) => {
              const primarySkill = worker.skillsDetailed?.[0];
              const riskTier = primarySkill?.riskTier ?? "LOW";
              const isProbation = worker.verificationStatus === "COMMUNITY_VERIFIED_PROBATION";

              return (
                <tr
                  key={worker.id}
                  className="cursor-pointer border-t border-border hover:bg-field/70 transition-colors"
                  onClick={() => void openWorker(worker)}
                >
                  <td className="px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                    <input
                      type="checkbox"
                      checked={selected.has(worker.id)}
                      onChange={() => toggle(worker.id)}
                    />
                  </td>
                  <td className="px-3 py-2.5 font-medium text-navy">
                    {worker.name}
                    {worker.badgeState === "SUSPENDED" && (
                      <span className="ml-1.5 rounded bg-red-100 px-1.5 py-0.2 text-[10px] text-red-700 font-bold">
                        SUSPENDED
                      </span>
                    )}
                  </td>
                  <td className="px-3 py-2.5 text-muted">{formatPhone(worker.phone)}</td>
                  <td className="px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                    <div className="flex items-center gap-1.5">
                      <span className="font-medium text-xs">{worker.skills?.[0] || "—"}</span>
                      {worker.skills?.[0] && (
                        <StatusBadge value={riskTier} />
                      )}
                      <button
                        type="button"
                        onClick={() => openSkills(worker)}
                        className="ml-1 text-muted hover:text-teal"
                        title="Edit skills"
                      >
                        <Pencil size={12} />
                      </button>
                    </div>
                  </td>
                  <td className="px-3 py-2.5">
                    <div className="flex flex-col gap-0.5">
                      <StatusBadge value={worker.verificationStatus} />
                      {isProbation && (
                        <span className="text-[10px] font-medium text-amber-800">
                          Probation: {worker.probationJobCount ?? 0}/5 jobs
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-3 py-2.5">
                    {worker.jobEligible ? (
                      <span className="inline-flex items-center gap-1 text-[11px] font-medium text-teal">
                        <ShieldCheck size={13} /> Eligible
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-[11px] font-medium text-muted">
                        <ShieldAlert size={13} /> Capped / Ineligible
                      </span>
                    )}
                  </td>
                  <td className="px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                    <select
                      value={worker.societyId || worker.society?.id || ""}
                      onChange={(e) => void assignSociety(worker.id, e.target.value)}
                      className="max-w-[180px] rounded border border-border bg-white px-2 py-1 text-xs"
                    >
                      {societyOptions.map((option) => (
                        <option key={option.id} value={option.id}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td className="px-3 py-2.5">
                    <span className="font-medium">
                      {Number(worker.rating ?? worker.ratingAverage ?? 0).toFixed(1)}
                    </span>
                    <span className="text-xs text-muted ml-0.5">({worker.reviewCount ?? 0})</span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Skills edit modal */}
      {skillsFor ? (
        <Modal title={`Skills · ${skillsFor.name}`} onClose={() => setSkillsFor(null)}>
          <form onSubmit={(e) => void saveSkills(e)}>
            <p className="mb-3 text-xs text-muted">Select every service category this worker can take.</p>
            {categories.length === 0 ? (
              <EmptyState message="No service categories available." />
            ) : (
              <div className="mb-4 max-h-72 space-y-1 overflow-y-auto rounded-md border border-border p-2">
                {categories.map((category) => (
                  <label
                    key={category.id}
                    className="flex cursor-pointer items-center justify-between rounded px-2 py-1.5 text-sm hover:bg-field"
                  >
                    <div className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={checkedSkills.has(category.id)}
                        onChange={() => toggleSkill(category.id)}
                      />
                      <span>{category.name}</span>
                    </div>
                    <span className="text-[10px] text-muted uppercase">{category.pricingType}</span>
                  </label>
                ))}
              </div>
            )}
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setSkillsFor(null)}
                className="rounded-md border border-border px-3 py-1.5 text-xs font-semibold text-muted"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={busy}
                className="rounded-md bg-teal px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
              >
                {busy ? "Saving…" : "Save skills"}
              </button>
            </div>
          </form>
        </Modal>
      ) : null}

      {/* Area Verification Officer Review Modal */}
      {active ? (
        <Modal title={`Area Officer Verification · ${active.name}`} onClose={() => setActive(null)} wide>
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3 border-b border-border pb-3">
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-semibold text-navy">{active.name}</h3>
                <StatusBadge value={active.verificationStatus} />
                <span className={`text-xs px-2 py-0.5 rounded font-medium ${active.badgeState === "ACTIVE" ? "bg-teal-50 text-teal" : "bg-amber-100 text-amber-800"}`}>
                  Badge: {active.badgeState || "ACTIVE"}
                </span>
              </div>
              <p className="mt-0.5 text-xs text-muted">
                {formatPhone(active.phone)} · {active.society?.name ?? "No society"} · Rating: {Number(active.ratingAverage ?? 0).toFixed(1)} ({active.reviewCount ?? 0} reviews)
              </p>
            </div>
            <div className="text-right">
              <div className="text-xs text-muted">Capability Gate:</div>
              <span className={`text-xs font-bold ${active.jobEligible ? "text-teal" : "text-amber-700"}`}>
                {active.jobEligible ? "✓ Job Eligible" : "⚠ Not Job Eligible"}
              </span>
            </div>
          </div>

          <div className="space-y-5">
            {/* Section 13 Structured Verification Checklist */}
            <div className="rounded-lg border border-border bg-field/40 p-3">
              <h4 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted flex items-center gap-1.5">
                <CheckCircle2 size={14} className="text-teal" /> Structured Verification Checklist (Section 13)
              </h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
                <div className="rounded bg-white p-2 border border-border">
                  <span className="text-muted block text-[10px]">Phone & Identity</span>
                  <span className="font-semibold text-teal">✓ Verified</span>
                </div>
                <div className="rounded bg-white p-2 border border-border">
                  <span className="text-muted block text-[10px]">Service Area</span>
                  <span className="font-semibold text-navy">{active.society?.name || "Assigned"}</span>
                </div>
                <div className="rounded bg-white p-2 border border-border">
                  <span className="text-muted block text-[10px]">Primary Trade Tier</span>
                  <span className="font-semibold">{active.skillsDetailed?.[0]?.riskTier || "LOW"} Risk</span>
                </div>
                <div className="rounded bg-white p-2 border border-border">
                  <span className="text-muted block text-[10px]">Practical Check</span>
                  <span className={`font-semibold ${active.skillsDetailed?.[0]?.riskTier === "HIGH" ? (active.skillsDetailed?.[0]?.practicalCheckPassed ? "text-teal" : "text-danger") : "text-muted"}`}>
                    {active.skillsDetailed?.[0]?.riskTier === "HIGH" ? (active.skillsDetailed?.[0]?.practicalCheckPassed ? "✓ PASSED" : "REQUIRED") : "N/A (Low/Med)"}
                  </span>
                </div>
              </div>
            </div>

            {/* Officer Action Panel */}
            <div className="rounded-lg border border-teal/30 bg-teal-50/40 p-3">
              <h4 className="mb-2 text-xs font-bold text-navy flex items-center justify-between">
                <span>Area Officer Decision & Oversight</span>
                <span className="text-[11px] font-normal text-muted">Section 14 & 15</span>
              </h4>
              <div className="mb-3">
                <input
                  type="text"
                  placeholder="Optional verification notes or explanation..."
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  className="w-full rounded border border-border bg-white px-2.5 py-1.5 text-xs"
                />
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void patchOfficerAction("approve_probation")}
                  className="rounded-md bg-teal px-3 py-1.5 text-xs font-semibold text-white hover:bg-teal-dark transition-colors"
                >
                  Approve (Probation Gate)
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void patchOfficerAction("approve_full")}
                  className="rounded-md bg-navy px-3 py-1.5 text-xs font-semibold text-white hover:bg-navy/90 transition-colors"
                >
                  Promote Full Community Verified
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void patchOfficerAction("request_info")}
                  className="rounded-md border border-border bg-white px-3 py-1.5 text-xs font-semibold text-muted hover:bg-field"
                >
                  Request More Info
                </button>
                {active.badgeState === "SUSPENDED" ? (
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void patchOfficerAction("restore")}
                    className="rounded-md border border-teal bg-white px-3 py-1.5 text-xs font-semibold text-teal hover:bg-teal-50"
                  >
                    Restore Active Badge
                  </button>
                ) : (
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void patchOfficerAction("suspend")}
                    className="rounded-md border border-amber-600 bg-white px-3 py-1.5 text-xs font-semibold text-amber-700 hover:bg-amber-50"
                  >
                    Suspend Worker
                  </button>
                )}
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void patchOfficerAction("reject")}
                  className="rounded-md border border-danger bg-white px-3 py-1.5 text-xs font-semibold text-danger hover:bg-red-50"
                >
                  Reject
                </button>
              </div>
            </div>

            {/* Community References Section */}
            <div>
              <div className="mb-2 flex items-center justify-between">
                <h4 className="text-xs font-bold uppercase tracking-wider text-muted">
                  Community References (Section 9–11)
                </h4>
                <span className="text-xs text-muted">
                  {active.references?.filter((r) => r.verified).length || 0} of {active.references?.length || 0} verified
                </span>
              </div>
              {(active.references ?? []).length === 0 ? (
                <p className="rounded border border-dashed border-border p-3 text-center text-xs text-muted">
                  No community references submitted yet.
                </p>
              ) : (
                <div className="grid gap-2 sm:grid-cols-2">
                  {active.references!.map((ref) => (
                    <div key={ref.id} className="rounded-lg border border-border bg-white p-3 text-xs">
                      <div className="flex items-start justify-between">
                        <div>
                          <p className="font-semibold text-navy">{ref.name}</p>
                          <p className="text-muted">{formatPhone(ref.phone)} · {ref.relationship}</p>
                          {ref.yearsKnown && <p className="text-muted mt-0.5">Known: {ref.yearsKnown}</p>}
                          {ref.workObserved && <p className="text-muted mt-0.5">Observed: {ref.workObserved}</p>}
                        </div>
                        <button
                          type="button"
                          disabled={busy}
                          onClick={() => void toggleReferenceVerified(ref.id, ref.verified)}
                          className={`rounded px-2 py-1 font-semibold text-[11px] ${
                            ref.verified ? "bg-teal-50 text-teal border border-teal/30" : "bg-field text-muted border border-border"
                          }`}
                        >
                          {ref.verified ? "✓ Verified" : "Mark Verified"}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Verification Evidence & Practical Check */}
            <div>
              <div className="mb-2 flex items-center justify-between">
                <h4 className="text-xs font-bold uppercase tracking-wider text-muted">
                  Experience Evidence & Practical Check (Section 10 & 34)
                </h4>
              </div>
              {(active.evidences ?? []).length === 0 ? (
                <p className="rounded border border-dashed border-border p-3 text-center text-xs text-muted">
                  No experience evidence or practical check uploaded.
                </p>
              ) : (
                <div className="space-y-2">
                  {active.evidences!.map((ev) => (
                    <div key={ev.id} className="rounded-lg border border-border bg-white p-3 text-xs">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-semibold text-navy">{ev.title || ev.evidenceType}</span>
                            <StatusBadge value={ev.status} />
                            {ev.evidenceType === "PRACTICAL_CHECK" && (
                              <span className="rounded bg-purple-50 px-1.5 py-0.5 text-[10px] font-bold text-purple-700 border border-purple-200">
                                High-Risk Practical Check
                              </span>
                            )}
                          </div>
                          {ev.description && <p className="mt-1 text-muted">{ev.description}</p>}
                          {ev.fileUrl && (
                            <a
                              href={ev.fileUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="mt-1.5 inline-flex items-center gap-1 text-teal hover:underline font-medium"
                            >
                              <ExternalLink size={12} /> View Submission
                            </a>
                          )}
                        </div>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => void patchEvidence(ev.id, "PASSED")}
                            className="rounded bg-teal px-2 py-1 font-semibold text-[11px] text-white hover:bg-teal-dark"
                          >
                            Pass
                          </button>
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => void patchEvidence(ev.id, "FAILED")}
                            className="rounded border border-danger px-2 py-1 font-semibold text-[11px] text-danger hover:bg-red-50"
                          >
                            Fail
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Formal Certifications Section */}
            <div>
              <h4 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted">
                Formal Certificates (Section 23 - Regulated Services)
              </h4>
              {(active.certifications ?? []).length === 0 ? (
                <p className="rounded border border-dashed border-border p-3 text-center text-xs text-muted">
                  No formal certificate uploaded. (Community Verification does not require certificates).
                </p>
              ) : (
                <div className="space-y-2">
                  {active.certifications!.map((cert) => (
                    <div key={cert.id} className="rounded-lg border border-border bg-white p-3 text-xs">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <StatusBadge value={cert.status} />
                          <p className="mt-1 break-all text-muted">{cert.docUrl}</p>
                          {cert.adminNote ? <p className="mt-1 text-navy">{cert.adminNote}</p> : null}
                        </div>
                        <div className="flex gap-2 shrink-0">
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => void patchCert(cert, "APPROVED")}
                            className="rounded-md bg-teal px-2.5 py-1 text-xs font-semibold text-white"
                          >
                            Approve
                          </button>
                          <button
                            type="button"
                            disabled={busy}
                            onClick={() => void patchCert(cert, "REJECTED")}
                            className="rounded-md border border-danger px-2.5 py-1 text-xs font-semibold text-danger"
                          >
                            Reject
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </Modal>
      ) : null}
    </div>
  );
}
