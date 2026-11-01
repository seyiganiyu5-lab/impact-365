import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { privacy } from "@/lib/legal";

export const metadata: Metadata = {
  title: `${privacy.en.title} · IMPACT-365`,
  description: privacy.en.intro,
  alternates: { languages: { fr: "/confidentialite" } },
};

export default function Page() {
  return <LegalPage doc={privacy.en} lang="en" kind="privacy" />;
}
