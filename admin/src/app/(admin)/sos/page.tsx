"use client";

import { useEffect, useState } from "react";
import { EyeOff, Lock } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Empty, Loading, PageHeader, formatDateTime } from "@/components/ui";

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
  member: { full_name: string | null; phone: string | null } | null;
  help_offers: { id: string; message: string; created_at: string; helper: { full_name: string | null } | null }[];
};

const STATUS_STYLE: Record<Status, string> = {
  open: "bg-lavender text-purple",
  in_progress: "bg-gold-light/60 text-[#a8871f]",
  resolved: "bg-green-100 text-green-800",
};

async function fetchRequests(filter: Status | "all") {
  let q = supabase()
    .from("help_requests")
    .select(
      "id, category, description, is_anonymous, leaders_only, status, staff_note, created_at, " +
        "member:profiles!help_requests_user_id_fkey(full_name, phone), " +
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
      <div className="mb-4 inline-flex flex-wrap rounded-xl bg-white p-1 shadow-sm">
        {(["open", "in_progress", "resolved", "all"] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`cursor-pointer rounded-lg px-4 py-1.5 text-sm font-semibold ${filter === f ? "bg-purple text-white" : "text-muted"}`}
          >
            {f === "all" ? t.common.all : t.sos.status[f]}
          </button>
        ))}
      </div>
      {rows === null ? (
        <Loading />
      ) : rows.length === 0 ? (
        <Empty />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
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
  onPatch: (v: Partial<Pick<HelpRequest, "status" | "staff_note">>) => void;
}) {
  const { t } = useI18n();
  const [note, setNote] = useState(r.staff_note ?? "");

  return (
    <div className="card space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <span className="badge bg-purple text-white">{t.sos.categories[r.category]}</span>
        <span className={`badge ${STATUS_STYLE[r.status]}`}>{t.sos.status[r.status]}</span>
        {r.leaders_only && (
          <span className="badge bg-red-50 text-red-700"><Lock className="mr-1 h-3 w-3" />{t.sos.leadersOnly}</span>
        )}
        {r.is_anonymous && (
          <span className="badge bg-beige text-muted"><EyeOff className="mr-1 h-3 w-3" />{t.sos.anonymousToCommunity}</span>
        )}
        <span className="ml-auto text-xs text-muted">{formatDateTime(r.created_at, lang)}</span>
      </div>
      <div className="text-sm font-semibold">
        {r.member?.full_name}
        {r.member?.phone && <span className="ml-2 font-normal text-muted">{r.member.phone}</span>}
      </div>
      <p className="whitespace-pre-wrap text-sm">{r.description}</p>

      <div>
        <div className="mb-1 text-xs font-semibold text-muted">{t.sos.offers}</div>
        {r.help_offers.length === 0 ? (
          <div className="text-xs text-muted">{t.sos.noOffers}</div>
        ) : (
          <ul className="space-y-1 text-sm">
            {r.help_offers.map((o) => (
              <li key={o.id} className="rounded-lg bg-cream px-3 py-2">
                <span className="font-semibold">{o.helper?.full_name ?? t.common.anonymous}:</span> {o.message}
              </li>
            ))}
          </ul>
        )}
      </div>

      <div>
        <label className="label text-xs">{t.sos.note}</label>
        <textarea rows={2} className="input" placeholder={t.sos.notePh} value={note} onChange={(e) => setNote(e.target.value)} />
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <select
          className="input w-auto"
          value={r.status}
          onChange={(e) => onPatch({ status: e.target.value as Status })}
        >
          {(["open", "in_progress", "resolved"] as const).map((s) => (
            <option key={s} value={s}>{t.sos.status[s]}</option>
          ))}
        </select>
        <button
          className="btn-primary ml-auto"
          disabled={note === (r.staff_note ?? "")}
          onClick={() => onPatch({ staff_note: note.trim() || null })}
        >
          {t.common.save}
        </button>
      </div>
    </div>
  );
}
