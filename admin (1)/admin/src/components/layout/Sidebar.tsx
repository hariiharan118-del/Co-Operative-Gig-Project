import {
  Bell,
  Briefcase,
  Building2,
  CircleHelp,
  ClipboardList,
  Handshake,
  LayoutDashboard,
  Map,
  Megaphone,
  Scale,
  Settings,
  ShieldAlert,
  Users,
} from "lucide-react";
import { NavLink } from "react-router-dom";
import { BrandMark } from "../BrandMark";

const LINKS = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard, end: true },
  { to: "/live-map", label: "Live Map", icon: Map },
  { to: "/workers", label: "Workers", icon: Handshake },
  { to: "/services", label: "Services", icon: Briefcase },
  { to: "/federations", label: "Federations", icon: Building2 },
  { to: "/users", label: "Users", icon: Users },
  { to: "/bookings", label: "Bookings", icon: ClipboardList },
  { to: "/disputes", label: "Disputes", icon: ShieldAlert },
  { to: "/welfare", label: "Welfare", icon: Scale },
  { to: "/support", label: "Support", icon: CircleHelp },
  { to: "/announcements", label: "Announcements", icon: Megaphone },
  { to: "/settings", label: "Settings", icon: Settings },
] as const;

type SidebarProps = {
  open: boolean;
  onNavigate?: () => void;
};

export function Sidebar({ open, onNavigate }: SidebarProps) {
  return (
    <aside
      className={`fixed inset-y-0 left-0 z-50 flex w-56 shrink-0 flex-col border-r border-border bg-white transition-transform duration-200 ease-out md:static md:z-auto md:translate-x-0 ${
        open ? "translate-x-0" : "-translate-x-full"
      }`}
    >
      <div className="flex items-center gap-2.5 border-b border-border px-4 py-4">
        <BrandMark size={32} />
        <div>
          <p className="text-[13px] font-bold leading-tight text-navy">Co-opServe</p>
          <p className="text-[11px] font-medium text-muted">Admin</p>
        </div>
      </div>
      <nav className="flex-1 overflow-y-auto px-2 py-3">
        {LINKS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={"end" in item ? item.end : false}
            onClick={onNavigate}
            className={({ isActive }) =>
              `mb-0.5 flex items-center gap-2.5 rounded-md px-2.5 py-2 text-[13px] font-medium ${
                isActive ? "bg-accent-soft text-teal" : "text-muted hover:bg-field hover:text-navy"
              }`
            }
          >
            <item.icon size={16} />
            {item.label}
          </NavLink>
        ))}
      </nav>
      <div className="border-t border-border px-4 py-3 text-[11px] text-muted">
        <Bell size={12} className="mr-1 inline" />
        Internal operations
      </div>
    </aside>
  );
}
