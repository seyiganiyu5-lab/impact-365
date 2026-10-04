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

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { t } = useI18n();
  const pathname = usePathname();
  const router = useRouter();
  const [profile, setProfile] = useState<StaffProfile | null | undefined>(undefined);
  const [menuOpen, setMenuOpen] = useState(false);

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
        .select("id, full_name, role")
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
    { href: "/devotions", label: t.nav.devotions, icon: BookOpen },
    { href: "/challenges", label: t.nav.challenges, icon: Target },
    { href: "/concerns", label: t.nav.concerns, icon: MessageCircle },
    { href: "/sos", label: t.nav.sos, icon: ShieldAlert },
    { href: "/prayers", label: t.nav.prayers, icon: HandHeart },
    { href: "/announcements", label: t.nav.announcements, icon: Megaphone },
    { href: "/members", label: t.nav.members, icon: Users },
  ];

  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  const sidebar = (
    <aside className="flex h-full w-64 flex-col bg-purple p-5 text-white">
      <div className="mb-8 flex items-center justify-between">
        <Logo light />
        <button className="lg:hidden" onClick={() => setMenuOpen(false)} aria-label="Close menu">
          <X className="h-5 w-5" />
        </button>
      </div>
      <nav className="flex-1 space-y-1">
        {nav.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            onClick={() => setMenuOpen(false)}
            className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
              isActive(href) ? "bg-white/10 text-gold" : "text-white/80 hover:bg-white/5"
            }`}
          >
            <Icon className="h-[18px] w-[18px]" />
            {label}
          </Link>
        ))}
      </nav>
      <div className="mt-6 space-y-3 border-t border-white/10 pt-4">
        <div className="text-sm">
          <div className="font-semibold">{profile.full_name}</div>
          <div className="text-xs text-gold">{t.members.roles[profile.role]}</div>
        </div>
        <div className="flex items-center justify-between">
          <LangSwitch dark />
          <button onClick={signOut} className="flex cursor-pointer items-center gap-1.5 text-xs text-white/70 hover:text-white">
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
          <header className="flex items-center justify-between border-b border-line bg-white px-4 py-3 lg:hidden">
            <button onClick={() => setMenuOpen(true)} aria-label="Open menu">
              <Menu className="h-6 w-6 text-purple" />
            </button>
            <Logo />
            <span className="w-6" />
          </header>
          <main className="mx-auto max-w-6xl p-4 lg:p-8">{children}</main>
        </div>
      </div>
    </StaffContext.Provider>
  );
}
