import { LogOut, Menu } from "lucide-react";
import { useAuth } from "../../context/AuthContext";
import { displayName, formatPhone, prettyStatus } from "../../lib/format";

type TopBarProps = {
  onMenuClick: () => void;
};

export function TopBar({ onMenuClick }: TopBarProps) {
  const { user, logout } = useAuth();
  const name = displayName(user, "Admin");

  return (
    <header className="flex h-14 shrink-0 items-center justify-between gap-3 border-b border-border bg-white px-4 md:px-5">
      <div className="flex min-w-0 items-center gap-2">
        <button
          type="button"
          onClick={onMenuClick}
          className="rounded-md p-1.5 text-navy hover:bg-field md:hidden"
          aria-label="Open menu"
        >
          <Menu size={20} />
        </button>
        <p className="truncate text-sm font-medium text-muted">Operations console</p>
      </div>
      <div className="flex items-center gap-3">
        <div className="hidden text-right sm:block">
          <p className="text-sm font-semibold text-navy">{name}</p>
          <p className="text-[11px] text-muted">
            {prettyStatus(user?.role)} · {formatPhone(user?.phone)}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void logout()}
          className="inline-flex items-center gap-1.5 rounded-md border border-border px-2.5 py-1.5 text-xs font-semibold text-muted hover:bg-field hover:text-navy"
        >
          <LogOut size={14} />
          Logout
        </button>
      </div>
    </header>
  );
}
