"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookOpen, CalendarClock, HandHeart, MessageCircle, ShieldAlert, Users } from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { useStaff } from "@/lib/staff";
import { PageHeader } from "@/components/ui";

type Stats = {
  members: number;
  open_conversations: number;
  open_help_requests: number;
  prayers_this_week: number;
  devotions_scheduled: number;
  completions_today: number;
};

export default function DashboardPage() {
  const { t } = useI18n();
  const staff = useStaff();
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    supabase()
      .rpc("admin_dashboard")
      .then(({ data }) => setStats(data as Stats));
  }, []);

  const tiles = [
    { label: t.dashboard.members, value: stats?.members, icon: Users, href: "/members" },
    { label: t.dashboard.openConversations, value: stats?.open_conversations, icon: MessageCircle, href: "/concerns", highlight: true },
    { label: t.dashboard.openHelp, value: stats?.open_help_requests, icon: ShieldAlert, href: "/sos", highlight: true },
    { label: t.dashboard.prayersWeek, value: stats?.prayers_this_week, icon: HandHeart, href: "/prayers" },
    { label: t.dashboard.devotionsScheduled, value: stats?.devotions_scheduled, icon: CalendarClock, href: "/devotions" },
    { label: t.dashboard.completionsToday, value: stats?.completions_today, icon: BookOpen, href: "/devotions" },
  ];

  return (
    <>
      <PageHeader title={`${t.dashboard.welcome}, ${staff.full_name?.split(" ")[0] ?? ""}`} subtitle={t.tagline} />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {tiles.map(({ label, value, icon: Icon, href, highlight }) => (
          <Link key={label} href={href} className="card flex items-center gap-4 transition hover:-translate-y-0.5">
            <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${highlight && value ? "bg-gold text-white" : "bg-lavender text-purple"}`}>
              <Icon className="h-6 w-6" />
            </div>
            <div>
              <div className="text-3xl font-extrabold">{value ?? "–"}</div>
              <div className="text-sm text-muted">{label}</div>
            </div>
          </Link>
        ))}
      </div>

      <h2 className="mb-3 mt-10 text-lg font-bold">{t.dashboard.quick}</h2>
      <div className="flex flex-wrap gap-3">
        <Link href="/devotions/new" className="btn-primary">{t.dashboard.addDevotion}</Link>
        <Link href="/challenges/new" className="btn-primary">{t.dashboard.addChallenge}</Link>
        <Link href="/concerns" className="btn-gold">{t.dashboard.answerMessages}</Link>
      </div>
    </>
  );
}
