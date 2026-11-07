import Link from "next/link";
import { Logo } from "@/components/Logo";
import { LEGAL, type Block, type LegalDoc, type LegalLang } from "@/lib/legal";

/** `**bold**` → <strong>. */
function rich(text: string) {
  return text.split(/(\*\*[^*]+\*\*)/g).map((part, i) =>
    part.startsWith("**") && part.endsWith("**") ? (
      <strong key={i} className="font-semibold text-ink">
        {part.slice(2, -2)}
      </strong>
    ) : (
      part
    ),
  );
}

function BlockView({ block }: { block: Block }) {
  if (typeof block === "string") {
    return <p className="leading-relaxed">{rich(block)}</p>;
  }
  return (
    <ul className="space-y-2">
      {block.list.map((item, i) => (
        <li key={i} className="flex gap-3 leading-relaxed">
          <span aria-hidden className="mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-gold" />
          <span>{rich(item)}</span>
        </li>
      ))}
    </ul>
  );
}

const nav: Record<LegalLang, { privacy: string; deletion: string; other: string; contents: string }> = {
  fr: {
    privacy: "Confidentialité",
    deletion: "Supprimer mon compte",
    other: "English",
    contents: "Sommaire",
  },
  en: {
    privacy: "Privacy",
    deletion: "Delete my account",
    other: "Français",
    contents: "Contents",
  },
};

const paths: Record<LegalLang, { privacy: string; deletion: string }> = {
  fr: { privacy: "/confidentialite", deletion: "/suppression-compte" },
  en: { privacy: "/privacy", deletion: "/delete-account" },
};

/** Public page (no sign-in): privacy policy or account deletion. */
export function LegalPage({
  doc,
  lang,
  kind,
}: {
  doc: LegalDoc;
  lang: LegalLang;
  kind: "privacy" | "deletion";
}) {
  const t = nav[lang];
  const other: LegalLang = lang === "fr" ? "en" : "fr";
  const showContents = doc.sections.length > 4;

  return (
    <div lang={lang} className="min-h-screen bg-cream">
      <header className="bg-gradient-to-br from-purple-dark via-purple to-purple-light text-white">
        <div className="mx-auto flex max-w-3xl flex-wrap items-center justify-between gap-4 px-5 pt-6">
          <Logo light />
          <nav className="flex flex-wrap items-center gap-2 text-sm font-semibold">
            <Link
              href={paths[lang].privacy}
              aria-current={kind === "privacy" ? "page" : undefined}
              className={`rounded-lg px-3 py-1.5 ${kind === "privacy" ? "bg-white/15" : "hover:bg-white/10"}`}
            >
              {t.privacy}
            </Link>
            <Link
              href={paths[lang].deletion}
              aria-current={kind === "deletion" ? "page" : undefined}
              className={`rounded-lg px-3 py-1.5 ${kind === "deletion" ? "bg-white/15" : "hover:bg-white/10"}`}
            >
              {t.deletion}
            </Link>
            <Link
              href={paths[other][kind]}
              hrefLang={other}
              className="rounded-lg border border-gold/60 px-3 py-1.5 text-gold hover:bg-gold/10"
            >
              {t.other}
            </Link>
          </nav>
        </div>
        <div className="mx-auto max-w-3xl px-5 pb-10 pt-10">
          <h1 className="text-3xl font-extrabold leading-tight sm:text-4xl">{doc.title}</h1>
          <p className="mt-2 text-sm text-gold-light">{doc.updatedLabel}</p>
          <p className="mt-5 max-w-2xl leading-relaxed text-white/85">{doc.intro}</p>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-5 py-8">
        {showContents && (
          <nav aria-label={t.contents} className="card mb-6">
            <h2 className="mb-3 text-sm font-bold uppercase tracking-wide text-muted">{t.contents}</h2>
            <ol className="grid grid-cols-1 gap-1.5 text-sm sm:grid-cols-2">
              {doc.sections.map((s) => (
                <li key={s.id}>
                  <a href={`#${s.id}`} className="inline-block py-1.5 text-purple hover:underline">
                    {s.title}
                  </a>
                </li>
              ))}
            </ol>
          </nav>
        )}

        <div className="space-y-5">
          {doc.sections.map((s) => (
            <section key={s.id} id={s.id} className="card scroll-mt-6">
              <h2 className="mb-3 text-xl font-bold text-purple">{s.title}</h2>
              <div className="space-y-3 text-[15px] text-ink/85">
                {s.blocks.map((b, i) => (
                  <BlockView key={i} block={b} />
                ))}
              </div>
            </section>
          ))}
        </div>

        <footer className="mt-10 border-t border-line pt-6 text-center text-sm text-muted">
          <p>
            © {LEGAL.publisher} · {LEGAL.country[lang]} ·{" "}
            <a href={`mailto:${LEGAL.email}`} className="font-semibold text-purple hover:underline">
              {LEGAL.email}
            </a>
          </p>
        </footer>
      </main>
    </div>
  );
}
