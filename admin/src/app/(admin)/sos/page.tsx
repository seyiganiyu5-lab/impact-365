"use client";

import { useEffect, useState } from "react";
import { EyeOff, HeartHandshake, Lock, MessageSquareText, Phone } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Avatar, Chip, Empty, Loading, PageHeader, SOS_EMOJI, Segmented, formatRelative } from "@/components/ui";

type Status = "open" | "in_progress" | "resolved";
type Category = "prayer" | "financial" | "health" | "emotional" | "studies_work" | "other";

type HelpRequest = {
  id: string;
  category: Category;
  description: string;
  is_anonymous: boolean;
  leaders_only: boolean;
  status: Status;
  staff_note: string | null;
  created_at: string;
  member: { full_name: string | null; phone: string | null; avatar_url: string | null } | null;
  help_offers: { id: string; message: string; created_at: string; helper: { full_name: string | null } | null }[];
};

const STATUS_TONE = { open: "gold", in_progress: "purple", resolved: "green" } as const;

async function fetchRequests(filter: Status | "all") {
  let q = supabase()
    .from("help_requests")
    .select(
      "id, category, description, is_anonymous, leaders_only, status, staff_note, created_at, " +
        "member:profiles!help_requests_user_id_fkey(full_name, phone, avatar_url), " +
        "help_offers(id, message, created_at, helper:profiles!help_offers_helper_id_fkey(full_name))",
    )
    .order("created_at", { ascending: false });
  if (filter !== "all") q = q.eq("status", filter);
  const { data } = await q;
  return (data as unknown as HelpRequest[]) ?? [];
}

export default function SosPage() {
  const { t, lang } = useI18n();
  const [filter, setFilter] = useState<Status | "all">("open");
  const [rows, setRows] = useState<HelpRequest[] | null>(null);

  const [reload, setReload] = useState(0);
  const load = () => setReload((n) => n + 1);

  useEffect(() => {
    fetchRequests(filter).then(setRows);
  }, [filter, reload]);

  async function patch(id: string, values: Partial<Pick<HelpRequest, "status" | "staff_note">>) {
    await supabase()
      .from("help_requests")
      .update({ ...values, updated_at: new Date().toISOString() })
      .eq("id", id);
    load();
  }

  return (
    <>
      <PageHeader title={t.sos.title} subtitle={t.sos.subtitle} />
      <div className="mb-5">
        <Segmented
          value={filter}
          onChange={setFilter}
          options={(["open", "in_progress", "resolved", "all"] as const).map((f) => ({
            value: f,
            label: f === "all" ? t.common.all : t.sos.status[f],
            count: f === filter && f === "open" ? rows?.length : undefined,
          }))}
        />
      </div>
      {rows === null ? (
        <Loading />
      ) : rows.length === 0 ? (
        <Empty emoji="🌿" />
      ) : (
        <div className="grid grid-cols-1 gap-5 xl:grid-cols-2">
          {rows.map((r) => (
            <SosCard key={r.id} r={r} lang={lang} onPatch={(v) => patch(r.id, v)} />
          ))}
        </div>
      )}
    </>
  );
}

function SosCard({
  r,
  lang,
  onPatch,
}: {
  r: HelpRequest;
  lang: string;
  onPatch: (v: Partial<Pick<HelpRequest, "status" | "staff_note">>) => Promise<void> | void;
}) {
  const { t } = useI18n();
  const [note, setNote] = useState(r.staff_note ?? "");
  const [saved, setSaved] = useState(false);
  const dirty = note.trim() !== (r.staff_note ?? "");

  async function saveNote() {
    await onPatch({ staff_note: note.trim() || null });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  }

  return (
    <article className="card flex flex-col gap-4 p-5">
      {/* Category + status */}
      <div className="flex items-start gap-3">
        <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-lavender text-2xl">
          {SOS_EMOJI[r.category] ?? "✨"}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="font-bold text-purple">{t.sos.categories[r.category]}</h3>
            <Chip tone={STATUS_TONE[r.status]}>{t.sos.status[r.status]}</Chip>
          </div>
          <div className="mt-1 flex flex-wrap gap-1.5">
            {r.leaders_only && (
              <Chip tone="red" icon={<Lock className="h-3 w-3" />}>
                {t.sos.leadersOnly}
              </Chip>
            )}
            {r.is_anonymous && (
              <Chip tone="muted" icon={<EyeOff className="h-3 w-3" />}>
                {t.sos.anonymousToCommunity}
              </Chip>
            )}
          </div>
        </div>
        <span className="shrink-0 text-xs text-muted">{formatRelative(r.created_at, lang, t.ui.yesterday)}</span>
      </div>

      <p className="whitespace-pre-wrap text-[15px] leading-relaxed text-ink">{r.description}</p>

      {/* Member (always visible to leaders, even when anonymous) */}
      <div className="flex flex-wrap items-center gap-3 rounded-xl bg-cream px-3 py-2.5">
        <Avatar name={r.member?.full_name} url={r.member?.avatar_url} size={36} />
        <div className="min-w-[140px] flex-1">
          <div className="truncate text-sm font-semibold">{r.member?.full_name ?? "—"}</div>
          {r.member?.phone && <div className="whitespace-nowrap text-xs text-muted">{r.member.phone}</div>}
        </div>
        {r.member?.phone && (
          <a href={`tel:${r.member.phone.replace(/[^+\d]/g, "")}`} className="btn-ghost ml-auto min-h-10 px-3 py-2">
            <Phone className="h-4 w-4" /> {t.ui.call}
          </a>
        )}
      </div>

      {/* Offers of help */}
      <div>
        <div className="mb-2 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide text-muted">
          <HeartHandshake className="h-4 w-4 text-gold" /> {t.sos.offers} · {r.help_offers.length}
        </div>
        {r.help_offers.length === 0 ? (
          <p className="text-sm text-muted">{t.sos.noOffers}</p>
        ) : (
          <ul className="space-y-2">
            {r.help_offers.map((o) => (
              <li key={o.id} className="rounded-xl border border-line px-3 py-2 text-sm">
                <span className="font-semibold">{o.helper?.full_name ?? t.common.anonymous}</span>
                <span className="text-muted"> · {formatRelative(o.created_at, lang, t.ui.yesterday)}</span>
                <p className="mt-0.5 text-ink">{o.message}</p>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Leader's answer */}
      <div className="space-y-3 border-t border-line pt-4">
        <label className="flex items-center gap-1.5 text-sm font-semibold text-ink">
          <MessageSquareText className="h-4 w-4 text-purple" /> {t.sos.note}
        </label>
        <textarea
          rows={2}
          className="input"
          placeholder={t.sos.notePh}
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="inline-flex rounded-xl border border-line bg-white p-0.5" role="group" aria-label={t.ui.statusLabel}>
            {(["open", "in_progress", "resolved"] as const).map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => s !== r.status && onPatch({ status: s })}
                aria-pressed={r.status === s}
                className={`cursor-pointer rounded-lg px-3 py-2.5 text-xs font-semibold transition ${
                  r.status === s ? "bg-purple text-white" : "text-muted hover:bg-lavender"
                }`}
              >
                {t.sos.status[s]}
              </button>
            ))}
          </div>
          <button className="btn-primary" disabled={!dirty} onClick={saveNote}>
            {saved ? t.common.saved : t.common.save}
          </button>
        </div>
      </div>
    </article>
  );
}
