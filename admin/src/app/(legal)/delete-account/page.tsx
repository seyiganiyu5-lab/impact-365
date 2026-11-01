import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { deletion } from "@/lib/legal";

export const metadata: Metadata = {
  title: `${deletion.en.title} · IMPACT-365`,
  description: deletion.en.intro,
  alternates: { languages: { fr: "/suppression-compte" } },
};

export default function Page() {
  return <LegalPage doc={deletion.en} lang="en" kind="deletion" />;
}
