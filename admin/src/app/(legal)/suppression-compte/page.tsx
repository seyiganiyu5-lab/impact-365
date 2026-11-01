import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { deletion } from "@/lib/legal";

export const metadata: Metadata = {
  title: `${deletion.fr.title} · IMPACT-365`,
  description: deletion.fr.intro,
  alternates: { languages: { en: "/delete-account" } },
};

export default function Page() {
  return <LegalPage doc={deletion.fr} lang="fr" kind="deletion" />;
}
