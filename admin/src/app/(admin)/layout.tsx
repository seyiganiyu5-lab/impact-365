"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  BookOpen,
  HandHeart,
  LayoutDashboard,
  LogOut,
  Megaphone,
  Menu,
  MessageCircle,
  ShieldAlert,
  Target,
  Users,
  X,
} from "lucide-react";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Logo } from "@/components/Logo";
import { LangSwitch } from "@/components/LangSwitch";
import { StaffContext, type StaffProfile } from "@/lib/staff";
import { Avatar } from "@/components/ui";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { t } = useI18n();
  const pathname = usePathname();
  const router = useRouter();
  const [profile, setProfile] = useState<StaffProfile | null | undefined>(undefined);
  const [menuOpen, setMenuOpen] = useState(false);
  // Gold counters in the menu: things waiting for a leader.
  const [counts, setCounts] = useState<{ concerns: number; sos: number }>({ concerns: 0, sos: 0 });

  useEffect(() => {
    if (!profile || profile.role === "member") return;
    supabase()
      .rpc("admin_dashboard")
      .then(({ data }) => {
        const d = data as { open_conversations?: number; open_help_requests?: number } | null;
        if (d) setCounts({ concerns: d.open_conversations ?? 0, sos: d.open_help_requests ?? 0 });
      });
  }, [profile, pathname]);

  useEffect(() => {
    (async () => {
      const db = supabase();
      const { data: auth } = await db.auth.getUser();
      if (!auth.user) {
        router.replace("/login");
        return;
      }
      const { data } = await db
        .from("profiles")
        .select("id, full_name, avatar_url, role")
        .eq("id", auth.user.id)
        .single();
      setProfile((data as StaffProfile) ?? null);
    })();
  }, [router]);

  async function signOut() {
    await supabase().auth.signOut();
    router.replace("/login");
    router.refresh();
  }

  if (profile === undefined) {
    return <div className="flex min-h-screen items-center justify-center text-muted">{t.common.loading}</div>;
  }

  if (!profile || profile.role === "member") {
    return (
      <div className="flex min-h-screen items-center justify-center p-4">
        <div className="card max-w-md space-y-4 text-center">
          <div className="flex justify-center"><Logo /></div>
          <h1 className="text-xl font-bold text-purple">{t.denied.title}</h1>
          <p className="text-sm text-muted">{t.denied.text}</p>
          <button onClick={signOut} className="btn-ghost">{t.common.signOut}</button>
        </div>
      </div>
    );
  }

  const nav = [
    { href: "/", label: t.nav.dashboard, icon: LayoutDashboard },
    { href: "/concerns", label: t.nav.concerns, icon: MessageCircle, count: counts.concerns },
    { href: "/sos", label: t.nav.sos, icon: ShieldAlert, count: counts.sos },
    { href: "/prayers", label: t.nav.prayers, icon: HandHeart },
    { href: "/devotions", label: t.nav.devotions, icon: BookOpen },
    { href: "/challenges", label: t.nav.challenges, icon: Target },
    { href: "/announcements", label: t.nav.announcements, icon: Megaphone },
    { href: "/members", label: t.nav.members, icon: Users },
  ];

  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);
  const current = nav.find((n) => isActive(n.href));

  const sidebar = (
    <aside className="flex h-full w-[264px] flex-col bg-gradient-to-b from-purple-dark via-purple to-[#4a2a8f] px-4 pb-4 pt-6 text-white">
      <div className="mb-8 flex items-center justify-between px-2">
        <Logo light />
        <button
          className="cursor-pointer rounded-lg p-1.5 hover:bg-white/10 lg:hidden"
          onClick={() => setMenuOpen(false)}
          aria-label="Close menu"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
      <nav className="flex-1 space-y-1 overflow-y-auto">
        {nav.map(({ href, label, icon: Icon, count }) => {
          const active = isActive(href);
          return (
            <Link
              key={href}
              href={href}
              onClick={() => setMenuOpen(false)}
              aria-current={active ? "page" : undefined}
              className={`group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                active ? "bg-white text-purple shadow-sm" : "text-white/80 hover:bg-white/10 hover:text-white"
              }`}
            >
              <Icon className={`h-[18px] w-[18px] ${active ? "text-purple" : "text-gold"}`} />
              <span className="flex-1">{label}</span>
              {!!count && (
                <span className="min-w-5 rounded-full bg-gold px-1.5 text-center text-[11px] font-bold leading-5 text-white">
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </Link>
          );
        })}
      </nav>
      <div className="mt-4 rounded-2xl bg-white/10 p-3">
        <div className="flex items-center gap-3">
          <Avatar name={profile.full_name} url={profile.avatar_url} size={38} ring />
          <div className="min-w-0 flex-1">
            <div className="truncate text-sm font-semibold">{profile.full_name}</div>
            <div className="text-xs text-gold">{t.members.roles[profile.role]}</div>
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between">
          <LangSwitch dark />
          <button
            onClick={signOut}
            className="flex cursor-pointer items-center gap-1.5 rounded-lg px-2 py-1 text-xs text-white/75 hover:bg-white/10 hover:text-white"
          >
            <LogOut className="h-4 w-4" /> {t.common.signOut}
          </button>
        </div>
      </div>
    </aside>
  );

  return (
    <StaffContext.Provider value={profile}>
      <div className="flex min-h-screen">
        <div className="sticky top-0 hidden h-screen lg:block">{sidebar}</div>
        {menuOpen && (
          <div className="fixed inset-0 z-40 flex lg:hidden">
            {sidebar}
            <div className="flex-1 bg-black/40" onClick={() => setMenuOpen(false)} />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-line bg-cream/90 px-4 py-3 backdrop-blur lg:hidden">
            <button
              onClick={() => setMenuOpen(true)}
              aria-label={t.ui.menu}
              className="relative cursor-pointer rounded-xl border border-line bg-white p-2"
            >
              <Menu className="h-5 w-5 text-purple" />
              {counts.concerns + counts.sos > 0 && (
                <span className="absolute -right-1 -top-1 h-3 w-3 rounded-full border-2 border-cream bg-gold" />
              )}
            </button>
            <span className="flex-1 truncate font-bold text-purple">{current?.label}</span>
            <Avatar name={profile.full_name} url={profile.avatar_url} size={34} />
          </header>
          <main className="mx-auto max-w-6xl px-4 py-6 lg:px-10 lg:py-10">{children}</main>
        </div>
      </div>
    </StaffContext.Provider>
  );
}
