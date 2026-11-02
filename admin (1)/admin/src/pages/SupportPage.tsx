import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { EmptyState, ErrorText } from "../components/EmptyState";
import { StatusBadge } from "../components/StatusBadge";
import { api, unwrapPage } from "../lib/api";
import { displayName, formatDateTime, formatPhone } from "../lib/format";
import type { SupportConversation, SupportConversationStatus, SupportMessage } from "../types";

const TABS: Array<{ id: SupportConversationStatus | "ALL"; label: string }> = [
  { id: "ALL", label: "All" },
  { id: "AI_HANDLING", label: "AI-handling" },
  { id: "ESCALATED", label: "Escalated" },
  { id: "RESOLVED", label: "Resolved" },
];

export function SupportPage() {
  const [tab, setTab] = useState<SupportConversationStatus | "ALL">("ESCALATED");
  const [items, setItems] = useState<SupportConversation[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [thread, setThread] = useState<SupportConversation | null>(null);
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<unknown>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const loadList = useCallback(async () => {
    try {
      const data = await api<unknown>("/admin/support/conversations", {
        query: { limit: 100, status: tab === "ALL" ? undefined : tab },
      });
      const next = unwrapPage<SupportConversation>(data).items;
      setItems(next);
      setError(null);
      setActiveId((current) => current ?? next[0]?.id ?? null);
    } catch (err) {
      setError(err);
    }
  }, [tab]);

  const loadThread = useCallback(async (id: string) => {
    const data = await api<SupportConversation>(`/admin/support/conversations/${id}`);
    setThread(data);
  }, []);

  useEffect(() => {
    setActiveId(null);
    setThread(null);
    void loadList();
  }, [loadList]);

  useEffect(() => {
    if (!activeId) return;
    void loadThread(activeId).catch((err) => setError(err));
  }, [activeId, loadThread]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [thread?.messages?.length]);

  const messages = thread?.messages ?? [];

  async function send(event: FormEvent) {
    event.preventDefault();
    if (!activeId || !draft.trim()) return;
    const content = draft.trim();
    const optimistic: SupportMessage = {
      id: `local-${Date.now()}`,
      sender: "AGENT",
      content,
      createdAt: new Date().toISOString(),
    };
    setThread((prev) =>
      prev ? { ...prev, messages: [...(prev.messages ?? []), optimistic] } : prev,
    );
    setDraft("");
    try {
      const saved = await api<SupportMessage>(`/admin/support/conversations/${activeId}/reply`, {
        method: "POST",
        body: { message: content },
      });
      setThread((prev) =>
        prev
          ? {
              ...prev,
              status: prev.status === "AI_HANDLING" ? "ESCALATED" : prev.status,
              messages: (prev.messages ?? []).map((msg) => (msg.id === optimistic.id ? saved : msg)),
            }
          : prev,
      );
      await loadList();
    } catch (err) {
      setError(err);
      setThread((prev) =>
        prev ? { ...prev, messages: (prev.messages ?? []).filter((msg) => msg.id !== optimistic.id) } : prev,
      );
      setDraft(content);
    }
  }

  async function resolve() {
    if (!activeId) return;
    try {
      await api(`/admin/support/conversations/${activeId}/resolve`, { method: "POST" });
      await Promise.all([loadList(), loadThread(activeId)]);
    } catch (err) {
      setError(err);
    }
  }

  const lastPreview = useMemo(() => {
    const map = new Map<string, string>();
    for (const item of items) {
      const last = item.messages?.[0];
      if (last) map.set(item.id, last.content);
    }
    return map;
  }, [items]);

  return (
    <div className="-m-5 flex h-[calc(100%+2.5rem)] min-h-[540px] overflow-hidden">
      <aside className="flex w-80 shrink-0 flex-col border-r border-border bg-white">
        <div className="border-b border-border p-3">
          <h1 className="text-lg font-semibold">Support</h1>
          <div className="mt-2 flex flex-wrap gap-1">
            {TABS.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => setTab(item.id)}
                className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${
                  tab === item.id ? "bg-teal text-white" : "bg-field text-muted"
                }`}
              >
                {item.label}
              </button>
            ))}
          </div>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto">
          {items.length === 0 ? <EmptyState message="No conversations in this queue." /> : null}
          {items.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => setActiveId(item.id)}
              className={`block w-full border-b border-border px-3 py-3 text-left ${
                item.id === activeId ? "bg-accent-soft" : "hover:bg-field"
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <p className="truncate text-sm font-semibold">{displayName(item.user)}</p>
                <StatusBadge value={item.status} />
              </div>
              <p className="mt-1 truncate text-xs text-muted">
                {lastPreview.get(item.id) || formatPhone(item.user?.phone)}
              </p>
            </button>
          ))}
        </div>
      </aside>

      <section className="flex min-w-0 flex-1 flex-col bg-[#f7fbfc]">
        {thread ? (
          <>
            <header className="flex items-center justify-between border-b border-border bg-white px-4 py-3">
              <div>
                <p className="text-sm font-semibold">{displayName(thread.user)}</p>
                <p className="text-xs text-muted">{formatPhone(thread.user?.phone)}</p>
              </div>
              <button
                type="button"
                onClick={() => void resolve()}
                className="rounded-md border border-border px-3 py-1.5 text-xs font-semibold text-teal"
              >
                Mark resolved
              </button>
            </header>
            <div className="min-h-0 flex-1 space-y-2 overflow-y-auto p-4">
              <ErrorText error={error} />
              {messages.map((message) => (
                <MessageBubble key={message.id} message={message} />
              ))}
              <div ref={bottomRef} />
            </div>
            <form onSubmit={(e) => void send(e)} className="flex gap-2 border-t border-border bg-white p-3">
              <input
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                placeholder="Reply as agent…"
                className="flex-1 rounded-md border border-border bg-field px-3 py-2 text-sm outline-none focus:border-teal"
              />
              <button type="submit" className="rounded-md bg-teal px-4 py-2 text-sm font-semibold text-white">
                Send
              </button>
            </form>
          </>
        ) : (
          <div className="flex flex-1 items-center justify-center text-sm text-muted">
            Select a conversation
          </div>
        )}
      </section>
    </div>
  );
}

function MessageBubble({ message }: { message: SupportMessage }) {
  const tone =
    message.sender === "AGENT"
      ? "ml-auto bg-teal text-white"
      : message.sender === "AI"
        ? "bg-accent-soft text-teal-dark"
        : "bg-white text-navy border border-border";
  return (
    <div className={`max-w-[80%] rounded-xl px-3 py-2 text-sm ${tone}`}>
      <div className="mb-1 flex items-center justify-between gap-3 text-[10px] uppercase tracking-wide opacity-80">
        <span>{message.sender === "AI" ? "AI assistant" : message.sender === "AGENT" ? "Agent" : "User"}</span>
        <span>{formatDateTime(message.createdAt)}</span>
      </div>
      <p className="whitespace-pre-wrap">{message.content}</p>
    </div>
  );
}
