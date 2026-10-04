"use client";

import { useEffect, useRef, useState } from "react";
import { Lock, Send } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { useI18n } from "@/lib/i18n";
import { Empty, Loading, PageHeader, formatDateTime } from "@/components/ui";

type Conversation = {
  id: string;
  subject: string;
  status: "open" | "closed";
  last_message_at: string;
  assigned_to: string | null;
  member: { full_name: string | null } | null;
  assignee: { full_name: string | null } | null;
  messages: { is_from_staff: boolean; created_at: string }[];
};

type Message = {
  id: string;
  body: string;
  sender_id: string;
  is_from_staff: boolean;
  created_at: string;
};

async function fetchConversations(status: "open" | "closed") {
  const { data } = await supabase()
    .from("conversations")
    .select(
      "id, subject, status, last_message_at, assigned_to, " +
        "member:profiles!conversations_user_id_fkey(full_name), " +
        "assignee:profiles!conversations_assigned_to_fkey(full_name), " +
        "messages(is_from_staff, created_at)",
    )
    .eq("status", status)
    .order("last_message_at", { ascending: false });
  return (data as unknown as Conversation[]) ?? [];
}

export default function ConcernsPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [filter, setFilter] = useState<"open" | "closed">("open");
  const [conversations, setConversations] = useState<Conversation[] | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const [reload, setReload] = useState(0);
  const load = () => setReload((n) => n + 1);

  useEffect(() => {
    fetchConversations(filter).then(setConversations);
  }, [filter, reload]);

  useEffect(() => {
    // Refresh the list whenever any conversation changes (a new message bumps it).
    const channel = supabase()
      .channel("conversations-list")
      .on("postgres_changes", { event: "*", schema: "public", table: "conversations" }, () =>
        setReload((n) => n + 1),
      )
      .subscribe();
    return () => {
      supabase().removeChannel(channel);
    };
  }, []);

  const selected = conversations?.find((c) => c.id === selectedId) ?? null;

  async function setStatus(c: Conversation, status: "open" | "closed") {
    await supabase().from("conversations").update({ status }).eq("id", c.id);
    setSelectedId(null);
    load();
  }

  async function assignMe(c: Conversation) {
    await supabase().from("conversations").update({ assigned_to: staff.id }).eq("id", c.id);
    load();
  }

  return (
    <>
      <PageHeader title={t.concerns.title} subtitle={t.concerns.subtitle} />
      <div className="grid gap-4 lg:grid-cols-[340px_1fr]">
        <div className="space-y-3">
          <div className="inline-flex rounded-xl bg-white p-1 shadow-sm">
            {(["open", "closed"] as const).map((f) => (
              <button
                key={f}
                onClick={() => {
                  setFilter(f);
                  setSelectedId(null);
                }}
                className={`cursor-pointer rounded-lg px-4 py-1.5 text-sm font-semibold ${filter === f ? "bg-purple text-white" : "text-muted"}`}
              >
                {t.concerns[f]}
              </button>
            ))}
          </div>
          {conversations === null ? (
            <Loading />
          ) : conversations.length === 0 ? (
            <Empty />
          ) : (
            conversations.map((c) => {
              // Waiting for a reply = the latest message came from the member.
              const last = [...c.messages].sort((a, b) => a.created_at.localeCompare(b.created_at)).at(-1);
              const unread = !!last && !last.is_from_staff;
              return (
                <button
                  key={c.id}
                  onClick={() => setSelectedId(c.id)}
                  className={`card block w-full cursor-pointer p-4 text-left transition ${selectedId === c.id ? "ring-2 ring-purple" : "hover:bg-lavender"}`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="truncate font-semibold">{c.member?.full_name ?? "—"}</span>
                    <span className="shrink-0 text-xs text-muted">{formatDateTime(c.last_message_at, lang)}</span>
                  </div>
                  <div className="mt-0.5 flex items-center gap-2">
                    <span className="truncate text-sm text-muted">{c.subject}</span>
                    {unread && <span className="ml-auto h-2.5 w-2.5 shrink-0 rounded-full bg-gold" />}
                  </div>
                  <div className="mt-1 text-xs text-muted">
                    {c.assignee?.full_name ? `${t.concerns.assignedTo} ${c.assignee.full_name}` : t.concerns.unassigned}
                  </div>
                </button>
              );
            })
          )}
        </div>

        {selected ? (
          <Thread
            key={selected.id}
            conversation={selected}
            onClose={() => setStatus(selected, selected.status === "open" ? "closed" : "open")}
            onAssign={() => assignMe(selected)}
          />
        ) : (
          <div className="card hidden items-center justify-center text-muted lg:flex">{t.concerns.select}</div>
        )}
      </div>
    </>
  );
}

function Thread({
  conversation,
  onClose,
  onAssign,
}: {
  conversation: Conversation;
  onClose: () => void;
  onAssign: () => void;
}) {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [messages, setMessages] = useState<Message[]>([]);
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);
  const bottom = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const db = supabase();
    db.from("messages")
      .select("id, body, sender_id, is_from_staff, created_at")
      .eq("conversation_id", conversation.id)
      .order("created_at")
      .then(({ data }) => setMessages((data as Message[]) ?? []));

    const channel = db
      .channel(`messages-${conversation.id}`)
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "messages", filter: `conversation_id=eq.${conversation.id}` },
        (payload) =>
          setMessages((prev) =>
            prev.some((m) => m.id === payload.new.id) ? prev : [...prev, payload.new as Message],
          ),
      )
      .subscribe();
    return () => {
      db.removeChannel(channel);
    };
  }, [conversation.id]);

  useEffect(() => bottom.current?.scrollIntoView({ behavior: "smooth" }), [messages.length]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    const body = reply.trim();
    if (!body) return;
    setSending(true);
    const { data, error } = await supabase()
      .from("messages")
      .insert({ conversation_id: conversation.id, sender_id: staff.id, body })
      .select("id, body, sender_id, is_from_staff, created_at")
      .single();
    setSending(false);
    if (!error && data) {
      setReply("");
      setMessages((prev) => (prev.some((m) => m.id === data.id) ? prev : [...prev, data as Message]));
    }
  }

  return (
    <div className="card flex h-[70vh] flex-col p-0">
      <div className="flex flex-wrap items-center gap-3 border-b border-line p-4">
        <div className="min-w-0 flex-1">
          <div className="truncate font-bold">{conversation.subject}</div>
          <div className="text-xs text-muted">{conversation.member?.full_name}</div>
        </div>
        {conversation.assigned_to !== staff.id && (
          <button onClick={onAssign} className="btn-ghost py-1.5">{t.concerns.assignMe}</button>
        )}
        <button onClick={onClose} className="btn-ghost py-1.5">
          {conversation.status === "open" ? t.concerns.close : t.concerns.reopen}
        </button>
      </div>
      <div className="flex-1 space-y-3 overflow-y-auto bg-cream p-4">
        {messages.map((m) => (
          <div key={m.id} className={`flex ${m.is_from_staff ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-[80%] rounded-2xl px-4 py-2.5 text-sm ${
                m.is_from_staff ? "rounded-br-sm bg-purple text-white" : "rounded-bl-sm border border-line bg-white"
              }`}
            >
              <div className={`mb-0.5 text-[11px] font-semibold ${m.is_from_staff ? "text-gold" : "text-purple"}`}>
                {m.is_from_staff ? (m.sender_id === staff.id ? staff.full_name : t.concerns.leader) : t.concerns.member}
              </div>
              <div className="whitespace-pre-wrap">{m.body}</div>
              <div className={`mt-1 text-right text-[10px] ${m.is_from_staff ? "text-white/60" : "text-muted"}`}>
                {formatDateTime(m.created_at, lang)}
              </div>
            </div>
          </div>
        ))}
        <div ref={bottom} />
      </div>
      <form onSubmit={send} className="flex items-end gap-2 border-t border-line p-3">
        <Lock className="mb-3 h-4 w-4 shrink-0 text-muted" />
        <textarea
          rows={2}
          className="input resize-none"
          placeholder={t.concerns.reply}
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) send(e);
          }}
        />
        <button type="submit" disabled={sending || !reply.trim()} className="btn-primary">
          <Send className="h-4 w-4" /> {t.concerns.send}
        </button>
      </form>
    </div>
  );
}
