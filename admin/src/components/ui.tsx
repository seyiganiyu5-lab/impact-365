"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Upload, X } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";

export function PageHeader({
  title,
  subtitle,
  action,
  back,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
  /** Link shown above the title ("← Retour"). */
  back?: { href: string; label: string };
}) {
  return (
    <div className="mb-7">
      {back && (
        <Link
          href={back.href}
          className="-ml-2 mb-2 inline-flex min-h-10 items-center gap-1.5 rounded-lg px-2 text-sm font-medium text-muted transition hover:bg-lavender hover:text-purple"
        >
          <ArrowLeft className="h-4 w-4" /> {back.label}
        </Link>
      )}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div className="min-w-0">
          <h1 className="text-2xl font-extrabold tracking-tight text-purple lg:text-[28px]">{title}</h1>
          {subtitle && <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-muted">{subtitle}</p>}
        </div>
        {action}
      </div>
    </div>
  );
}

/** Round photo, or initials on lavender. */
export function Avatar({
  name,
  url,
  size = 40,
  ring = false,
}: {
  name: string | null | undefined;
  url?: string | null;
  size?: number;
  ring?: boolean;
}) {
  const initials =
    (name ?? "")
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((p) => p[0]?.toUpperCase())
      .join("") || "?";
  return (
    <span
      className={`relative inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-lavender font-bold text-purple ${
        ring ? "ring-2 ring-gold ring-offset-2 ring-offset-transparent" : ""
      }`}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}
      aria-hidden
    >
      {initials}
      {url && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={url}
          alt=""
          className="absolute inset-0 h-full w-full object-cover"
          referrerPolicy="no-referrer"
          onError={(e) => (e.currentTarget.style.display = "none")}
        />
      )}
    </span>
  );
}

const CHIP_TONES = {
  purple: "bg-lavender text-purple",
  gold: "bg-gold/15 text-[#9a7a17]",
  green: "bg-emerald-50 text-emerald-700",
  red: "bg-red-50 text-red-700",
  muted: "bg-beige text-muted",
  solid: "bg-purple text-white",
} as const;

export function Chip({
  tone = "purple",
  icon,
  children,
}: {
  tone?: keyof typeof CHIP_TONES;
  icon?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold ${CHIP_TONES[tone]}`}>
      {icon}
      {children}
    </span>
  );
}

/** Pill tabs (like the app), with optional gold counts. */
export function Segmented<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T;
  options: { value: T; label: string; count?: number }[];
  onChange: (v: T) => void;
}) {
  return (
    <div className="inline-flex max-w-full flex-wrap gap-1 rounded-2xl border border-line bg-white p-1">
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            aria-pressed={active}
            className={`inline-flex cursor-pointer items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition ${
              active ? "bg-purple text-white shadow-sm" : "text-ink/70 hover:bg-lavender"
            }`}
          >
            {o.label}
            {!!o.count && (
              <span className="min-w-5 rounded-full bg-gold px-1.5 text-center text-[11px] font-bold leading-5 text-white">
                {o.count > 99 ? "99+" : o.count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}

export function Empty({ children, emoji = "🕊️" }: { children?: React.ReactNode; emoji?: string }) {
  const { t } = useI18n();
  return (
    <div className="card flex flex-col items-center gap-3 py-14 text-center">
      <span className="flex h-16 w-16 items-center justify-center rounded-full bg-lavender text-3xl">{emoji}</span>
      <p className="max-w-sm text-sm text-muted">{children ?? t.common.empty}</p>
    </div>
  );
}

/** Grey placeholders while data loads. */
export function Loading({ rows = 3 }: { rows?: number }) {
  const { t } = useI18n();
  return (
    <div className="space-y-3" role="status" aria-label={t.common.loading}>
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="card animate-pulse space-y-3">
          <div className="h-4 w-1/3 rounded-full bg-line" />
          <div className="h-3 w-2/3 rounded-full bg-line/70" />
        </div>
      ))}
    </div>
  );
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

/** "14:05" today, "Hier" yesterday, else "12 oct." */
export function formatRelative(iso: string, lang: string, yesterday: string) {
  const d = new Date(iso);
  const now = new Date();
  const day = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diff = Math.round((day(now) - day(d)) / 86_400_000);
  const locale = lang === "fr" ? "fr-FR" : "en-GB";
  if (diff === 0) return d.toLocaleTimeString(locale, { hour: "2-digit", minute: "2-digit" });
  if (diff === 1) return yesterday;
  return d.toLocaleDateString(locale, { day: "numeric", month: "short" });
}

/** Same emojis as the app for Holy SOS categories. */
export const SOS_EMOJI: Record<string, string> = {
  prayer: "🙏",
  financial: "💰",
  health: "🩺",
  emotional: "💜",
  studies_work: "🎓",
  other: "✨",
};
