import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { I18nProvider } from "@/lib/i18n";
import "./globals.css";

const inter = Inter({ variable: "--font-inter", subsets: ["latin", "latin-ext"] });

export const metadata: Metadata = {
  title: "Impact-365 Admin",
  description: "Espace responsables Impact-365 — dévotions, défis, messages et Holy SOS.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="fr" className={`${inter.variable} h-full antialiased`}>
      <body className="min-h-full font-sans">
        <I18nProvider>{children}</I18nProvider>
      </body>
    </html>
  );
}
