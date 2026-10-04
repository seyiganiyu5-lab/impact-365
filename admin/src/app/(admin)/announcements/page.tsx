"use client";

import { useEffect, useState } from "react";
import { Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { CONTENT_LANGS, useI18n, type ContentLang } from "@/lib/i18n";
import { Empty, ErrorText, Loading, PageHeader, formatDateTime } from "@/components/ui";

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
      <div className="grid gap-6 lg:grid-cols-[380px_1fr]">
        <form onSubmit={publish} className="card h-fit space-y-4">
          <h2 className="font-bold">{t.announcements.newAnnouncement}</h2>
          <div>
            <label className="label">{t.announcements.titleField}</label>
            <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div>
            <label className="label">{t.announcements.body}</label>
            <textarea rows={5} className="input" value={body} onChange={(e) => setBody(e.target.value)} />
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
          <ErrorText message={error} />
          <button type="submit" disabled={busy || !title.trim() || !body.trim()} className="btn-gold w-full">
            {t.announcements.publish}
          </button>
        </form>
        <div className="space-y-3">
          {rows === null ? (
            <Loading />
          ) : rows.length === 0 ? (
            <Empty />
          ) : (
            rows.map((a) => (
              <div key={a.id} className="card flex gap-4">
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-semibold">{a.title}</span>
                    <span className="badge bg-lavender text-purple">{a.lang ? t.langs[a.lang] : t.announcements.everyone}</span>
                    <span className="text-xs text-muted">{formatDateTime(a.created_at, lang)}</span>
                  </div>
                  <p className="mt-1 whitespace-pre-wrap text-sm text-muted">{a.body}</p>
                </div>
                <button onClick={() => remove(a.id)} className="btn-danger h-fit px-2.5 py-1.5" aria-label={t.common.delete}>
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  );
}
