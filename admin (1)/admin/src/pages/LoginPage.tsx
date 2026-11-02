import { FormEvent, useState } from "react";
import { Navigate } from "react-router-dom";
import { BrandMark } from "../components/BrandMark";
import { useAuth } from "../context/AuthContext";

export function LoginPage() {
  const { user, ready, login } = useAuth();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (ready && user) return <Navigate to="/" replace />;

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await login(phone, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex min-h-full items-center justify-center bg-[#f7fbfc] p-6">
      <form
        onSubmit={(e) => void onSubmit(e)}
        className="w-full max-w-sm rounded-2xl border border-border bg-white p-7 shadow-sm"
      >
        <div className="mb-6 flex flex-col items-center text-center">
          <BrandMark size={56} />
          <h1 className="mt-3 text-xl font-bold text-navy">Co-opServe Admin</h1>
          <p className="mt-1 text-sm text-muted">Sign in with your admin phone and password</p>
        </div>
        <label className="mb-1 block text-xs font-semibold text-muted">Phone</label>
        <input
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          className="mb-3 w-full rounded-md border border-border bg-field px-3 py-2 text-sm outline-none focus:border-teal"
          placeholder="+91 98765 43212"
          autoComplete="username"
          required
        />
        <label className="mb-1 block text-xs font-semibold text-muted">Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mb-4 w-full rounded-md border border-border bg-field px-3 py-2 text-sm outline-none focus:border-teal"
          placeholder="Password"
          autoComplete="current-password"
          required
        />
        {error ? <p className="mb-3 text-sm text-danger">{error}</p> : null}
        <button
          type="submit"
          disabled={busy}
          className="w-full rounded-md bg-teal py-2.5 text-sm font-semibold text-white hover:bg-teal-dark disabled:opacity-60"
        >
          {busy ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}
