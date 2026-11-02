import { FormEvent, useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { Modal } from "../components/Modal";
import { PageHeader } from "../components/PageHeader";
import { StatusBadge } from "../components/StatusBadge";
import { api, unwrapPage } from "../lib/api";
import { displayName, formatDateTime } from "../lib/format";
import type { DisputeRow } from "../types";

export function DisputesPage() {
  const [rows, setRows] = useState<DisputeRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);
  const [active, setActive] = useState<DisputeRow | null>(null);
  const [note, setNote] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/disputes", { query: { limit: 100 } });
      setRows(unwrapPage<DisputeRow>(data).items);
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

  async function resolve(event: FormEvent) {
    event.preventDefault();
    if (!active) return;
    try {
      await api(`/admin/disputes/${active.id}`, {
        method: "PATCH",
        body: { status: "RESOLVED", note },
      });
      setActive(null);
      setNote("");
      await load();
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader title="Disputes" subtitle="BookingIssue records" />
      <ErrorText error={error} />
      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Opened</th>
              <th className="px-3 py-2">Category</th>
              <th className="px-3 py-2">Booking</th>
              <th className="px-3 py-2">Reporter</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2" />
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={6} /> : null}
            {!loading && rows.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-4">
                  <EmptyState message="No disputes." />
                </td>
              </tr>
            ) : null}
            {rows.map((row) => (
              <tr key={row.id} className="border-t border-border">
                <td className="px-3 py-2">{formatDateTime(row.createdAt)}</td>
                <td className="px-3 py-2 font-medium">{row.category}</td>
                <td className="px-3 py-2 text-xs text-muted">
                  {row.booking?.serviceCategory?.name ?? row.bookingId.slice(0, 8)}
                </td>
                <td className="px-3 py-2">{displayName(row.reporter)}</td>
                <td className="px-3 py-2">
                  <StatusBadge value={row.status} />
                </td>
                <td className="px-3 py-2 text-right">
                  <button
                    type="button"
                    onClick={() => {
                      setActive(row);
                      setNote(row.adminNote ?? "");
                    }}
                    className="text-xs font-semibold text-teal"
                  >
                    Resolve
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {active ? (
        <Modal title="Resolve dispute" onClose={() => setActive(null)}>
          <p className="mb-2 text-sm font-medium">{active.category}</p>
          <p className="mb-3 text-sm text-muted">{active.description}</p>
          <form onSubmit={(e) => void resolve(e)} className="space-y-3">
            <label className="block text-xs font-semibold text-muted">Resolution note</label>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="h-28 w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
              required
            />
            <button type="submit" className="rounded-md bg-teal px-3 py-2 text-sm font-semibold text-white">
              Mark resolved
            </button>
          </form>
        </Modal>
      ) : null}
    </div>
  );
}
