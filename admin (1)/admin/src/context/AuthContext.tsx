import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  api,
  clearSession,
  getAccessToken,
  getRefreshToken,
  onSessionExpired,
  persistSession,
  refreshAccessToken,
} from "../lib/api";
import { normalizePhone } from "../lib/format";
import type { AuthSession, Role, SessionUser } from "../types";

const ADMIN_ROLES: Role[] = ["ADMIN", "SUPER_ADMIN"];

type AuthState = {
  user: SessionUser | null;
  ready: boolean;
  splashVisible: boolean;
  login: (phone: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

function isAdmin(user?: SessionUser | null): user is SessionUser {
  return Boolean(user && ADMIN_ROLES.includes(user.role));
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [ready, setReady] = useState(false);
  const [splashVisible, setSplashVisible] = useState(true);

  const finishBoot = useCallback((next: SessionUser | null) => {
    setUser(next);
    setReady(true);
    window.setTimeout(() => setSplashVisible(false), 380);
  }, []);

  useEffect(() => {
    return onSessionExpired(() => setUser(null));
  }, []);

  useEffect(() => {
    const started = Date.now();
    const minSplash = 900;
    let cancelled = false;

    async function restoreUser(): Promise<SessionUser | null> {
      if (!getAccessToken() && getRefreshToken()) {
        const refreshed = await refreshAccessToken();
        if (!refreshed) {
          clearSession();
          return null;
        }
      }
      if (!getAccessToken()) return null;

      const me = await api<SessionUser>("/auth/me");
      if (!isAdmin(me)) {
        clearSession();
        return null;
      }
      return me;
    }

    async function boot() {
      let next: SessionUser | null = null;
      try {
        next = await restoreUser();
      } catch {
        clearSession();
        next = null;
      }
      const wait = Math.max(0, minSplash - (Date.now() - started));
      await new Promise((resolve) => window.setTimeout(resolve, wait));
      if (!cancelled) finishBoot(next);
    }

    void boot();
    return () => {
      cancelled = true;
    };
  }, [finishBoot]);

  const login = useCallback(async (phone: string, password: string) => {
    const session = await api<AuthSession>("/auth/login", {
      method: "POST",
      auth: false,
      body: { phone: normalizePhone(phone), password },
    });
    if (!isAdmin(session.user)) {
      throw new Error("This account is not an admin. Access is limited to ADMIN and SUPER_ADMIN.");
    }
    persistSession(session);
    const me = await api<SessionUser>("/auth/me").catch(() => session.user);
    if (!isAdmin(me)) {
      clearSession();
      throw new Error("This account is not an admin. Access is limited to ADMIN and SUPER_ADMIN.");
    }
    setUser(me);
  }, []);

  const logout = useCallback(async () => {
    const refreshToken = getRefreshToken();
    try {
      if (refreshToken) {
        await api("/auth/logout", { method: "POST", auth: false, body: { refreshToken } });
      }
    } catch {
      // still clear locally
    }
    clearSession();
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, ready, splashVisible, login, logout }),
    [user, ready, splashVisible, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
