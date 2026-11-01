"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { CONTENT_LANGS, useI18n } from "@/lib/i18n";
import { Chip, Empty, Loading, PageHeader, formatDate, todayISO } from "@/components/ui";

type Row = {
  id: string;
  challenge_date: string;
  is_published: boolean;
  challenge_translations: { lang: string; title: string }[];
  challenge_completions: { count: number }[];
};

export default function ChallengesPage() {
  const { t, lang } = useI18n();
  const [rows, setRows] = useState<Row[] | null>(null);

  useEffect(() => {
    supabase()
      .from("challenges")
      .select("id, challenge_date, is_published, challenge_translations(lang, title), challenge_completions(count)")
      .gte("challenge_date", todayISO(-30))
      .order("challenge_date", { ascending: false })
      .then(({ data }) => setRows((data as Row[]) ?? []));
  }, []);

  const today = todayISO();

  return (
    <>
      <PageHeader
        title={t.challenges.title}
        subtitle={t.challenges.subtitle}
        action={
          <Link href="/challenges/new" className="btn-primary">
            <Plus className="h-4 w-4" /> {t.challenges.newChallenge}
          </Link>
        }
      />
      {rows === null ? (
        <Loading />
      ) : rows.length === 0 ? (
        <Empty emoji="🎯" />
      ) : (
        <div className="space-y-3">
          {rows.map((r) => {
            const title =
              r.challenge_translations.find((x) => x.lang === lang)?.title ??
              r.challenge_translations[0]?.title;
            const isToday = r.challenge_date === today;
            return (
              <Link
                key={r.id}
                href={`/challenges/${r.id}`}
                className={`card flex flex-wrap items-center gap-4 p-4 transition hover:bg-lavender/60 sm:flex-nowrap ${
                  isToday ? "ring-2 ring-gold" : ""
                }`}
              >
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-lavender text-2xl">🎯</span>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2 text-xs font-semibold text-[#9a7a17]">
                    <span className="first-letter:uppercase">{formatDate(r.challenge_date, lang)}</span>
                    {isToday && <Chip tone="gold">{t.ui.today}</Chip>}
                  </div>
                  <div className="mt-0.5 font-semibold text-ink">{title}</div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="flex gap-1.5">
                    {CONTENT_LANGS.map((l) => (
                      <span
                        key={l}
                        title={t.langs[l]}
                        className={`rounded-md px-1.5 py-0.5 text-[10px] font-bold ${
                          r.challenge_translations.some((x) => x.lang === l)
                            ? "bg-purple text-white"
                            : "bg-white text-muted/60 ring-1 ring-line"
                        }`}
                      >
                        {l.toUpperCase()}
                      </span>
                    ))}
                  </div>
                  <span className="whitespace-nowrap text-sm text-muted">
                    <strong className="text-ink">{r.challenge_completions[0]?.count ?? 0}</strong> {t.challenges.completions}
                  </span>
                  <Chip tone={r.is_published ? "green" : "muted"}>{r.is_published ? t.common.published : t.common.draft}</Chip>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </>
  );
}
