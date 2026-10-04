"use client";

import { useEffect, useState } from "react";
import { HandHeart, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Empty, Loading, PageHeader, formatDateTime } from "@/components/ui";

type Prayer = {
  id: string;
  title: string;
  details: string | null;
  is_anonymous: boolean;
  is_answered: boolean;
  testimony: string | null;
  created_at: string;
  member: { full_name: string | null } | null;
  prayer_intercessions: { count: number }[];
};

async function fetchPrayers() {
  const { data } = await supabase()
    .from("prayer_requests")
    .select(
      "id, title, details, is_anonymous, is_answered, testimony, created_at, " +
        "member:profiles!prayer_requests_user_id_fkey(full_name), prayer_intercessions(count)",
    )
    .eq("is_shared", true)
    .order("created_at", { ascending: false })
    .limit(200);
  return (data as unknown as Prayer[]) ?? [];
}

export default function PrayersPage() {
  const { t, lang } = useI18n();
  const [rows, setRows] = useState<Prayer[] | null>(null);

  const [reload, setReload] = useState(0);
  const load = () => setReload((n) => n + 1);

  useEffect(() => {
    fetchPrayers().then(setRows);
  }, [reload]);

  async function remove(id: string) {
    if (!confirm(t.common.confirmDelete)) return;
    await supabase().from("prayer_requests").delete().eq("id", id);
    load();
  }

  return (
    <>
      <PageHeader title={t.prayers.title} subtitle={t.prayers.subtitle} />
      {rows === null ? (
        <Loading />
      ) : rows.length === 0 ? (
        <Empty />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {rows.map((p) => (
            <div key={p.id} className="card space-y-2">
              <div className="flex items-center gap-2 text-xs text-muted">
                <span className="font-semibold text-ink">{p.member?.full_name}</span>
                {p.is_anonymous && <span className="badge bg-beige">{t.common.anonymous}</span>}
                {p.is_answered && <span className="badge bg-green-100 text-green-800">{t.prayers.answered}</span>}
                <span className="ml-auto">{formatDateTime(p.created_at, lang)}</span>
              </div>
              <div className="font-semibold">{p.title}</div>
              {p.details && <p className="text-sm text-muted">{p.details}</p>}
              {p.testimony && (
                <p className="rounded-lg bg-cream p-3 text-sm">
                  <span className="font-semibold text-gold">{t.prayers.testimony}: </span>
                  {p.testimony}
                </p>
              )}
              <div className="flex items-center justify-between pt-1">
                <span className="flex items-center gap-1.5 text-sm text-muted">
                  <HandHeart className="h-4 w-4 text-gold" />
                  {p.prayer_intercessions[0]?.count ?? 0} {t.prayers.intercessions}
                </span>
                <button onClick={() => remove(p.id)} className="btn-danger px-2.5 py-1.5" aria-label={t.common.delete}>
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
