"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  ArrowRight,
  BookOpen,
  CalendarClock,
  CheckCircle2,
  HandHeart,
  MessageCircle,
  Plus,
  ShieldAlert,
  Users,
} from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { SLOTS, useI18n, type Slot } from "@/lib/i18n";
import { useStaff } from "@/lib/staff";
import { todayISO } from "@/components/ui";

type Stats = {
  members: number;
  open_conversations: number;
  open_help_requests: number;
  prayers_this_week: number;
  devotions_scheduled: number;
  completions_today: number;
};

type TodayDevotion = {
  id: string;
  slot: Slot;
  is_published: boolean;
  devotion_translations: { lang: string; verse_reference: string }[];
};

type TodayChallenge = {
  id: string;
  is_published: boolean;
  challenge_translations: { lang: string; title: string }[];
};

const SLOT_EMOJI: Record<Slot, string> = { morning: "🌅", afternoon: "☀️", night: "🌙" };

export default function DashboardPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [stats, setStats] = useState<Stats | null>(null);
  const [devotions, setDevotions] = useState<TodayDevotion[] | null>(null);
  const [challenge, setChallenge] = useState<TodayChallenge | null | undefined>(undefined);

  useEffect(() => {
    const db = supabase();
    const today = todayISO();
    db.rpc("admin_dashboard").then(({ data }) => setStats(data as Stats));
    db.from("devotions")
      .select("id, slot, is_published, devotion_translations(lang, verse_reference)")
      .eq("devotion_date", today)
      .then(({ data }) => setDevotions((data as TodayDevotion[]) ?? []));
    db.from("challenges")
      .select("id, is_published, challenge_translations(lang, title)")
      .eq("challenge_date", today)
      .then(({ data }) => setChallenge(((data as TodayChallenge[]) ?? [])[0] ?? null));
  }, []);

  const hour = new Date().getHours();
  const greeting = hour < 12 ? t.ui.morning : hour < 18 ? t.ui.afternoon : t.ui.evening;
  const firstName = staff.full_name?.split(" ")[0] ?? "";
  const todayLabel = new Date().toLocaleDateString(lang === "fr" ? "fr-FR" : "en-GB", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });

  const waiting = stats?.open_conversations ?? 0;
  const sos = stats?.open_help_requests ?? 0;

  return (
    <div className="space-y-9">
      {/* Greeting */}
      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-purple-dark via-purple to-purple-light p-6 text-white shadow-[0_12px_30px_rgba(59,30,123,0.25)] sm:p-8">
        <div aria-hidden className="absolute -right-16 -top-16 h-56 w-56 rounded-full bg-gold/15 blur-2xl" />
        <div className="relative flex flex-wrap items-end justify-between gap-6">
          <div>
            <p className="text-sm font-semibold text-gold first-letter:uppercase">{todayLabel}</p>
            <h1 className="mt-1 text-3xl font-extrabold tracking-tight sm:text-4xl">
              {greeting}, {firstName} 👋
            </h1>
            <p className="mt-2 text-sm text-white/75">{t.tagline}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Link href="/devotions/new" className="btn bg-white/10 text-white ring-1 ring-white/25 hover:bg-white/20">
              <Plus className="h-4 w-4" /> {t.dashboard.addDevotion}
            </Link>
            <Link href="/announcements" className="btn-gold">
              <Plus className="h-4 w-4" /> {t.announcements.newAnnouncement}
            </Link>
          </div>
        </div>
      </section>

      {/* To do */}
      <section>
        <h2 className="mb-3 text-lg font-bold text-purple">{t.ui.todo}</h2>
        {stats && waiting === 0 && sos === 0 ? (
          <div className="card flex items-center gap-3 text-sm text-muted">
            <CheckCircle2 className="h-5 w-5 text-emerald-600" /> {t.ui.allCaughtUp}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <TodoCard
              href="/concerns"
              icon={<MessageCircle className="h-6 w-6" />}
              count={stats ? waiting : null}
              label={t.dashboard.openConversations}
              action={t.ui.reply}
            />
            <TodoCard
              href="/sos"
              icon={<ShieldAlert className="h-6 w-6" />}
              count={stats ? sos : null}
              label={t.ui.openSos}
              action={t.ui.view}
            />
          </div>
        )}
      </section>

      {/* Today's content */}
      <section>
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-lg font-bold text-purple">{t.ui.todayContent}</h2>
          <Link href="/devotions" className="-mr-2 inline-flex min-h-10 items-center rounded-lg px-2 text-sm font-semibold text-[#9a7a17] hover:underline">
            {t.nav.devotions} →
          </Link>
        </div>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {SLOTS.map((slot) => {
            const d = devotions?.find((x) => x.slot === slot);
            const ref =
              d?.devotion_translations.find((x) => x.lang === lang)?.verse_reference ??
              d?.devotion_translations[0]?.verse_reference;
            return (
              <ContentTile
                key={slot}
                loading={devotions === null}
                emoji={SLOT_EMOJI[slot]}
                label={t.slots[slot]}
                title={ref}
                published={d?.is_published}
                href={d ? `/devotions/${d.id}` : `/devotions/new?date=${todayISO()}&slot=${slot}`}
              />
            );
          })}
          <ContentTile
            loading={challenge === undefined}
            emoji="🎯"
            label={t.ui.challengeOfDay}
            title={
              challenge?.challenge_translations.find((x) => x.lang === lang)?.title ??
              challenge?.challenge_translations[0]?.title
            }
            published={challenge?.is_published}
            href={challenge ? `/challenges/${challenge.id}` : "/challenges/new"}
          />
        </div>
      </section>

      {/* Overview */}
      <section>
        <h2 className="mb-3 text-lg font-bold text-purple">{t.ui.overview}</h2>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <Stat icon={<Users />} value={stats?.members} label={t.dashboard.members} href="/members" />
          <Stat icon={<HandHeart />} value={stats?.prayers_this_week} label={t.dashboard.prayersWeek} href="/prayers" />
          <Stat
            icon={<CalendarClock />}
            value={stats?.devotions_scheduled}
            label={t.dashboard.devotionsScheduled}
            href="/devotions"
          />
          <Stat icon={<BookOpen />} value={stats?.completions_today} label={t.dashboard.completionsToday} href="/devotions" />
        </div>
      </section>
    </div>
  );
}

function TodoCard({
  href,
  icon,
  count,
  label,
  action,
}: {
  href: string;
  icon: React.ReactNode;
  count: number | null;
  label: string;
  action: string;
}) {
  const active = !!count;
  return (
    <Link
      href={href}
      className={`group flex items-center gap-4 rounded-2xl border p-5 transition hover:-translate-y-0.5 ${
        active ? "border-gold/50 bg-white shadow-[0_8px_22px_rgba(212,175,55,0.18)]" : "border-line bg-white"
      }`}
    >
      <span
        className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl ${
          active ? "bg-gold text-white" : "bg-lavender text-purple"
        }`}
      >
        {icon}
      </span>
      <div className="min-w-0 flex-1">
        <div className="text-3xl font-extrabold leading-none text-ink">{count ?? "–"}</div>
        <div className="mt-1 text-sm text-muted">{label}</div>
      </div>
      <span className="inline-flex items-center gap-1 text-sm font-semibold text-purple">
        {action} <ArrowRight className="h-4 w-4 transition group-hover:translate-x-0.5" />
      </span>
    </Link>
  );
}

function ContentTile({
  loading,
  emoji,
  label,
  title,
  published,
  href,
}: {
  loading: boolean;
  emoji: string;
  label: string;
  title?: string;
  published?: boolean;
  href: string;
}) {
  const { t } = useI18n();
  if (loading) return <div className="card h-[112px] animate-pulse" />;
  const exists = title !== undefined;
  return (
    <Link
      href={href}
      className={`flex flex-col gap-2 rounded-2xl p-4 transition hover:-translate-y-0.5 ${
        exists ? "bg-white shadow-[0_6px_18px_rgba(59,30,123,0.06)]" : "border-2 border-dashed border-line hover:border-purple"
      }`}
    >
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-bold uppercase tracking-wide text-[#9a7a17]">
          {emoji} {label}
        </span>
        {exists && (
          <span
            className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${
              published ? "bg-emerald-50 text-emerald-700" : "bg-beige text-muted"
            }`}
          >
            {published ? t.common.published : t.common.draft}
          </span>
        )}
      </div>
      {exists ? (
        <div className="line-clamp-2 font-semibold text-ink">{title}</div>
      ) : (
        <div className="flex items-center gap-1.5 text-sm font-semibold text-muted">
          <Plus className="h-4 w-4" /> {t.ui.toCreate}
        </div>
      )}
    </Link>
  );
}

function Stat({
  icon,
  value,
  label,
  href,
}: {
  icon: React.ReactElement<{ className?: string }>;
  value: number | undefined;
  label: string;
  href: string;
}) {
  return (
    <Link href={href} className="card flex flex-col gap-3 p-4 transition hover:-translate-y-0.5">
      <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-lavender text-purple [&>svg]:h-5 [&>svg]:w-5">
        {icon}
      </span>
      <div>
        <div className="text-2xl font-extrabold text-ink">{value ?? "–"}</div>
        <div className="text-xs text-muted">{label}</div>
      </div>
    </Link>
  );
}

