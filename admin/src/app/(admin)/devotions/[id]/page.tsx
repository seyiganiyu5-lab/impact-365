"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { ArrowLeft, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useStaff } from "@/lib/staff";
import { CONTENT_LANGS, SLOTS, useI18n, type ContentLang, type Slot } from "@/lib/i18n";
import { ErrorText, Loading, MediaUpload, PageHeader, todayISO } from "@/components/ui";

type Translation = {
  theme: string;
  verse_reference: string;
  verse_text: string;
  god_says: string;
  i_understand: string;
  i_do: string;
  audio_url: string | null;
};

const emptyTranslation = (): Translation => ({
  theme: "",
  verse_reference: "",
  verse_text: "",
  god_says: "",
  i_understand: "",
  i_do: "",
  audio_url: null,
});

const REQUIRED: (keyof Translation)[] = ["verse_reference", "verse_text", "god_says", "i_understand", "i_do"];

const isBlank = (tr: Translation) =>
  Object.entries(tr).every(([, v]) => v === null || String(v).trim() === "");
const isComplete = (tr: Translation) => REQUIRED.every((k) => String(tr[k] ?? "").trim() !== "");

export default function DevotionEditorPage() {
  return (
    <Suspense fallback={<Loading />}>
      <DevotionEditor />
    </Suspense>
  );
}

function DevotionEditor() {
  const { t } = useI18n();
  const staff = useStaff();
  const router = useRouter();
  const params = useParams<{ id: string }>();
  const search = useSearchParams();
  const isNew = params.id === "new";

  const [loading, setLoading] = useState(!isNew);
  const [date, setDate] = useState(search.get("date") ?? todayISO());
  const [slot, setSlot] = useState<Slot>((search.get("slot") as Slot) ?? "morning");
  const [published, setPublished] = useState(true);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [tab, setTab] = useState<ContentLang>("fr");
  const [translations, setTranslations] = useState<Record<ContentLang, Translation>>({
    fr: emptyTranslation(),
    en: emptyTranslation(),
    yo: emptyTranslation(),
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isNew) return;
    supabase()
      .from("devotions")
      .select("*, devotion_translations(*)")
      .eq("id", params.id)
      .single()
      .then(({ data }) => {
        if (!data) return;
        setDate(data.devotion_date);
        setSlot(data.slot);
        setPublished(data.is_published);
        setImageUrl(data.image_url);
        const next = { fr: emptyTranslation(), en: emptyTranslation(), yo: emptyTranslation() };
        for (const tr of data.devotion_translations as (Translation & { lang: ContentLang })[]) {
          next[tr.lang] = {
            theme: tr.theme ?? "",
            verse_reference: tr.verse_reference,
            verse_text: tr.verse_text,
            god_says: tr.god_says,
            i_understand: tr.i_understand,
            i_do: tr.i_do,
            audio_url: tr.audio_url,
          };
        }
        setTranslations(next);
        setLoading(false);
      });
  }, [isNew, params.id]);

  const current = translations[tab];
  const update = (field: keyof Translation, value: string | null) =>
    setTranslations((prev) => ({ ...prev, [tab]: { ...prev[tab], [field]: value } }));

  async function save() {
    setError(null);
    const filled = CONTENT_LANGS.filter((l) => !isBlank(translations[l]));
    if (filled.length === 0) return setError(t.devotions.needOne);
    const incomplete = filled.find((l) => !isComplete(translations[l]));
    if (incomplete) {
      setTab(incomplete);
      return setError(t.devotions.incomplete.replace("{lang}", t.langs[incomplete]));
    }

    setSaving(true);
    const db = supabase();
    const devotion = {
      devotion_date: date,
      slot,
      is_published: published,
      image_url: imageUrl,
      updated_at: new Date().toISOString(),
    };
    const res = isNew
      ? await db.from("devotions").insert({ ...devotion, created_by: staff.id }).select("id").single()
      : await db.from("devotions").update(devotion).eq("id", params.id).select("id").single();

    if (res.error) {
      setSaving(false);
      return setError(res.error.code === "23505" ? t.devotions.duplicate : res.error.message);
    }
    const id = res.data.id as string;

    const upserts = filled.map((l) => ({
      devotion_id: id,
      lang: l,
      ...translations[l],
      theme: translations[l].theme.trim() || null,
    }));
    const { error: trError } = await db.from("devotion_translations").upsert(upserts);
    const removed = CONTENT_LANGS.filter((l) => isBlank(translations[l]));
    if (!trError && removed.length) {
      await db.from("devotion_translations").delete().eq("devotion_id", id).in("lang", removed);
    }
    setSaving(false);
    if (trError) return setError(trError.message);
    router.push("/devotions");
  }

  async function remove() {
    if (!confirm(t.common.confirmDelete)) return;
    await supabase().from("devotions").delete().eq("id", params.id);
    router.push("/devotions");
  }

  if (loading) return <Loading />;

  const field = (key: keyof Translation, label: string, rows = 0, placeholder?: string) => (
    <div>
      <label className="label">
        {label}
        {REQUIRED.includes(key) && <span className="text-gold"> *</span>}
      </label>
      {rows ? (
        <textarea
          rows={rows}
          className="input"
          value={(current[key] as string) ?? ""}
          placeholder={placeholder}
          onChange={(e) => update(key, e.target.value)}
        />
      ) : (
        <input
          className="input"
          value={(current[key] as string) ?? ""}
          placeholder={placeholder}
          onChange={(e) => update(key, e.target.value)}
        />
      )}
    </div>
  );

  return (
    <>
      <Link href="/devotions" className="mb-4 inline-flex items-center gap-1 text-sm text-muted hover:text-purple">
        <ArrowLeft className="h-4 w-4" /> {t.common.back}
      </Link>
      <PageHeader
        title={isNew ? t.devotions.newDevotion : t.devotions.editDevotion}
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
            <label className="label">{t.devotions.slot}</label>
            <div className="grid grid-cols-3 gap-2">
              {SLOTS.map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => setSlot(s)}
                  className={`btn px-2 ${slot === s ? "bg-purple text-white" : "border border-line bg-white"}`}
                >
                  {t.slots[s]}
                </button>
              ))}
            </div>
          </div>
          <div>
            <label className="label">{t.devotions.image}</label>
            <MediaUpload value={imageUrl} onChange={setImageUrl} accept="image/*" folder="devotions" />
          </div>
          <label className="flex items-start gap-2 text-sm">
            <input type="checkbox" className="mt-0.5 h-4 w-4 accent-purple" checked={published} onChange={(e) => setPublished(e.target.checked)} />
            {t.devotions.publish}
          </label>
        </div>

        <div className="card space-y-4">
          <div>
            <h2 className="font-bold">{t.devotions.translations}</h2>
            <p className="text-sm text-muted">{t.devotions.translationHint}</p>
          </div>
          <div className="flex gap-2 border-b border-line">
            {CONTENT_LANGS.map((l) => {
              const tr = translations[l];
              const state = isBlank(tr) ? "missing" : isComplete(tr) ? "filled" : "partial";
              return (
                <button
                  key={l}
                  type="button"
                  onClick={() => setTab(l)}
                  className={`-mb-px flex cursor-pointer items-center gap-2 border-b-2 px-3 py-2 text-sm font-semibold ${
                    tab === l ? "border-purple text-purple" : "border-transparent text-muted"
                  }`}
                >
                  {t.langs[l]}
                  <span
                    className={`h-2 w-2 rounded-full ${
                      state === "filled" ? "bg-green-500" : state === "partial" ? "bg-gold" : "bg-line"
                    }`}
                    title={state === "missing" ? t.devotions.missing : t.devotions.filled}
                  />
                </button>
              );
            })}
          </div>

          {field("theme", t.devotions.theme)}
          <div className="grid gap-4 md:grid-cols-[220px_1fr]">
            {field("verse_reference", t.devotions.verseReference, 0, t.devotions.verseReferencePh)}
            {field("verse_text", t.devotions.verseText, 2)}
          </div>
          {field("god_says", t.devotions.godSays, 3)}
          {field("i_understand", t.devotions.iUnderstand, 3)}
          {field("i_do", t.devotions.iDo, 3)}
          <div>
            <label className="label">{t.devotions.audio}</label>
            <MediaUpload
              key={tab}
              value={current.audio_url}
              onChange={(url) => update("audio_url", url)}
              accept="audio/*"
              folder="audio"
            />
          </div>

          <ErrorText message={error} />
          <div className="flex justify-end gap-3 pt-2">
            <Link href="/devotions" className="btn-ghost">{t.common.cancel}</Link>
            <button onClick={save} disabled={saving} className="btn-primary">
              {saving ? t.common.saving : t.common.save}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
