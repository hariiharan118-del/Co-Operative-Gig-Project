import type { AuthSession } from "../types";

export const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://187.127.175.116:3000").replace(
  /\/$/,
  "",
);

const ACCESS_KEY = "coop_admin_access";
const REFRESH_KEY = "coop_admin_refresh";

export class ApiError extends Error {
  status: number;
  code?: string;

  constructor(message: string, status: number, code?: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_KEY);
}

export function hasStoredSession(): boolean {
  return Boolean(getAccessToken() || getRefreshToken());
}

export function persistSession(session: Pick<AuthSession, "accessToken" | "refreshToken">) {
  localStorage.setItem(ACCESS_KEY, session.accessToken);
  localStorage.setItem(REFRESH_KEY, session.refreshToken);
}

export function clearSession() {
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

type SessionListener = () => void;
const sessionListeners = new Set<SessionListener>();

export function onSessionExpired(listener: SessionListener) {
  sessionListeners.add(listener);
  return () => {
    sessionListeners.delete(listener);
  };
}

function expireSession() {
  const hadSession = hasStoredSession();
  clearSession();
  if (hadSession) {
    sessionListeners.forEach((listener) => listener());
  }
}

function readError(payload: unknown, fallback: string): { message: string; code?: string } {
  if (payload && typeof payload === "object") {
    const obj = payload as Record<string, unknown>;
    const err = obj.error;
    if (err && typeof err === "object") {
      const nested = err as Record<string, unknown>;
      return {
        message: typeof nested.message === "string" ? nested.message : fallback,
        code: typeof nested.code === "string" ? nested.code : undefined,
      };
    }
    if (typeof obj.message === "string") return { message: obj.message };
  }
  return { message: fallback };
}

export function unwrapList<T>(payload: unknown): T[] {
  if (Array.isArray(payload)) return payload as T[];
  if (payload && typeof payload === "object") {
    const obj = payload as Record<string, unknown>;
    if (Array.isArray(obj.items)) return obj.items as T[];
    if (Array.isArray(obj.data)) return obj.data as T[];
    if (Array.isArray(obj.results)) return obj.results as T[];
  }
  return [];
}

export function unwrapPage<T>(payload: unknown): { items: T[]; total: number; page: number; limit: number } {
  if (Array.isArray(payload)) {
    return { items: payload as T[], total: payload.length, page: 1, limit: payload.length };
  }
  if (payload && typeof payload === "object") {
    const obj = payload as Record<string, unknown>;
    const items = unwrapList<T>(payload);
    return {
      items,
      total: typeof obj.total === "number" ? obj.total : items.length,
      page: typeof obj.page === "number" ? obj.page : 1,
      limit: typeof obj.limit === "number" ? obj.limit : items.length,
    };
  }
  return { items: [], total: 0, page: 1, limit: 20 };
}

type RequestOptions = {
  method?: string;
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined | null>;
  auth?: boolean;
  skipRefresh?: boolean;
};

function toQuery(query?: RequestOptions["query"]): string {
  if (!query) return "";
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === "") continue;
    params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

async function parseBody(res: Response): Promise<unknown> {
  if (res.status === 204) return null;
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return text;
  }
}

let refreshPromise: Promise<boolean> | null = null;

export async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    try {
      const res = await fetch(`${API_BASE}/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken }),
      });
      const payload = await parseBody(res);
      if (!res.ok) return false;
      const session = payload as AuthSession;
      if (!session?.accessToken || !session?.refreshToken) return false;
      persistSession(session);
      return true;
    } catch {
      return false;
    }
  })().finally(() => {
    refreshPromise = null;
  });

  return refreshPromise;
}

export async function api<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = "GET", body, query, auth = true, skipRefresh = false } = options;

  if (auth && !skipRefresh && !getAccessToken() && getRefreshToken()) {
    const refreshed = await refreshAccessToken();
    if (!refreshed) {
      expireSession();
      throw new ApiError("Session expired", 401, "UNAUTHENTICATED");
    }
  }

  if (auth && !getAccessToken()) {
    throw new ApiError("Not signed in", 401, "UNAUTHENTICATED");
  }

  const headers: Record<string, string> = {};
  if (body !== undefined) headers["Content-Type"] = "application/json";
  if (auth) {
    const token = getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}${toQuery(query)}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (res.status === 401 && auth && !skipRefresh) {
    const ok = await refreshAccessToken();
    if (ok) return api<T>(path, { ...options, skipRefresh: true });
    expireSession();
  }

  const payload = await parseBody(res);
  if (!res.ok) {
    const err = readError(payload, res.statusText || "Request failed");
    throw new ApiError(err.message, res.status, err.code);
  }
  return payload as T;
}
