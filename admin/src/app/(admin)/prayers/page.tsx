"use client";

import { useEffect, useState } from "react";
import { EyeOff, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Avatar, Chip, Empty, Loading, PageHeader, Segmented, formatRelative } from "@/components/ui";

type Prayer = {
  id: string;
  title: string;
  details: string | null;
  is_anonymous: boolean;
  is_answered: boolean;
  testimony: string | null;
  created_at: string;
  member: { full_name: string | null; avatar_url: string | null } | null;
  prayer_intercessions: { count: number }[];
};

async function fetchPrayers() {
  const { data } = await supabase()
    .from("prayer_requests")
    .select(
      "id, title, details, is_anonymous, is_answered, testimony, created_at, " +
        "member:profiles!prayer_requests_user_id_fkey(full_name, avatar_url), prayer_intercessions(count)",
    )
    .eq("is_shared", true)
    .order("created_at", { ascending: false })
    .limit(200);
  return (data as unknown as Prayer[]) ?? [];
}

export default function PrayersPage() {
  const { t, lang } = useI18n();
  const [rows, setRows] = useState<Prayer[] | null>(null);
  const [filter, setFilter] = useState<"ongoing" | "answered" | "all">("ongoing");

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

  const shown = (rows ?? []).filter((p) =>
    filter === "all" ? true : filter === "answered" ? p.is_answered : !p.is_answered,
  );

  return (
    <>
      <PageHeader title={t.prayers.title} subtitle={t.prayers.subtitle} />
      <div className="mb-5">
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { value: "ongoing", label: t.sos.status.in_progress },
            { value: "answered", label: t.prayers.answered },
            { value: "all", label: t.common.all },
          ]}
        />
      </div>
      {rows === null ? (
        <Loading />
      ) : shown.length === 0 ? (
        <Empty emoji="🙏" />
      ) : (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
          {shown.map((p) => (
            <article key={p.id} className="card flex flex-col gap-3 p-5">
              <div className="flex items-center gap-3">
                <Avatar name={p.member?.full_name} url={p.member?.avatar_url} size={38} />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-semibold">{p.member?.full_name ?? "—"}</div>
                  <div className="text-xs text-muted">{formatRelative(p.created_at, lang, t.ui.yesterday)}</div>
                </div>
                {p.is_answered ? (
                  <Chip tone="green">✓ {t.prayers.answered}</Chip>
                ) : (
                  p.is_anonymous && (
                    <Chip tone="muted" icon={<EyeOff className="h-3 w-3" />}>
                      {t.common.anonymous}
                    </Chip>
                  )
                )}
              </div>
              <div>
                <h3 className="font-bold text-ink">{p.title}</h3>
                {p.details && <p className="mt-1 text-sm leading-relaxed text-muted">{p.details}</p>}
              </div>
              {p.testimony && (
                <blockquote className="rounded-xl bg-beige px-4 py-3 text-sm italic text-ink">
                  <span className="mb-1 block text-xs font-bold not-italic text-[#9a7a17]">✨ {t.prayers.testimony}</span>
                  {p.testimony}
                </blockquote>
              )}
              <div className="mt-auto flex items-center justify-between border-t border-line pt-3">
                <span className="flex items-center gap-1.5 text-sm text-muted">
                  🙏 <strong className="text-ink">{p.prayer_intercessions[0]?.count ?? 0}</strong> {t.prayers.intercessions}
                </span>
                <button
                  onClick={() => remove(p.id)}
                  className="cursor-pointer rounded-lg p-2 text-muted transition hover:bg-red-50 hover:text-red-700"
                  aria-label={t.common.delete}
                  title={t.common.delete}
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
    </>
  );
}
