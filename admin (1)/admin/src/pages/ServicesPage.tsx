import { FormEvent, useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { Modal } from "../components/Modal";
import { PageHeader } from "../components/PageHeader";
import { api, unwrapList } from "../lib/api";
import { asNumber, formatInr } from "../lib/format";
import type { PricingType, ServiceRow } from "../types";

export function ServicesPage() {
  const [services, setServices] = useState<ServiceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [editing, setEditing] = useState<ServiceRow | null>(null);
  const [commissionFor, setCommissionFor] = useState<ServiceRow | null>(null);
  const [commission, setCommission] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/services");
      setServices(flatten(unwrapList<ServiceRow>(data)));
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

  async function remove(id: string) {
    if (!window.confirm("Delete this service?")) return;
    try {
      await api(`/admin/services/${id}`, { method: "DELETE" });
      await load();
    } catch (err) {
      setError(err);
    }
  }

  async function saveCommission(event: FormEvent) {
    event.preventDefault();
    if (!commissionFor) return;
    try {
      await api("/admin/settings/commission", {
        method: "PATCH",
        body: { categoryId: commissionFor.id, commissionRate: Number(commission) },
      });
      setCommissionFor(null);
      await load();
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader
        title="Services"
        subtitle="Categories, pricing, and commission rates"
        actions={
          <button
            type="button"
            onClick={() => setShowAdd(true)}
            className="rounded-md bg-teal px-3 py-1.5 text-xs font-semibold text-white"
          >
            Add service
          </button>
        }
      />
      <ErrorText error={error} />
      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Name</th>
              <th className="px-3 py-2">Price</th>
              <th className="px-3 py-2">Type</th>
              <th className="px-3 py-2">Commission</th>
              <th className="px-3 py-2" />
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={5} /> : null}
            {!loading && services.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-4">
                  <EmptyState message="No services configured." />
                </td>
              </tr>
            ) : null}
            {services.map((service) => (
              <tr key={service.id} className="border-t border-border">
                <td className="px-3 py-2 font-medium">{service.name}</td>
                <td className="px-3 py-2">{formatInr(service.basePricing)}</td>
                <td className="px-3 py-2 text-xs text-muted">{service.pricingType}</td>
                <td className="px-3 py-2">
                  <button
                    type="button"
                    onClick={() => {
                      setCommissionFor(service);
                      setCommission(String(asNumber(service.commissionRate)));
                    }}
                    className="rounded border border-border px-2 py-0.5 text-xs font-semibold text-teal hover:bg-field"
                  >
                    {asNumber(service.commissionRate)}%
                  </button>
                </td>
                <td className="px-3 py-2 text-right">
                  <button type="button" onClick={() => setEditing(service)} className="mr-2 text-xs font-semibold text-teal">
                    Edit
                  </button>
                  <button type="button" onClick={() => void remove(service.id)} className="text-xs font-semibold text-danger">
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {showAdd ? (
        <ServiceForm
          title="Add service"
          onClose={() => setShowAdd(false)}
          onSaved={async () => {
            setShowAdd(false);
            await load();
          }}
        />
      ) : null}
      {editing ? (
        <ServiceForm
          title="Edit service"
          initial={editing}
          onClose={() => setEditing(null)}
          onSaved={async () => {
            setEditing(null);
            await load();
          }}
        />
      ) : null}
      {commissionFor ? (
        <Modal title={`Commission · ${commissionFor.name}`} onClose={() => setCommissionFor(null)}>
          <form onSubmit={(e) => void saveCommission(e)} className="space-y-3">
            <label className="block text-xs font-semibold text-muted">Commission rate (%)</label>
            <input
              type="number"
              min={0}
              max={100}
              step={0.1}
              value={commission}
              onChange={(e) => setCommission(e.target.value)}
              className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
              required
            />
            <button type="submit" className="rounded-md bg-teal px-3 py-2 text-sm font-semibold text-white">
              Save
            </button>
          </form>
        </Modal>
      ) : null}
    </div>
  );
}

function flatten(rows: ServiceRow[]): ServiceRow[] {
  return rows.flatMap((row) => [row, ...(row.children ?? [])]);
}

function ServiceForm({
  title,
  initial,
  onClose,
  onSaved,
}: {
  title: string;
  initial?: ServiceRow;
  onClose: () => void;
  onSaved: () => Promise<void>;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [price, setPrice] = useState(String(asNumber(initial?.basePricing) || ""));
  const [pricingType, setPricingType] = useState<PricingType>(initial?.pricingType ?? "HOURLY");
  const [commissionRate, setCommissionRate] = useState(String(asNumber(initial?.commissionRate)));
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      const body = {
        name,
        basePricing: Number(price),
        pricingType,
        commissionRate: Number(commissionRate || 0),
      };
      if (initial) {
        await api(`/admin/services/${initial.id}`, { method: "PATCH", body });
      } else {
        await api("/admin/services", { method: "POST", body });
      }
      await onSaved();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title={title} onClose={onClose}>
      <form onSubmit={(e) => void onSubmit(e)} className="space-y-3">
        <Field label="Name" value={name} onChange={setName} />
        <Field label="Price (INR)" value={price} onChange={setPrice} type="number" />
        <label className="block text-xs font-semibold text-muted">Pricing type</label>
        <select
          value={pricingType}
          onChange={(e) => setPricingType(e.target.value as PricingType)}
          className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
        >
          <option value="HOURLY">Hourly</option>
          <option value="FIXED">Fixed</option>
        </select>
        <Field label="Commission rate (%)" value={commissionRate} onChange={setCommissionRate} type="number" />
        <ErrorText error={error} />
        <button
          type="submit"
          disabled={busy}
          className="rounded-md bg-teal px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {busy ? "Saving…" : "Save"}
        </button>
      </form>
    </Modal>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold text-muted">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-md border border-border bg-field px-3 py-2 text-sm"
        required
      />
    </label>
  );
}
