import { ChevronDown, ChevronRight } from "lucide-react";
import { FormEvent, useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText } from "../components/EmptyState";
import { Modal } from "../components/Modal";
import { PageHeader } from "../components/PageHeader";
import { api, unwrapList } from "../lib/api";
import type { Federation, Society } from "../types";

export function FederationsPage() {
  const [federations, setFederations] = useState<Federation[]>([]);
  const [openIds, setOpenIds] = useState<Set<string>>(new Set());
  const [error, setError] = useState<unknown>(null);
  const [federationForm, setFederationForm] = useState<Partial<Federation> | null>(null);
  const [societyForm, setSocietyForm] = useState<{ federationId: string; society?: Society } | null>(null);

  const load = useCallback(async () => {
    try {
      const data = await api<unknown>("/admin/federations");
      setFederations(unwrapList<Federation>(data));
      setError(null);
    } catch (err) {
      setError(err);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  function toggle(id: string) {
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function removeFederation(id: string) {
    if (!window.confirm("Delete this federation?")) return;
    try {
      await api(`/admin/federations/${id}`, { method: "DELETE" });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  async function removeSociety(id: string) {
    if (!window.confirm("Delete this society?")) return;
    try {
      await api(`/admin/societies/${id}`, { method: "DELETE" });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader
        title="Federations"
        subtitle="Two-level cooperative structure"
        actions={
          <button
            type="button"
            onClick={() => setFederationForm({})}
            className="rounded-md bg-teal px-3 py-1.5 text-xs font-semibold text-white"
          >
            Add federation
          </button>
        }
      />
      <ErrorText error={error} />
      <div className="space-y-2">
        {federations.length === 0 ? <EmptyState message="No federations yet." /> : null}
        {federations.map((federation) => {
          const open = openIds.has(federation.id);
          return (
            <section key={federation.id} className="rounded-lg border border-border bg-white">
              <div className="flex items-center gap-2 px-3 py-3">
                <button type="button" onClick={() => toggle(federation.id)} className="text-muted">
                  {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                </button>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold">{federation.name}</p>
                  <p className="text-xs text-muted">{federation.region}</p>
                </div>
                <button
                  type="button"
                  onClick={() => setSocietyForm({ federationId: federation.id })}
                  className="text-xs font-semibold text-teal"
                >
                  Add society
                </button>
                <button type="button" onClick={() => setFederationForm(federation)} className="text-xs font-semibold text-teal">
                  Edit
                </button>
                <button
                  type="button"
                  onClick={() => void removeFederation(federation.id)}
                  className="text-xs font-semibold text-danger"
                >
                  Delete
                </button>
              </div>
              {open ? (
                <div className="border-t border-border px-4 py-2">
                  {(federation.societies ?? []).length === 0 ? (
                    <p className="py-3 text-sm text-muted">No societies in this federation.</p>
                  ) : (
                    <table className="min-w-full text-sm">
                      <tbody>
                        {federation.societies!.map((society) => (
                          <tr key={society.id} className="border-b border-border last:border-0">
                            <td className="py-2 font-medium">{society.name}</td>
                            <td className="py-2 text-right">
                              <button
                                type="button"
                                onClick={() => setSocietyForm({ federationId: federation.id, society })}
                                className="mr-3 text-xs font-semibold text-teal"
                              >
                                Edit
                              </button>
                              <button
                                type="button"
                                onClick={() => void removeSociety(society.id)}
                                className="text-xs font-semibold text-danger"
                              >
                                Delete
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              ) : null}
            </section>
          );
        })}
      </div>

      {federationForm ? (
        <NamedForm
          title={federationForm.id ? "Edit federation" : "Add federation"}
          fields={[
            { key: "name", label: "Name", value: federationForm.name ?? "" },
            { key: "region", label: "Region", value: federationForm.region ?? "" },
          ]}
          onClose={() => setFederationForm(null)}
          onSubmit={async (values) => {
            if (federationForm.id) {
              await api(`/admin/federations/${federationForm.id}`, { method: "PATCH", body: values });
            } else {
              await api("/admin/federations", { method: "POST", body: values });
            }
            setFederationForm(null);
            await load();
          }}
        />
      ) : null}

      {societyForm ? (
        <NamedForm
          title={societyForm.society ? "Edit society" : "Add society"}
          fields={[{ key: "name", label: "Name", value: societyForm.society?.name ?? "" }]}
          onClose={() => setSocietyForm(null)}
          onSubmit={async (values) => {
            if (societyForm.society) {
              await api(`/admin/societies/${societyForm.society.id}`, {
                method: "PATCH",
                body: { ...values, federationId: societyForm.federationId },
              });
            } else {
              await api("/admin/societies", {
                method: "POST",
                body: { ...values, federationId: societyForm.federationId },
              });
            }
            setSocietyForm(null);
            await load();
          }}
        />
      ) : null}
    </div>
  );
}

function NamedForm({
  title,
  fields,
  onClose,
  onSubmit,
}: {
  title: string;
  fields: Array<{ key: string; label: string; value: string }>;
  onClose: () => void;
  onSubmit: (values: Record<string, string>) => Promise<void>;
}) {
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(fields.map((f) => [f.key, f.value])),
  );
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await onSubmit(values);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title={title} onClose={onClose}>
      <form onSubmit={(e) => void submit(e)} className="space-y-3">
        {fields.map((field) => (
          <label key={field.key} className="block">
            <span className="mb-1 block text-xs font-semibold text-muted">{field.label}</span>
            <input
              value={values[field.key] ?? ""}
              onChange={(e) => setValues((prev) => ({ ...prev, [field.key]: e.target.value }))}
              className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
              required
            />
          </label>
        ))}
        <ErrorText error={error} />
        <button type="submit" disabled={busy} className="rounded-md bg-teal px-3 py-2 text-sm font-semibold text-white">
          Save
        </button>
      </form>
    </Modal>
  );
}
