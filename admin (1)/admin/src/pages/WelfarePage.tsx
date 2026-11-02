import { useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { PageHeader } from "../components/PageHeader";
import { StatusBadge } from "../components/StatusBadge";
import { api, unwrapPage } from "../lib/api";
import { formatDateTime, formatPhone } from "../lib/format";
import type { WelfareClaimRow } from "../types";

export function WelfarePage() {
  const [rows, setRows] = useState<WelfareClaimRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/welfare/claims", { query: { limit: 100 } });
      setRows(unwrapPage<WelfareClaimRow>(data).items);
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

  async function decide(id: string, status: "APPROVED" | "REJECTED") {
    try {
      await api(`/admin/welfare/claims/${id}`, { method: "PATCH", body: { status } });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader title="Welfare" subtitle="Worker welfare claims" />
      <ErrorText error={error} />
      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Submitted</th>
              <th className="px-3 py-2">Worker</th>
              <th className="px-3 py-2">Category</th>
              <th className="px-3 py-2">Description</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2" />
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={6} /> : null}
            {!loading && rows.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-4">
                  <EmptyState message="No welfare claims." />
                </td>
              </tr>
            ) : null}
            {rows.map((row) => (
              <tr key={row.id} className="border-t border-border">
                <td className="px-3 py-2">{formatDateTime(row.createdAt)}</td>
                <td className="px-3 py-2">
                  <p className="font-medium">{row.welfare?.worker?.name ?? "—"}</p>
                  <p className="text-xs text-muted">{formatPhone(row.welfare?.worker?.user?.phone)}</p>
                </td>
                <td className="px-3 py-2">{row.category}</td>
                <td className="max-w-xs px-3 py-2 text-xs text-muted">{row.description}</td>
                <td className="px-3 py-2">
                  <StatusBadge value={row.status} />
                </td>
                <td className="px-3 py-2 text-right">
                  <button
                    type="button"
                    onClick={() => void decide(row.id, "APPROVED")}
                    className="mr-2 text-xs font-semibold text-teal"
                  >
                    Approve
                  </button>
                  <button
                    type="button"
                    onClick={() => void decide(row.id, "REJECTED")}
                    className="text-xs font-semibold text-danger"
                  >
                    Reject
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
