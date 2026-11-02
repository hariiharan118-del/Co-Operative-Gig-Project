import { FormEvent, useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText } from "../components/EmptyState";
import { PageHeader } from "../components/PageHeader";
import { useAuth } from "../context/AuthContext";
import { api } from "../lib/api";
import { asNumber, displayName, formatPhone } from "../lib/format";
import type { PlatformProbationConfig } from "../types";

type CommissionRow = {
  categoryId: string;
  name: string;
  commissionRate: number;
  basePricing?: number;
};

export function SettingsPage() {
  const { user } = useAuth();
  const [rows, setRows] = useState<CommissionRow[]>([]);
  const [probationConfig, setProbationConfig] = useState<PlatformProbationConfig>({
    probationJobCountRequired: 5,
    probationMinRating: 4.0,
    probationJobValueCap: 1000,
    probationMaxConcurrentJobs: 2,
  });
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [probationSaved, setProbationSaved] = useState(false);

  const load = useCallback(async () => {
    try {
      const [settingsData, probationData] = await Promise.all([
        api<{ commissions?: CommissionRow[] }>("/admin/settings"),
        api<PlatformProbationConfig>("/admin/config/probation").catch(() => ({
          probationJobCountRequired: 5,
          probationMinRating: 4.0,
          probationJobValueCap: 1000,
          probationMaxConcurrentJobs: 2,
        })),
      ]);
      setRows(settingsData.commissions ?? []);
      setProbationConfig(probationData);
      setError(null);
    } catch (err) {
      setError(err);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function saveCommissions(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await api("/admin/settings/commission", {
        method: "PATCH",
        body: {
          items: rows.map((row) => ({
            categoryId: row.categoryId,
            commissionRate: asNumber(row.commissionRate),
          })),
        },
      });
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  async function saveProbationConfig(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setProbationSaved(false);
    try {
      const updated = await api<PlatformProbationConfig>("/admin/config/probation", {
        method: "PATCH",
        body: {
          probationJobCountRequired: Number(probationConfig.probationJobCountRequired),
          probationMinRating: Number(probationConfig.probationMinRating),
          probationJobValueCap: Number(probationConfig.probationJobValueCap),
          probationMaxConcurrentJobs: Number(probationConfig.probationMaxConcurrentJobs),
        },
      });
      setProbationConfig(updated);
      setProbationSaved(true);
      setTimeout(() => setProbationSaved(false), 3000);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Settings" subtitle="Account, platform probation gate, and commission rates" />
      <ErrorText error={error} />
      <section className="mb-5 rounded-lg border border-border bg-white p-4 text-sm shadow-sm">
        <h2 className="mb-2 text-sm font-semibold text-navy">Signed in as</h2>
        <p className="font-medium">{displayName(user, "Admin")}</p>
        <p className="text-muted text-xs">
          {formatPhone(user?.phone)} · {user?.role}
        </p>
      </section>

      {/* Section 16 & 23B Probation & Capability Gate Management */}
      <form onSubmit={(e) => void saveProbationConfig(e)} className="mb-5 rounded-lg border border-border bg-white p-4 shadow-sm">
        <div className="mb-3 flex items-center justify-between">
          <div>
            <h2 className="text-sm font-semibold text-navy">Probation & Capability Gate Thresholds</h2>
            <p className="text-xs text-muted">Configure limits for workers in COMMUNITY_VERIFIED_PROBATION status (Section 16 & 23B)</p>
          </div>
          {probationSaved && (
            <span className="text-xs font-semibold text-teal">✓ Saved</span>
          )}
        </div>
        <div className="grid gap-4 sm:grid-cols-2 text-sm">
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-navy">Required Probation Jobs</span>
            <span className="text-[11px] text-muted">Completed jobs before auto-promotion</span>
            <input
              type="number"
              min={1}
              max={50}
              value={probationConfig.probationJobCountRequired}
              onChange={(e) =>
                setProbationConfig((prev) => ({
                  ...prev,
                  probationJobCountRequired: Number(e.target.value),
                }))
              }
              className="rounded-md border border-border bg-field px-3 py-1.5 text-sm"
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-navy">Minimum Rating Threshold</span>
            <span className="text-[11px] text-muted">Min average rating for promotion (e.g. 4.0)</span>
            <input
              type="number"
              min={1.0}
              max={5.0}
              step={0.1}
              value={probationConfig.probationMinRating}
              onChange={(e) =>
                setProbationConfig((prev) => ({
                  ...prev,
                  probationMinRating: Number(e.target.value),
                }))
              }
              className="rounded-md border border-border bg-field px-3 py-1.5 text-sm"
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-navy">Maximum Job Value Cap (₹)</span>
            <span className="text-[11px] text-muted">Max single job value during probation</span>
            <input
              type="number"
              min={100}
              max={50000}
              step={50}
              value={probationConfig.probationJobValueCap}
              onChange={(e) =>
                setProbationConfig((prev) => ({
                  ...prev,
                  probationJobValueCap: Number(e.target.value),
                }))
              }
              className="rounded-md border border-border bg-field px-3 py-1.5 text-sm"
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-navy">Max Active Concurrent Jobs</span>
            <span className="text-[11px] text-muted">Concurrent in-progress jobs per probation worker</span>
            <input
              type="number"
              min={1}
              max={10}
              value={probationConfig.probationMaxConcurrentJobs}
              onChange={(e) =>
                setProbationConfig((prev) => ({
                  ...prev,
                  probationMaxConcurrentJobs: Number(e.target.value),
                }))
              }
              className="rounded-md border border-border bg-field px-3 py-1.5 text-sm"
            />
          </label>
        </div>
        <button
          type="submit"
          disabled={busy}
          className="mt-4 rounded-md bg-teal px-3 py-2 text-xs font-semibold text-white disabled:opacity-60 hover:bg-teal-dark transition-colors"
        >
          {busy ? "Saving…" : "Save probation settings"}
        </button>
      </form>

      <form onSubmit={(e) => void saveCommissions(e)} className="rounded-lg border border-border bg-white p-4 shadow-sm">
        <h2 className="mb-3 text-sm font-semibold text-navy">Commission rates</h2>
        {rows.length === 0 ? <EmptyState message="No commission settings returned." /> : null}
        <div className="space-y-2">
          {rows.map((row) => (
            <label key={row.categoryId} className="flex items-center justify-between gap-3 text-sm">
              <span>{row.name}</span>
              <input
                type="number"
                min={0}
                max={100}
                step={0.1}
                value={row.commissionRate}
                onChange={(e) =>
                  setRows((prev) =>
                    prev.map((item) =>
                      item.categoryId === row.categoryId
                        ? { ...item, commissionRate: Number(e.target.value) }
                        : item,
                    ),
                  )
                }
                className="w-24 rounded-md border border-border bg-field px-2 py-1 text-right"
              />
            </label>
          ))}
        </div>
        {rows.length > 0 ? (
          <button
            type="submit"
            disabled={busy}
            className="mt-4 rounded-md bg-teal px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {busy ? "Saving…" : "Save commissions"}
          </button>
        ) : null}
      </form>
    </div>
  );
}
