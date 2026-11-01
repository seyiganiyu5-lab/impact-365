import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { privacy } from "@/lib/legal";

export const metadata: Metadata = {
  title: `${privacy.fr.title} · IMPACT-365`,
  description: privacy.fr.intro,
  alternates: { languages: { en: "/privacy" } },
};

export default function Page() {
  return <LegalPage doc={privacy.fr} lang="fr" kind="privacy" />;
}
