import { useEffect, useState } from "react";
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";

export function AppLayout() {
  const { user, ready } = useAuth();
  const [navOpen, setNavOpen] = useState(false);

  useEffect(() => {
    if (!navOpen) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setNavOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [navOpen]);

  if (!ready) return null;
  if (!user) return <Navigate to="/login" replace />;

  return (
    <div className="flex h-full min-h-0 bg-[#f7fbfc]">
      <div
        className={`fixed inset-0 z-40 bg-navy/40 transition-opacity md:hidden ${
          navOpen ? "opacity-100" : "pointer-events-none opacity-0"
        }`}
        onClick={() => setNavOpen(false)}
        aria-hidden={!navOpen}
      />
      <Sidebar open={navOpen} onNavigate={() => setNavOpen(false)} />
      <div className="flex min-w-0 flex-1 flex-col">
        <TopBar onMenuClick={() => setNavOpen(true)} />
        <main className="min-h-0 flex-1 overflow-auto p-4 md:p-5">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
