"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { CheckCircle2, Circle, Plus } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { CONTENT_LANGS, SLOTS, useI18n, type Slot } from "@/lib/i18n";
import { Empty, Loading, PageHeader, formatDate, todayISO } from "@/components/ui";

type Row = {
  id: string;
  devotion_date: string;
  slot: Slot;
  is_published: boolean;
  devotion_translations: { lang: string; verse_reference: string }[];
};

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
      <div className="mb-4 flex flex-wrap items-center gap-2 text-sm">
        <span className="text-muted">{t.devotions.from}</span>
        <input type="date" className="input w-auto" value={from} onChange={(e) => setFrom(e.target.value)} />
        <span className="text-muted">{t.devotions.to}</span>
        <input type="date" className="input w-auto" value={to} onChange={(e) => setTo(e.target.value)} />
      </div>

      {rows === null ? (
        <Loading />
      ) : dates.length === 0 ? (
        <Empty />
      ) : (
        <div className="space-y-3">
          {dates.map((date) => (
            <div key={date} className={`card ${date === today ? "ring-2 ring-gold" : ""}`}>
              <div className="mb-3 font-bold capitalize">{formatDate(date, lang)}</div>
              <div className="grid gap-3 md:grid-cols-3">
                {SLOTS.map((slot) => {
                  const d = byDate.get(date)?.[slot];
                  if (!d) {
                    return (
                      <Link
                        key={slot}
                        href={`/devotions/new?date=${date}&slot=${slot}`}
                        className="flex items-center justify-center gap-2 rounded-xl border-2 border-dashed border-line p-4 text-sm text-muted hover:border-purple hover:text-purple"
                      >
                        <Plus className="h-4 w-4" /> {t.slots[slot]}
                      </Link>
                    );
                  }
                  const ref = d.devotion_translations.find((x) => x.lang === "fr")?.verse_reference
                    ?? d.devotion_translations[0]?.verse_reference;
                  return (
                    <Link key={slot} href={`/devotions/${d.id}`} className="rounded-xl bg-cream p-4 hover:bg-lavender">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-semibold uppercase text-gold">{t.slots[slot]}</span>
                        <span className={`badge ${d.is_published ? "bg-green-100 text-green-800" : "bg-beige text-muted"}`}>
                          {d.is_published ? t.common.published : t.common.draft}
                        </span>
                      </div>
                      <div className="mt-1 font-semibold">{ref ?? "—"}</div>
                      <div className="mt-2 flex gap-2 text-xs">
                        {CONTENT_LANGS.map((l) => {
                          const has = d.devotion_translations.some((x) => x.lang === l);
                          return (
                            <span key={l} className={`flex items-center gap-1 ${has ? "text-purple" : "text-muted/60"}`}>
                              {has ? <CheckCircle2 className="h-3.5 w-3.5" /> : <Circle className="h-3.5 w-3.5" />}
                              {l.toUpperCase()}
                            </span>
                          );
                        })}
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
