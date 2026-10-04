"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";
import { useStaff, type StaffRole } from "@/lib/staff";
import { useI18n } from "@/lib/i18n";
import { Empty, ErrorText, Loading, PageHeader, formatDate } from "@/components/ui";

type Member = {
  id: string;
  full_name: string | null;
  phone: string | null;
  role: StaffRole;
  preferred_language: "fr" | "en" | "yo";
  created_at: string;
};

const ROLES: StaffRole[] = ["member", "leader", "pastor", "admin"];

async function fetchMembers() {
  const { data } = await supabase()
    .from("profiles")
    .select("id, full_name, phone, role, preferred_language, created_at")
    .order("created_at", { ascending: false });
  return (data as Member[]) ?? [];
}

export default function MembersPage() {
  const { t, lang } = useI18n();
  const staff = useStaff();
  const [rows, setRows] = useState<Member[] | null>(null);
  const [search, setSearch] = useState("");
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

  const filtered = (rows ?? []).filter((m) =>
    (m.full_name ?? "").toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <>
      <PageHeader title={t.members.title} subtitle={t.members.subtitle} />
      <input
        className="input mb-4 max-w-sm"
        placeholder={t.members.search}
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <ErrorText message={error} />
      {rows === null ? (
        <Loading />
      ) : filtered.length === 0 ? (
        <Empty />
      ) : (
        <div className="card overflow-x-auto p-0">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-line text-xs uppercase text-muted">
              <tr>
                <th className="px-5 py-3">{t.members.name}</th>
                <th className="px-5 py-3">{t.members.language}</th>
                <th className="px-5 py-3">{t.members.joined}</th>
                <th className="px-5 py-3">{t.members.role}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((m) => (
                <tr key={m.id} className="border-b border-line last:border-0">
                  <td className="px-5 py-3">
                    <div className="font-semibold">{m.full_name ?? "—"}</div>
                    {m.phone && <div className="text-xs text-muted">{m.phone}</div>}
                  </td>
                  <td className="px-5 py-3">{t.langs[m.preferred_language]}</td>
                  <td className="px-5 py-3 capitalize">{formatDate(m.created_at, lang)}</td>
                  <td className="px-5 py-3">
                    {staff.role === "admin" && m.id !== staff.id ? (
                      <select className="input w-auto py-1.5" value={m.role} onChange={(e) => changeRole(m, e.target.value as StaffRole)}>
                        {ROLES.map((r) => (
                          <option key={r} value={r}>{t.members.roles[r]}</option>
                        ))}
                      </select>
                    ) : (
                      <span className="badge bg-lavender text-purple">{t.members.roles[m.role]}</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
