"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { CONTENT_LANGS, SLOTS, useI18n, type Slot } from "@/lib/i18n";
import { Chip, Empty, Loading, PageHeader, formatDate, todayISO } from "@/components/ui";

type Row = {
  id: string;
  devotion_date: string;
  slot: Slot;
  is_published: boolean;
  devotion_translations: { lang: string; verse_reference: string }[];
};

const SLOT_EMOJI: Record<Slot, string> = { morning: "🌅", afternoon: "☀️", night: "🌙" };

export default function DevotionsPage() {
  const { t, lang } = useI18n();
  const [from, setFrom] = useState(todayISO(-7));
  const [to, setTo] = useState(todayISO(21));
  const [rows, setRows] = useState<Row[] | null>(null);

  useEffect(() => {
    supabase()
      .from("devotions")
      .select("id, devotion_date, slot, is_published, devotion_translations(lang, verse_reference)")
      .gte("devotion_date", from)
      .lte("devotion_date", to)
      .order("devotion_date", { ascending: false })
      .then(({ data }) => setRows((data as Row[]) ?? []));
  }, [from, to]);

  // Group by date, newest first, and always show today even when empty.
  const byDate = new Map<string, Partial<Record<Slot, Row>>>();
  const today = todayISO();
  if (today >= from && today <= to) byDate.set(today, {});
  for (const r of rows ?? []) {
    byDate.set(r.devotion_date, { ...(byDate.get(r.devotion_date) ?? {}), [r.slot]: r });
  }
  const dates = [...byDate.keys()].sort().reverse();

  return (
    <>
      <PageHeader
        title={t.devotions.title}
        subtitle={t.devotions.subtitle}
        action={
          <Link href="/devotions/new" className="btn-primary">
            <Plus className="h-4 w-4" /> {t.devotions.newDevotion}
          </Link>
        }
      />
      <div className="mb-5 flex flex-wrap items-center gap-2 rounded-2xl border border-line bg-white p-2 text-sm">
        <span className="px-2 font-semibold text-muted">{t.devotions.from}</span>
        <input type="date" className="input w-auto py-1.5" value={from} onChange={(e) => setFrom(e.target.value)} />
        <span className="px-1 font-semibold text-muted">{t.devotions.to}</span>
        <input type="date" className="input w-auto py-1.5" value={to} onChange={(e) => setTo(e.target.value)} />
      </div>

      {rows === null ? (
        <Loading />
      ) : dates.length === 0 ? (
        <Empty emoji="📖" />
      ) : (
        <div className="space-y-4">
          {dates.map((date) => (
            <section
              key={date}
              className={`card p-5 ${date === today ? "ring-2 ring-gold shadow-[0_8px_22px_rgba(212,175,55,0.18)]" : ""}`}
            >
              <div className="mb-3 flex items-center gap-2">
                <h2 className="font-bold text-ink first-letter:uppercase">{formatDate(date, lang)}</h2>
                {date === today && <Chip tone="gold">{t.ui.today}</Chip>}
              </div>
              <div className="grid gap-3 md:grid-cols-3">
                {SLOTS.map((slot) => {
                  const d = byDate.get(date)?.[slot];
                  if (!d) {
                    return (
                      <Link
                        key={slot}
                        href={`/devotions/new?date=${date}&slot=${slot}`}
                        className="flex min-h-[104px] flex-col items-center justify-center gap-1 rounded-2xl border-2 border-dashed border-line p-4 text-sm text-muted transition hover:border-purple hover:text-purple"
                      >
                        <span className="text-lg">{SLOT_EMOJI[slot]}</span>
                        <span className="flex items-center gap-1 font-semibold">
                          <Plus className="h-4 w-4" /> {t.slots[slot]}
                        </span>
                      </Link>
                    );
                  }
                  const ref = d.devotion_translations.find((x) => x.lang === "fr")?.verse_reference
                    ?? d.devotion_translations[0]?.verse_reference;
                  return (
                    <Link
                      key={slot}
                      href={`/devotions/${d.id}`}
                      className="flex min-h-[104px] flex-col gap-1.5 rounded-2xl bg-cream p-4 transition hover:bg-lavender"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-bold uppercase tracking-wide text-[#9a7a17]">
                          {SLOT_EMOJI[slot]} {t.slots[slot]}
                        </span>
                        <Chip tone={d.is_published ? "green" : "muted"}>
                          {d.is_published ? t.common.published : t.common.draft}
                        </Chip>
                      </div>
                      <div className="font-semibold text-ink">{ref ?? "—"}</div>
                      <div className="mt-auto flex gap-1.5">
                        {CONTENT_LANGS.map((l) => {
                          const has = d.devotion_translations.some((x) => x.lang === l);
                          return (
                            <span
                              key={l}
                              title={t.langs[l]}
                              className={`rounded-md px-1.5 py-0.5 text-[10px] font-bold ${
                                has ? "bg-purple text-white" : "bg-white text-muted/60 ring-1 ring-line"
                              }`}
                            >
                              {l.toUpperCase()}
                            </span>
                          );
                        })}
                      </div>
                    </Link>
                  );
                })}
              </div>
            </section>
          ))}
        </div>
      )}
    </>
  );
}
