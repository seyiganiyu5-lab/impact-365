"use client";

import { useEffect, useState } from "react";
import { Megaphone, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { CONTENT_LANGS, useI18n, type ContentLang } from "@/lib/i18n";
import { Chip, Empty, ErrorText, Loading, PageHeader, formatRelative } from "@/components/ui";

type Announcement = {
  id: string;
  title: string;
  body: string;
  lang: ContentLang | null;
  created_at: string;
};

async function fetchAnnouncements() {
  const { data } = await supabase()
    .from("announcements")
    .select("id, title, body, lang, created_at")
    .order("created_at", { ascending: false });
  return (data as Announcement[]) ?? [];
}

export default function AnnouncementsPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [rows, setRows] = useState<Announcement[] | null>(null);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [audience, setAudience] = useState<ContentLang | "">("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [reload, setReload] = useState(0);
  const load = () => setReload((n) => n + 1);

  useEffect(() => {
    fetchAnnouncements().then(setRows);
  }, [reload]);

  async function publish(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;
    setBusy(true);
    setError(null);
    const { error } = await supabase().from("announcements").insert({
      title: title.trim(),
      body: body.trim(),
      lang: audience || null,
      created_by: staff.id,
    });
    setBusy(false);
    if (error) return setError(error.message);
    setTitle("");
    setBody("");
    load();
  }

  async function remove(id: string) {
    if (!confirm(t.common.confirmDelete)) return;
    await supabase().from("announcements").delete().eq("id", id);
    load();
  }

  return (
    <>
      <PageHeader title={t.announcements.title} subtitle={t.announcements.subtitle} />
      <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-[400px_1fr]">
        <form onSubmit={publish} className="card space-y-4 p-5 lg:sticky lg:top-6">
          <h2 className="flex items-center gap-2 font-bold text-purple">
            <Megaphone className="h-5 w-5 text-gold" /> {t.announcements.newAnnouncement}
          </h2>
          <div>
            <label className="label">{t.announcements.titleField}</label>
            <input className="input" maxLength={120} value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div>
            <label className="label">{t.announcements.body}</label>
            <textarea rows={5} className="input" maxLength={2000} value={body} onChange={(e) => setBody(e.target.value)} />
          </div>
          <div>
            <label className="label">{t.announcements.audience}</label>
            <select className="input" value={audience} onChange={(e) => setAudience(e.target.value as ContentLang | "")}>
              <option value="">{t.announcements.everyone}</option>
              {CONTENT_LANGS.map((l) => (
                <option key={l} value={l}>{t.langs[l]}</option>
              ))}
            </select>
          </div>

          {/* Same look as the "Notifications" tab of the app */}
          <div>
            <div className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">{t.ui.preview}</div>
            <div className="rounded-2xl bg-cream p-3">
              <div className="flex gap-3 rounded-2xl border border-line bg-white p-3.5">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-lavender text-lg">📣</span>
                <div className="min-w-0">
                  <div className={`font-bold ${title.trim() ? "text-ink" : "text-muted/60"}`}>
                    {title.trim() || t.ui.previewTitle}
                  </div>
                  <p className={`mt-0.5 whitespace-pre-wrap text-sm ${body.trim() ? "text-muted" : "text-muted/50"}`}>
                    {body.trim() || t.ui.previewBody}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <ErrorText message={error} />
          <button type="submit" disabled={busy || !title.trim() || !body.trim()} className="btn-gold w-full py-3">
            {busy ? t.common.saving : t.announcements.publish}
          </button>
        </form>

        <div className="space-y-3">
          {rows === null ? (
            <Loading />
          ) : rows.length === 0 ? (
            <Empty emoji="📣" />
          ) : (
            rows.map((a) => (
              <article key={a.id} className="card flex gap-4 p-5">
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-lavender text-xl">📣</span>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="font-bold text-ink">{a.title}</h3>
                    <Chip tone={a.lang ? "purple" : "gold"}>{a.lang ? t.langs[a.lang] : t.announcements.everyone}</Chip>
                  </div>
                  <p className="mt-1 whitespace-pre-wrap text-sm leading-relaxed text-muted">{a.body}</p>
                  <div className="mt-2 text-xs text-muted">{formatRelative(a.created_at, lang, t.ui.yesterday)}</div>
                </div>
                <button
                  onClick={() => remove(a.id)}
                  className="h-fit cursor-pointer rounded-lg p-2 text-muted transition hover:bg-red-50 hover:text-red-700"
                  aria-label={t.common.delete}
                  title={t.common.delete}
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </article>
            ))
          )}
        </div>
      </div>
    </>
  );
}
