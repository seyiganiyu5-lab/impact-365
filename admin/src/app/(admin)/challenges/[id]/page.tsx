"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { CONTENT_LANGS, useI18n, type ContentLang } from "@/lib/i18n";
import { ErrorText, Loading, MediaUpload, PageHeader, todayISO } from "@/components/ui";

type Translation = {
  title: string;
  description: string;
  verse_reference: string;
  verse_text: string;
};

const empty = (): Translation => ({ title: "", description: "", verse_reference: "", verse_text: "" });
const isBlank = (tr: Translation) => Object.values(tr).every((v) => v.trim() === "");

export default function ChallengeEditorPage() {
  const { t } = useI18n();
  const staff = useStaff();
  const router = useRouter();
  const params = useParams<{ id: string }>();
  const isNew = params.id === "new";

  const [loading, setLoading] = useState(!isNew);
  const [date, setDate] = useState(todayISO(1));
  const [published, setPublished] = useState(true);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [tab, setTab] = useState<ContentLang>("fr");
  const [translations, setTranslations] = useState<Record<ContentLang, Translation>>({
    fr: empty(),
    en: empty(),
    yo: empty(),
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isNew) return;
    supabase()
      .from("challenges")
      .select("*, challenge_translations(*)")
      .eq("id", params.id)
      .single()
      .then(({ data }) => {
        if (!data) return;
        setDate(data.challenge_date);
        setPublished(data.is_published);
        setImageUrl(data.image_url);
        const next = { fr: empty(), en: empty(), yo: empty() };
        for (const tr of data.challenge_translations) {
          next[tr.lang as ContentLang] = {
            title: tr.title ?? "",
            description: tr.description ?? "",
            verse_reference: tr.verse_reference ?? "",
            verse_text: tr.verse_text ?? "",
          };
        }
        setTranslations(next);
        setLoading(false);
      });
  }, [isNew, params.id]);

  const current = translations[tab];
  const update = (field: keyof Translation, value: string) =>
    setTranslations((prev) => ({ ...prev, [tab]: { ...prev[tab], [field]: value } }));

  async function save() {
    setError(null);
    const filled = CONTENT_LANGS.filter((l) => !isBlank(translations[l]));
    if (filled.length === 0) return setError(t.devotions.needOne);
    const missingTitle = filled.find((l) => translations[l].title.trim() === "");
    if (missingTitle) {
      setTab(missingTitle);
      return setError(`${t.langs[missingTitle]}: ${t.challenges.challengeTitle} *`);
    }

    setSaving(true);
    const db = supabase();
    const challenge = { challenge_date: date, is_published: published, image_url: imageUrl };
    const res = isNew
      ? await db.from("challenges").insert({ ...challenge, created_by: staff.id }).select("id").single()
      : await db.from("challenges").update(challenge).eq("id", params.id).select("id").single();
    if (res.error) {
      setSaving(false);
      return setError(res.error.code === "23505" ? t.challenges.duplicate : res.error.message);
    }
    const id = res.data.id as string;
    const nullIfBlank = (v: string) => (v.trim() === "" ? null : v.trim());
    const { error: trError } = await db.from("challenge_translations").upsert(
      filled.map((l) => ({
        challenge_id: id,
        lang: l,
        title: translations[l].title.trim(),
        description: nullIfBlank(translations[l].description),
        verse_reference: nullIfBlank(translations[l].verse_reference),
        verse_text: nullIfBlank(translations[l].verse_text),
      })),
    );
    const removed = CONTENT_LANGS.filter((l) => isBlank(translations[l]));
    if (!trError && removed.length) {
      await db.from("challenge_translations").delete().eq("challenge_id", id).in("lang", removed);
    }
    setSaving(false);
    if (trError) return setError(trError.message);
    router.push("/challenges");
  }

  async function remove() {
    if (!confirm(t.common.confirmDelete)) return;
    await supabase().from("challenges").delete().eq("id", params.id);
    router.push("/challenges");
  }

  if (loading) return <Loading />;

  return (
    <>
      <Link href="/challenges" className="mb-4 inline-flex items-center gap-1 text-sm text-muted hover:text-purple">
        <ArrowLeft className="h-4 w-4" /> {t.common.back}
      </Link>
      <PageHeader
        title={isNew ? t.challenges.newChallenge : t.challenges.editChallenge}
        action={
          !isNew && (
            <button onClick={remove} className="btn-danger">
              <Trash2 className="h-4 w-4" /> {t.common.delete}
            </button>
          )
        }
      />
      <div className="grid gap-6 lg:grid-cols-[320px_1fr]">
        <div className="card h-fit space-y-4">
          <div>
            <label className="label">{t.common.date}</label>
            <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
          </div>
          <div>
            <label className="label">{t.devotions.image}</label>
            <MediaUpload value={imageUrl} onChange={setImageUrl} accept="image/*" folder="challenges" />
          </div>
          <label className="flex items-start gap-2 text-sm">
            <input type="checkbox" className="mt-0.5 h-4 w-4 accent-purple" checked={published} onChange={(e) => setPublished(e.target.checked)} />
            {t.devotions.publish}
          </label>
        </div>
        <div className="card space-y-4">
          <div className="flex gap-2 border-b border-line">
            {CONTENT_LANGS.map((l) => (
              <button
                key={l}
                type="button"
                onClick={() => setTab(l)}
                className={`-mb-px flex cursor-pointer items-center gap-2 border-b-2 px-3 py-2 text-sm font-semibold ${
                  tab === l ? "border-purple text-purple" : "border-transparent text-muted"
                }`}
              >
                {t.langs[l]}
                <span className={`h-2 w-2 rounded-full ${isBlank(translations[l]) ? "bg-line" : "bg-green-500"}`} />
              </button>
            ))}
          </div>
          <div>
            <label className="label">{t.challenges.challengeTitle} <span className="text-gold">*</span></label>
            <textarea rows={2} className="input" value={current.title} onChange={(e) => update("title", e.target.value)} />
          </div>
          <div>
            <label className="label">{t.challenges.description}</label>
            <textarea rows={3} className="input" value={current.description} onChange={(e) => update("description", e.target.value)} />
          </div>
          <div className="grid gap-4 md:grid-cols-[220px_1fr]">
            <div>
              <label className="label">{t.challenges.verseReference}</label>
              <input className="input" value={current.verse_reference} onChange={(e) => update("verse_reference", e.target.value)} />
            </div>
            <div>
              <label className="label">{t.challenges.verseText}</label>
              <textarea rows={2} className="input" value={current.verse_text} onChange={(e) => update("verse_text", e.target.value)} />
            </div>
          </div>
          <ErrorText message={error} />
          <div className="flex justify-end gap-3 pt-2">
            <Link href="/challenges" className="btn-ghost">{t.common.cancel}</Link>
            <button onClick={save} disabled={saving} className="btn-primary">
              {saving ? t.common.saving : t.common.save}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
