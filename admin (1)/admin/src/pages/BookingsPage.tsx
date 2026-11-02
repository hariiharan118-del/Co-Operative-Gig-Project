import { useCallback, useEffect, useState } from "react";
import { EmptyState, ErrorText, LoadingRows } from "../components/EmptyState";
import { Modal } from "../components/Modal";
import { PageHeader } from "../components/PageHeader";
import { StatusBadge } from "../components/StatusBadge";
import { api, unwrapList, unwrapPage } from "../lib/api";
import { displayName, formatDateTime, formatInr, formatPhone } from "../lib/format";
import type { BookingRow, BookingStatus, ServiceRow } from "../types";

const STATUSES: Array<BookingStatus | ""> = [
  "",
  "PENDING_MATCH",
  "BROADCASTING",
  "ACCEPTED",
  "EN_ROUTE",
  "ARRIVED",
  "IN_PROGRESS",
  "AWAITING_PAYMENT",
  "COMPLETED",
  "CANCELLED",
  "DISPUTED",
];

export function BookingsPage() {
  const [bookings, setBookings] = useState<BookingRow[]>([]);
  const [services, setServices] = useState<ServiceRow[]>([]);
  const [status, setStatus] = useState<BookingStatus | "">("");
  const [categoryId, setCategoryId] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>(null);
  const [detail, setDetail] = useState<BookingRow | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api<unknown>("/admin/bookings", {
        query: { limit: 100, status: status || undefined, categoryId: categoryId || undefined, from, to },
      });
      setBookings(unwrapPage<BookingRow>(data).items);
      setError(null);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [status, categoryId, from, to]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    api<unknown>("/admin/services")
      .then((data) => setServices(unwrapList<ServiceRow>(data)))
      .catch(() => undefined);
  }, []);

  async function openDetail(id: string) {
    try {
      setDetail(await api<BookingRow>(`/admin/bookings/${id}`));
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div>
      <PageHeader title="Bookings" subtitle="Filter by status, date, and category" />
      <div className="mb-3 flex flex-wrap gap-2">
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value as BookingStatus | "")}
          className="rounded-md border border-border bg-white px-2 py-1.5 text-sm"
        >
          <option value="">All statuses</option>
          {STATUSES.filter(Boolean).map((value) => (
            <option key={value} value={value}>
              {value.replaceAll("_", " ")}
            </option>
          ))}
        </select>
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
          className="rounded-md border border-border bg-white px-2 py-1.5 text-sm"
        >
          <option value="">All categories</option>
          {services.map((service) => (
            <option key={service.id} value={service.id}>
              {service.name}
            </option>
          ))}
        </select>
        <input
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          className="rounded-md border border-border bg-white px-2 py-1.5 text-sm"
        />
        <input
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          className="rounded-md border border-border bg-white px-2 py-1.5 text-sm"
        />
      </div>
      <ErrorText error={error} />
      <div className="overflow-hidden rounded-lg border border-border bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-field text-[11px] uppercase tracking-wide text-muted">
            <tr>
              <th className="px-3 py-2">Created</th>
              <th className="px-3 py-2">Category</th>
              <th className="px-3 py-2">Customer</th>
              <th className="px-3 py-2">Worker</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2">Amount</th>
            </tr>
          </thead>
          <tbody>
            {loading ? <LoadingRows cols={6} /> : null}
            {!loading && bookings.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-4">
                  <EmptyState message="No bookings match these filters." />
                </td>
              </tr>
            ) : null}
            {bookings.map((booking) => (
              <tr
                key={booking.id}
                className="cursor-pointer border-t border-border hover:bg-field/70"
                onClick={() => void openDetail(booking.id)}
              >
                <td className="px-3 py-2">{formatDateTime(booking.createdAt)}</td>
                <td className="px-3 py-2 font-medium">{booking.serviceCategory?.name ?? "—"}</td>
                <td className="px-3 py-2">{displayName(booking.customer)}</td>
                <td className="px-3 py-2">{displayName(booking.worker, "Unassigned")}</td>
                <td className="px-3 py-2">
                  <StatusBadge value={booking.status} />
                </td>
                <td className="px-3 py-2">{booking.payment ? formatInr(booking.payment.amount) : "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {detail ? (
        <Modal title={`Booking ${detail.id.slice(0, 8)}`} onClose={() => setDetail(null)} wide>
          <div className="grid gap-4 text-sm md:grid-cols-2">
            <Field label="Status" value={<StatusBadge value={detail.status} />} />
            <Field label="Created" value={formatDateTime(detail.createdAt)} />
            <Field label="Scheduled" value={formatDateTime(detail.scheduledAt)} />
            <Field label="Category" value={detail.serviceCategory?.name ?? "—"} />
            <Field
              label="Customer"
              value={`${displayName(detail.customer)} · ${formatPhone(detail.customer?.phone)}`}
            />
            <Field
              label="Worker"
              value={`${displayName(detail.worker, "Unassigned")} · ${formatPhone(detail.worker?.phone)}`}
            />
            <Field
              label="Address"
              value={
                detail.address
                  ? `${detail.address.line1 ?? ""}, ${detail.address.city ?? ""} ${detail.address.pincode ?? ""}`
                  : "—"
              }
            />
            <Field
              label="Payment"
              value={
                detail.payment
                  ? `${formatInr(detail.payment.amount)} · ${detail.payment.status}`
                  : "—"
              }
            />
            {detail.cancelReason ? <Field label="Cancel reason" value={detail.cancelReason} /> : null}
          </div>
          {detail.reviews?.length ? (
            <div className="mt-4">
              <p className="mb-2 text-xs font-semibold uppercase text-muted">Reviews</p>
              {detail.reviews.map((review, i) => (
                <p key={i} className="text-sm">
                  {review.direction}: {review.rating}/5 {review.comment ? `· ${review.comment}` : ""}
                </p>
              ))}
            </div>
          ) : null}
        </Modal>
      ) : null}
    </div>
  );
}

function Field({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">{label}</p>
      <div className="mt-0.5">{value}</div>
    </div>
  );
}
