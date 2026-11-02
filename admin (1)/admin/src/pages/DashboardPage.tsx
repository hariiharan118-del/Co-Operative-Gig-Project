import { useEffect, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { ErrorText } from "../components/EmptyState";
import { PageHeader } from "../components/PageHeader";
import { api } from "../lib/api";
import { formatDate, formatInr } from "../lib/format";
import type { AdminStats, BookingPoint, DemandPoint, RevenuePoint } from "../types";

const TEAL = "#17707D";
const ACCENT = "#AEDDE3";

export function DashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [revenue, setRevenue] = useState<RevenuePoint[]>([]);
  const [bookings, setBookings] = useState<BookingPoint[]>([]);
  const [demand, setDemand] = useState<DemandPoint[]>([]);
  const [error, setError] = useState<unknown>(null);
  const [range, setRange] = useState<"7d" | "30d" | "90d">("30d");

  useEffect(() => {
    let cancelled = false;
    setError(null);
    Promise.allSettled([
      api<AdminStats>("/admin/stats"),
      api<RevenuePoint[]>("/admin/analytics/revenue", { query: { range } }),
      api<BookingPoint[]>("/admin/analytics/bookings", { query: { range } }),
      api<DemandPoint[]>("/admin/analytics/demand-by-category", { query: { range } }),
    ]).then(([statsRes, revenueRes, bookingsRes, demandRes]) => {
      if (cancelled) return;
      if (statsRes.status === "fulfilled") setStats(statsRes.value);
      if (revenueRes.status === "fulfilled") {
        setRevenue(Array.isArray(revenueRes.value) ? revenueRes.value : []);
      }
      if (bookingsRes.status === "fulfilled") {
        setBookings(Array.isArray(bookingsRes.value) ? bookingsRes.value : []);
      }
      if (demandRes.status === "fulfilled") {
        setDemand(Array.isArray(demandRes.value) ? demandRes.value : []);
      }
      const firstError = [statsRes, revenueRes, bookingsRes, demandRes].find(
        (result) => result.status === "rejected",
      );
      setError(firstError && firstError.status === "rejected" ? firstError.reason : null);
    });
    return () => {
      cancelled = true;
    };
  }, [range]);

  const cards = [
    { label: "Revenue", value: formatInr(stats?.revenue) },
    { label: "Active bookings", value: stats?.activeBookings ?? "—" },
    { label: "Workers", value: stats?.totalWorkers ?? "—" },
    { label: "Customers", value: stats?.totalCustomers ?? "—" },
    { label: "Pending verifies", value: stats?.pendingVerifications ?? "—" },
    { label: "Open disputes", value: stats?.openDisputes ?? "—" },
    { label: "Welfare claims", value: stats?.openClaims ?? "—" },
    { label: "Escalated support", value: stats?.escalatedSupport ?? "—" },
  ];

  return (
    <div>
      <PageHeader
        title="Dashboard"
        subtitle="Platform volume, revenue, and outstanding work"
        actions={
          <select
            value={range}
            onChange={(e) => setRange(e.target.value as "7d" | "30d" | "90d")}
            className="rounded-md border border-border bg-white px-2 py-1.5 text-sm"
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
            <option value="90d">Last 90 days</option>
          </select>
        }
      />
      <ErrorText error={error} />
      <div className="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
        {cards.map((card) => (
          <div key={card.label} className="rounded-lg border border-border bg-white px-4 py-3">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">{card.label}</p>
            <p className="mt-1 text-xl font-semibold text-navy">{card.value}</p>
          </div>
        ))}
      </div>
      <div className="grid gap-4 xl:grid-cols-2">
        <ChartCard title="Revenue over time">
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={revenue}>
              <CartesianGrid stroke="#D4E4E7" strokeDasharray="3 3" />
              <XAxis dataKey="date" tickFormatter={(v) => formatDate(v)} tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip formatter={(value) => formatInr(value)} labelFormatter={(v) => formatDate(String(v))} />
              <Line type="monotone" dataKey="revenue" stroke={TEAL} strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>
        <ChartCard title="Booking volume over time">
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={bookings}>
              <CartesianGrid stroke="#D4E4E7" strokeDasharray="3 3" />
              <XAxis dataKey="date" tickFormatter={(v) => formatDate(v)} tick={{ fontSize: 11 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
              <Tooltip labelFormatter={(v) => formatDate(String(v))} />
              <Line type="monotone" dataKey="count" stroke={TEAL} strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>
        <ChartCard title="Demand by category" className="xl:col-span-2">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={demand}>
              <CartesianGrid stroke="#D4E4E7" strokeDasharray="3 3" />
              <XAxis dataKey="category" tick={{ fontSize: 11 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="count" fill={ACCENT} stroke={TEAL} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>
    </div>
  );
}

function ChartCard({
  title,
  children,
  className = "",
}: {
  title: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section className={`rounded-lg border border-border bg-white p-4 ${className}`}>
      <h2 className="mb-3 text-sm font-semibold text-navy">{title}</h2>
      {children}
    </section>
  );
}
