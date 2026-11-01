"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";
import { useStaff, type StaffRole } from "@/lib/staff";
import { useI18n } from "@/lib/i18n";
import { Search } from "lucide-react";
import { Avatar, Chip, Empty, ErrorText, Loading, PageHeader, Segmented, formatDate } from "@/components/ui";

type Member = {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  phone: string | null;
  role: StaffRole;
  preferred_language: "fr" | "en" | "yo";
  created_at: string;
};

const ROLES: StaffRole[] = ["member", "leader", "pastor", "admin"];

async function fetchMembers() {
  const { data } = await supabase()
    .from("profiles")
    .select("id, full_name, avatar_url, phone, role, preferred_language, created_at")
    .order("created_at", { ascending: false });
  return (data as Member[]) ?? [];
}

export default function MembersPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [rows, setRows] = useState<Member[] | null>(null);
  const [search, setSearch] = useState("");
  const [group, setGroup] = useState<"all" | "team" | "member">("all");
  const [error, setError] = useState<string | null>(null);

  const [reload, setReload] = useState(0);
  const load = () => setReload((n) => n + 1);

  useEffect(() => {
    fetchMembers().then(setRows);
  }, [reload]);

  async function changeRole(m: Member, role: StaffRole) {
    setError(null);
    const { error } = await supabase().from("profiles").update({ role }).eq("id", m.id);
    if (error) setError(error.message);
    load();
  }

  const all = rows ?? [];
  const team = all.filter((m) => m.role !== "member");
  const filtered = all.filter(
    (m) =>
      (group === "all" || (group === "team" ? m.role !== "member" : m.role === "member")) &&
      (m.full_name ?? "").toLowerCase().includes(search.trim().toLowerCase()),
  );

  const roleControl = (m: Member) =>
    staff.role === "admin" && m.id !== staff.id ? (
      <select
        className="input w-auto py-1.5 text-sm"
        value={m.role}
        onChange={(e) => changeRole(m, e.target.value as StaffRole)}
        aria-label={t.members.role}
      >
        {ROLES.map((r) => (
          <option key={r} value={r}>{t.members.roles[r]}</option>
        ))}
      </select>
    ) : (
      <Chip tone={m.role === "member" ? "muted" : m.role === "admin" ? "solid" : "purple"}>{t.members.roles[m.role]}</Chip>
    );

  return (
    <>
      <PageHeader title={t.members.title} subtitle={t.members.subtitle} />
      <div className="mb-5 flex flex-wrap items-center gap-3">
        <Segmented
          value={group}
          onChange={setGroup}
          options={[
            { value: "all", label: `${t.ui.allRoles} · ${all.length}` },
            { value: "team", label: `${t.ui.team} · ${team.length}` },
            { value: "member", label: `${t.members.roles.member} · ${all.length - team.length}` },
          ]}
        />
        <label className="relative w-full sm:ml-auto sm:w-72">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            className="input pl-10"
            placeholder={t.members.search}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>
      <ErrorText message={error} />
      {rows === null ? (
        <Loading />
      ) : filtered.length === 0 ? (
        <Empty emoji="👥" />
      ) : (
        <>
          {/* Phone: cards */}
          <div className="space-y-3 md:hidden">
            {filtered.map((m) => (
              <div key={m.id} className="card flex items-center gap-3 p-4">
                <Avatar name={m.full_name} url={m.avatar_url} size={44} />
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{m.full_name ?? "—"}</div>
                  <div className="truncate text-xs text-muted">
                    {t.langs[m.preferred_language]}
                    {m.phone ? ` · ${m.phone}` : ""}
                  </div>
                </div>
                {roleControl(m)}
              </div>
            ))}
          </div>

          {/* Larger screens: table */}
          <div className="card hidden overflow-hidden p-0 md:block">
            <table className="w-full text-left text-sm">
              <thead className="bg-cream text-xs font-semibold uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-5 py-3">{t.members.name}</th>
                  <th className="px-5 py-3">{t.members.language}</th>
                  <th className="px-5 py-3">{t.members.joined}</th>
                  <th className="px-5 py-3">{t.members.role}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => (
                  <tr key={m.id} className="border-t border-line transition hover:bg-cream/60">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <Avatar name={m.full_name} url={m.avatar_url} size={38} />
                        <div className="min-w-0">
                          <div className="font-semibold">
                            {m.full_name ?? "—"}
                            {m.id === staff.id && <span className="ml-1.5 text-xs font-normal text-muted">({t.ui.you})</span>}
                          </div>
                          {m.phone && <div className="text-xs text-muted">{m.phone}</div>}
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3">{t.langs[m.preferred_language]}</td>
                    <td className="px-5 py-3 first-letter:uppercase">{formatDate(m.created_at, lang)}</td>
                    <td className="px-5 py-3">{roleControl(m)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </>
  );
}
