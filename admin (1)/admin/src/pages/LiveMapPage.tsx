import L from "leaflet";
import { useEffect, useMemo, useState } from "react";
import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import { ErrorText } from "../components/EmptyState";
import { StatusBadge } from "../components/StatusBadge";
import { api } from "../lib/api";
import { prettyStatus } from "../lib/format";
import type { BookingStatus, LiveMapMarker } from "../types";

const STATUS_COLOR: Record<BookingStatus, string> = {
  PENDING_MATCH: "#9A5B12",
  BROADCASTING: "#9A5B12",
  ACCEPTED: "#17707D",
  EN_ROUTE: "#17707D",
  ARRIVED: "#12525C",
  IN_PROGRESS: "#12525C",
  AWAITING_PAYMENT: "#9A5B12",
  COMPLETED: "#3F7078",
  CANCELLED: "#B42318",
  DISPUTED: "#B42318",
};

const DEFAULT_CENTER: [number, number] = [8.5241, 76.9366];

function markerIcon(status: BookingStatus) {
  const color = STATUS_COLOR[status] ?? "#17707D";
  return L.divIcon({
    className: "",
    iconSize: [18, 18],
    iconAnchor: [9, 9],
    popupAnchor: [0, -10],
    html: `<span style="display:block;width:16px;height:16px;border-radius:999px;background:${color};border:2px solid white;box-shadow:0 0 0 1px ${color}"></span>`,
  });
}

export function LiveMapPage() {
  const [markers, setMarkers] = useState<LiveMapMarker[]>([]);
  const [error, setError] = useState<unknown>(null);
  const [ready, setReady] = useState(false);
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);

  useEffect(() => setReady(true), []);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      try {
        const data = await api<LiveMapMarker[]>("/admin/live-map");
        if (cancelled) return;
        setMarkers(Array.isArray(data) ? data : []);
        setUpdatedAt(new Date());
        setError(null);
      } catch (err) {
        if (!cancelled) setError(err);
      }
    }
    void load();
    const timer = window.setInterval(() => void load(), 12000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, []);

  const center = useMemo<[number, number]>(() => {
    if (markers[0]) return [markers[0].lat, markers[0].lng];
    return DEFAULT_CENTER;
  }, [markers]);

  const counts = useMemo(() => {
    const map = new Map<string, number>();
    for (const marker of markers) map.set(marker.status, (map.get(marker.status) ?? 0) + 1);
    return [...map.entries()];
  }, [markers]);

  return (
    <div className="-m-5 flex h-[calc(100%+2.5rem)] min-h-[520px] flex-col">
      <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border bg-white px-5 py-3">
        <div>
          <h1 className="text-lg font-semibold text-navy">Live Map</h1>
          <p className="text-xs text-muted">
            Active bookings · auto-refresh 12s
            {updatedAt ? ` · updated ${updatedAt.toLocaleTimeString("en-IN")}` : ""}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          {counts.map(([status, count]) => (
            <span key={status} className="inline-flex items-center gap-1.5 text-xs text-muted">
              <span
                className="inline-block h-2.5 w-2.5 rounded-full"
                style={{ background: STATUS_COLOR[status as BookingStatus] }}
              />
              {prettyStatus(status)} ({count})
            </span>
          ))}
        </div>
      </div>
      <div className="relative min-h-0 flex-1">
        <div className="absolute left-4 top-3 z-[400]">
          <ErrorText error={error} />
        </div>
        {ready ? (
          <MapContainer center={center} zoom={12} className="h-full w-full" scrollWheelZoom>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            {markers.map((marker) => (
              <Marker
                key={marker.id}
                position={[marker.lat, marker.lng]}
                icon={markerIcon(marker.status)}
              >
                <Popup>
                  <div className="min-w-[180px] text-sm">
                    <p className="font-semibold text-navy">{marker.category}</p>
                    <div className="mt-1">
                      <StatusBadge value={marker.status} />
                    </div>
                    <p className="mt-2 text-xs text-muted">Worker</p>
                    <p className="font-medium">{marker.workerName}</p>
                    <p className="mt-1 text-xs text-muted">Customer</p>
                    <p className="font-medium">{marker.customerName}</p>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        ) : null}
      </div>
    </div>
  );
}
