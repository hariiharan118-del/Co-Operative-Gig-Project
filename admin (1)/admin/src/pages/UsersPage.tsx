import { useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { PageHeader } from "../components/PageHeader";
import { StatusBadge } from "../components/StatusBadge";
import { api, unwrapPage } from "../lib/api";
import { formatDate, formatPhone } from "../lib/format";
import type { UserRow } from "../types";

export function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/users", { query: { limit: 100 } });
      setUsers(unwrapPage<UserRow>(data).items);
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

  async function setStatus(user: UserRow, action: "activate" | "deactivate") {
    try {
      await api(`/admin/users/${user.id}/status`, { method: "PATCH", body: { action } });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader title="Users" subtitle="Customer and worker accounts" />
      <ErrorText error={error} />
      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Name</th>
              <th className="px-3 py-2">Phone</th>
              <th className="px-3 py-2">Join date</th>
              <th className="px-3 py-2">Role</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2" />
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={6} /> : null}
            {!loading && users.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-4">
                  <EmptyState message="No users found." />
                </td>
              </tr>
            ) : null}
            {users.map((user) => (
              <tr key={user.id} className="border-t border-border">
                <td className="px-3 py-2 font-medium">{user.name}</td>
                <td className="px-3 py-2 text-muted">{formatPhone(user.phone)}</td>
                <td className="px-3 py-2">{formatDate(user.joinDate ?? user.createdAt)}</td>
                <td className="px-3 py-2">
                  <StatusBadge value={user.role} />
                </td>
                <td className="px-3 py-2">
                  <StatusBadge value={user.status} />
                </td>
                <td className="px-3 py-2 text-right">
                  {user.status === "DISABLED" ? (
                    <button
                      type="button"
                      onClick={() => void setStatus(user, "activate")}
                      className="text-xs font-semibold text-teal"
                    >
                      Activate
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => void setStatus(user, "deactivate")}
                      className="text-xs font-semibold text-danger"
                    >
                      Deactivate
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
