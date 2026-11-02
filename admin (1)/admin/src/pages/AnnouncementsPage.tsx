import { FormEvent, useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { PageHeader } from "../components/PageHeader";
import { api, unwrapPage } from "../lib/api";
import { formatDateTime, prettyStatus } from "../lib/format";
import type { AnnouncementAudience, AnnouncementRow } from "../types";

export function AnnouncementsPage() {
  const [rows, setRows] = useState<AnnouncementRow[]>([]);
  const [audience, setAudience] = useState<AnnouncementAudience>("all");
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/announcements", { query: { limit: 100 } });
      setRows(unwrapPage<AnnouncementRow>(data).items);
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

  async function send(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await api("/admin/announcements", {
        method: "POST",
        body: { audience, title, message },
      });
      setTitle("");
      setMessage("");
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Announcements" subtitle="Broadcast to workers, customers, or everyone" />
      <ErrorText error={error} />
      <form onSubmit={(e) => void send(e)} className="mb-5 rounded-lg border border-border bg-white p-4">
        <div className="grid gap-3 md:grid-cols-3">
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-semibold text-muted">Audience</span>
            <select
              value={audience}
              onChange={(e) => setAudience(e.target.value as AnnouncementAudience)}
              className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
            >
              <option value="workers">Workers</option>
              <option value="customers">Customers</option>
              <option value="all">All</option>
            </select>
          </label>
          <label className="block text-sm md:col-span-2">
            <span className="mb-1 block text-xs font-semibold text-muted">Title</span>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
              required
            />
          </label>
        </div>
        <label className="mt-3 block text-sm">
          <span className="mb-1 block text-xs font-semibold text-muted">Message</span>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="h-28 w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
            required
          />
        </label>
        <button
          type="submit"
          disabled={busy}
          className="mt-3 rounded-md bg-teal px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {busy ? "Sending…" : "Send"}
        </button>
      </form>

      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Sent</th>
              <th className="px-3 py-2">Audience</th>
              <th className="px-3 py-2">Title</th>
              <th className="px-3 py-2">Message</th>
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={4} /> : null}
            {!loading && rows.length === 0 ? (
              <tr>
                <td colSpan={4} className="p-4">
                  <EmptyState message="No announcements sent yet." />
                </td>
              </tr>
            ) : null}
            {rows.map((row) => (
              <tr key={row.id} className="border-t border-border">
                <td className="whitespace-nowrap px-3 py-2">{formatDateTime(row.createdAt)}</td>
                <td className="px-3 py-2">{prettyStatus(row.audience)}</td>
                <td className="px-3 py-2 font-medium">{row.title}</td>
                <td className="max-w-xl px-3 py-2 text-xs text-muted">{row.message}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
