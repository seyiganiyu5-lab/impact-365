"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { CONTENT_LANGS, useI18n } from "@/lib/i18n";
import { Empty, Loading, PageHeader, formatDate, todayISO } from "@/components/ui";

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
        <Empty />
      ) : (
        <div className="space-y-3">
          {rows.map((r) => {
            const title =
              r.challenge_translations.find((x) => x.lang === lang)?.title ??
              r.challenge_translations[0]?.title;
            return (
              <Link
                key={r.id}
                href={`/challenges/${r.id}`}
                className={`card flex flex-wrap items-center gap-4 hover:bg-lavender ${r.challenge_date === today ? "ring-2 ring-gold" : ""}`}
              >
                <div className="w-40 text-sm font-semibold capitalize text-gold">{formatDate(r.challenge_date, lang)}</div>
                <div className="min-w-0 flex-1 font-semibold">{title}</div>
                <div className="flex gap-2 text-xs text-muted">
                  {CONTENT_LANGS.map((l) => (
                    <span key={l} className={r.challenge_translations.some((x) => x.lang === l) ? "text-purple" : "opacity-40"}>
                      {l.toUpperCase()}
                    </span>
                  ))}
                </div>
                <span className="text-sm text-muted">
                  {r.challenge_completions[0]?.count ?? 0} {t.challenges.completions}
                </span>
                <span className={`badge ${r.is_published ? "bg-green-100 text-green-800" : "bg-beige text-muted"}`}>
                  {r.is_published ? t.common.published : t.common.draft}
                </span>
              </Link>
            );
          })}
        </div>
      )}
    </>
  );
}
