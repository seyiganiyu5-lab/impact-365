"use client";

import { useState } from "react";
import { Upload, X } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";

export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
      <div>
        <h1 className="text-2xl font-extrabold text-purple lg:text-3xl">{title}</h1>
        {subtitle && <p className="mt-1 max-w-2xl text-sm text-muted">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function Empty({ children }: { children?: React.ReactNode }) {
  const { t } = useI18n();
  return <div className="card py-12 text-center text-muted">{children ?? t.common.empty}</div>;
}

export function Loading() {
  const { t } = useI18n();
  return <div className="py-12 text-center text-muted">{t.common.loading}</div>;
}

export function ErrorText({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{message}</p>;
}

/**
 * Uploads a file to the public `media` bucket and returns its public URL.
 * Used for devotion images and audio.
 */
export function MediaUpload({
  value,
  onChange,
  accept,
  folder,
}: {
  value: string | null;
  onChange: (url: string | null) => void;
  accept: string;
  folder: string;
}) {
  const { t } = useI18n();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onFile(file: File) {
    setBusy(true);
    setError(null);
    const ext = file.name.split(".").pop() ?? "bin";
    const path = `${folder}/${crypto.randomUUID()}.${ext}`;
    const db = supabase();
    const { error } = await db.storage.from("media").upload(path, file, {
      contentType: file.type,
      upsert: false,
    });
    setBusy(false);
    if (error) {
      setError(error.message);
      return;
    }
    onChange(db.storage.from("media").getPublicUrl(path).data.publicUrl);
  }

  return (
    <div className="space-y-2">
      {value ? (
        <div className="flex items-center gap-3 rounded-xl border border-line bg-cream p-2">
          {accept.startsWith("image") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={value} alt="" className="h-14 w-24 rounded-lg object-cover" />
          ) : (
            <audio src={value} controls className="h-10 flex-1" />
          )}
          <button type="button" onClick={() => onChange(null)} className="btn-ghost ml-auto px-2 py-1.5">
            <X className="h-4 w-4" /> {t.common.remove}
          </button>
        </div>
      ) : (
        <label className="btn-ghost w-fit">
          <Upload className="h-4 w-4" />
          {busy ? t.common.loading : t.common.upload}
          <input
            type="file"
            accept={accept}
            className="hidden"
            disabled={busy}
            onChange={(e) => e.target.files?.[0] && onFile(e.target.files[0])}
          />
        </label>
      )}
      <ErrorText message={error} />
    </div>
  );
}

/** Today's date as YYYY-MM-DD in the browser's timezone. */
export function todayISO(offsetDays = 0) {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function formatDate(iso: string, lang: string) {
  return new Date(iso.length === 10 ? `${iso}T12:00:00` : iso).toLocaleDateString(
    lang === "fr" ? "fr-FR" : "en-GB",
    { weekday: "short", day: "numeric", month: "short", year: "numeric" },
  );
}

export function formatDateTime(iso: string, lang: string) {
  return new Date(iso).toLocaleString(lang === "fr" ? "fr-FR" : "en-GB", {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}
