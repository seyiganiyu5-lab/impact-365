"use client";

import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Lock, RotateCcw, Search, Send, UserCheck, CheckCircle2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { useI18n } from "@/lib/i18n";
import { Avatar, Chip, Empty, Loading, PageHeader, Segmented, formatRelative } from "@/components/ui";

type Conversation = {
  id: string;
  subject: string;
  status: "open" | "closed";
  last_message_at: string;
  assigned_to: string | null;
  member: { full_name: string | null; avatar_url: string | null } | null;
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
        "member:profiles!conversations_user_id_fkey(full_name, avatar_url), " +
        "assignee:profiles!conversations_assigned_to_fkey(full_name), " +
        "messages(is_from_staff, created_at)",
    )
    .eq("status", status)
    .order("last_message_at", { ascending: false });
  return (data as unknown as Conversation[]) ?? [];
}

/** The latest message came from the member: a leader should answer. */
function isWaiting(c: Conversation) {
  const last = [...c.messages].sort((a, b) => a.created_at.localeCompare(b.created_at)).at(-1);
  return !!last && !last.is_from_staff;
}

export default function ConcernsPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [filter, setFilter] = useState<"open" | "closed">("open");
  const [conversations, setConversations] = useState<Conversation[] | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [search, setSearch] = useState("");

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
  const q = search.trim().toLowerCase();
  const shown = (conversations ?? []).filter(
    (c) => !q || c.subject.toLowerCase().includes(q) || (c.member?.full_name ?? "").toLowerCase().includes(q),
  );
  const waitingCount = (conversations ?? []).filter(isWaiting).length;

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
      <div className={selected ? "hidden lg:block" : ""}>
        <PageHeader title={t.concerns.title} subtitle={t.concerns.subtitle} />
      </div>
      <div className="grid grid-cols-1 gap-5 lg:h-[calc(100vh-15rem)] lg:min-h-[520px] lg:grid-cols-[360px_1fr]">
        {/* List */}
        <div className={`flex min-h-0 flex-col gap-3 ${selected ? "hidden lg:flex" : ""}`}>
          <Segmented
            value={filter}
            onChange={(f) => {
              setFilter(f);
              setSelectedId(null);
            }}
            options={[
              { value: "open", label: t.concerns.open, count: filter === "open" ? waitingCount : undefined },
              { value: "closed", label: t.concerns.closed },
            ]}
          />
          <label className="relative block">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
            <input
              className="input pl-10"
              placeholder={t.ui.search}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </label>
          <div className="min-h-0 flex-1 overflow-y-auto rounded-2xl bg-white shadow-[0_6px_18px_rgba(59,30,123,0.06)]">
            {conversations === null ? (
              <div className="p-3">
                <Loading />
              </div>
            ) : shown.length === 0 ? (
              <div className="p-10 text-center text-sm text-muted">💬 {t.common.empty}</div>
            ) : (
              shown.map((c) => {
                const waiting = isWaiting(c);
                const active = selectedId === c.id;
                return (
                  <button
                    key={c.id}
                    onClick={() => setSelectedId(c.id)}
                    className={`flex w-full cursor-pointer items-start gap-3 border-b border-line/70 px-4 py-3.5 text-left transition last:border-0 ${
                      active ? "bg-lavender" : "hover:bg-cream"
                    }`}
                  >
                    <Avatar name={c.member?.full_name} url={c.member?.avatar_url} size={44} />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-baseline justify-between gap-2">
                        <span className={`truncate ${waiting ? "font-bold" : "font-semibold"} text-ink`}>
                          {c.member?.full_name ?? "—"}
                        </span>
                        <span className={`shrink-0 text-xs ${waiting ? "font-semibold text-[#9a7a17]" : "text-muted"}`}>
                          {formatRelative(c.last_message_at, lang, t.ui.yesterday)}
                        </span>
                      </div>
                      <div className="mt-0.5 flex items-center gap-2">
                        <span className={`truncate text-sm ${waiting ? "text-ink" : "text-muted"}`}>{c.subject}</span>
                        {waiting && <span className="ml-auto h-2.5 w-2.5 shrink-0 rounded-full bg-gold" />}
                      </div>
                      <div className="mt-1 text-xs text-muted">
                        {waiting
                          ? t.ui.waiting
                          : c.assigned_to === staff.id
                            ? t.ui.assignedToMe
                            : c.assignee?.full_name
                              ? `${t.concerns.assignedTo} ${c.assignee.full_name}`
                              : t.concerns.unassigned}
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Thread */}
        {selected ? (
          <Thread
            key={selected.id}
            conversation={selected}
            onBack={() => setSelectedId(null)}
            onClose={() => setStatus(selected, selected.status === "open" ? "closed" : "open")}
            onAssign={() => assignMe(selected)}
          />
        ) : (
          <div className="hidden lg:block">
            <Empty emoji="💬">{t.concerns.select}</Empty>
          </div>
        )}
      </div>
    </>
  );
}

function dayKey(iso: string) {
  const d = new Date(iso);
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}

function dayLabel(iso: string, lang: string, today: string, yesterday: string) {
  const d = new Date(iso);
  const now = new Date();
  const start = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diff = Math.round((start(now) - start(d)) / 86_400_000);
  if (diff === 0) return today;
  if (diff === 1) return yesterday;
  return d.toLocaleDateString(lang === "fr" ? "fr-FR" : "en-GB", { weekday: "long", day: "numeric", month: "long" });
}

function Thread({
  conversation,
  onBack,
  onClose,
  onAssign,
}: {
  conversation: Conversation;
  onBack: () => void;
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

  // Braces: effects must not return the value of scrollIntoView (newer
  // browsers return a Promise, which React would try to call on cleanup).
  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [messages.length]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    const body = reply.trim();
    if (!body || sending) return;
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

  const closed = conversation.status === "closed";

  return (
    <div className="flex h-[calc(100vh-7rem)] min-h-[480px] flex-col overflow-hidden rounded-2xl bg-white shadow-[0_6px_18px_rgba(59,30,123,0.06)] lg:h-full">
      {/* Header */}
      <div className="flex items-center gap-3 border-b border-line px-4 py-3">
        <button
          onClick={onBack}
          className="cursor-pointer rounded-full border border-line p-2 text-purple lg:hidden"
          aria-label={t.ui.allConversations}
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <Avatar name={conversation.member?.full_name} url={conversation.member?.avatar_url} size={42} />
        <div className="min-w-0 flex-1">
          <div className="truncate font-bold text-ink">{conversation.member?.full_name ?? "—"}</div>
          <div className="truncate text-xs text-muted">{conversation.subject}</div>
        </div>
        <div className="flex shrink-0 flex-wrap justify-end gap-2">
          {conversation.assigned_to !== staff.id && !closed && (
            <button onClick={onAssign} className="btn-ghost min-h-10 px-3 py-2" title={t.concerns.assignMe}>
              <UserCheck className="h-4 w-4" />
              <span className="hidden sm:inline">{t.concerns.assignMe}</span>
            </button>
          )}
          <button onClick={onClose} className="btn-ghost min-h-10 px-3 py-2" title={closed ? t.concerns.reopen : t.concerns.close}>
            {closed ? <RotateCcw className="h-4 w-4" /> : <CheckCircle2 className="h-4 w-4" />}
            <span className="hidden sm:inline">{closed ? t.concerns.reopen : t.concerns.close}</span>
          </button>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 space-y-1 overflow-y-auto bg-cream px-4 py-4">
        <div className="mb-3 flex justify-center">
          <Chip tone="gold" icon={<Lock className="h-3 w-3" />}>
            {t.ui.privateThread}
          </Chip>
        </div>
        {messages.map((m, i) => {
          const prev = messages[i - 1];
          const next = messages[i + 1];
          const newDay = !prev || dayKey(prev.created_at) !== dayKey(m.created_at);
          const mine = m.is_from_staff;
          const endOfGroup = !next || next.is_from_staff !== m.is_from_staff || dayKey(next.created_at) !== dayKey(m.created_at);
          return (
            <div key={m.id}>
              {newDay && (
                <div className="my-3 flex justify-center">
                  <span className="rounded-full bg-lavender px-3 py-1 text-xs font-semibold text-purple first-letter:uppercase">
                    {dayLabel(m.created_at, lang, t.ui.today, t.ui.yesterday)}
                  </span>
                </div>
              )}
              <div className={`flex ${mine ? "justify-end" : "justify-start"} ${endOfGroup ? "mb-3" : "mb-0.5"}`}>
                <div
                  className={`max-w-[78%] rounded-2xl px-3.5 py-2 text-[15px] leading-relaxed ${
                    mine
                      ? `bg-purple text-white ${endOfGroup ? "rounded-br-md" : ""}`
                      : `border border-line bg-white text-ink ${endOfGroup ? "rounded-bl-md" : ""}`
                  }`}
                >
                  {mine && m.sender_id !== staff.id && (
                    <div className="mb-0.5 text-[11px] font-semibold text-gold">{t.concerns.leader}</div>
                  )}
                  <div className="whitespace-pre-wrap">{m.body}</div>
                  <div className={`mt-0.5 text-right text-[11px] ${mine ? "text-white/65" : "text-muted"}`}>
                    {new Date(m.created_at).toLocaleTimeString(lang === "fr" ? "fr-FR" : "en-GB", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
        <div ref={bottom} />
      </div>

      {/* Composer */}
      {closed ? (
        <div className="border-t border-line bg-beige px-4 py-3 text-center text-sm text-muted">{t.concerns.closed}</div>
      ) : (
        <form onSubmit={send} className="flex items-end gap-2 border-t border-line bg-white p-3">
          <textarea
            rows={1}
            className="max-h-40 min-h-11 flex-1 resize-none rounded-3xl border border-line bg-cream px-4 py-2.5 text-[15px] outline-none focus:border-purple focus:bg-white"
            placeholder={t.concerns.reply}
            value={reply}
            onChange={(e) => setReply(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) send(e);
            }}
          />
          <button
            type="submit"
            disabled={sending || !reply.trim()}
            aria-label={t.concerns.send}
            className="flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full bg-gold text-white transition hover:brightness-95 disabled:cursor-not-allowed disabled:opacity-45"
          >
            <Send className="h-5 w-5" />
          </button>
        </form>
      )}
    </div>
  );
}
