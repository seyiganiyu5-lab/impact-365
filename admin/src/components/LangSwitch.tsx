"use client";

import { useI18n } from "@/lib/i18n";

export function LangSwitch({ dark = false }: { dark?: boolean }) {
  const { lang, setLang } = useI18n();
  return (
    <div className={`inline-flex rounded-lg p-0.5 text-xs font-semibold ${dark ? "bg-white/10" : "bg-lavender"}`}>
      {(["fr", "en"] as const).map((l) => (
        <button
          key={l}
          onClick={() => setLang(l)}
          className={`cursor-pointer rounded-md px-2.5 py-1 uppercase ${
            lang === l ? "bg-gold text-white" : dark ? "text-white/70" : "text-muted"
          }`}
        >
          {l}
        </button>
      ))}
    </div>
  );
}
