import type { NextConfig } from "next";

const supabase = (process.env.NEXT_PUBLIC_SUPABASE_URL ?? "").trim();

/** Origin of the Supabase project, with a clear message if the setting is wrong. */
function originOf(url: string): string {
  if (!url) return "";
  try {
    const u = new URL(url);
    const local = u.hostname === "localhost" || u.hostname === "127.0.0.1";
    // https in production; http only for a local Supabase (supabase start).
    if (u.protocol === "https:" || local) return u.origin;
  } catch {
    // Explained below.
  }
  throw new Error(
    `NEXT_PUBLIC_SUPABASE_URL must be your Supabase address, like ` +
      `https://xxxx.supabase.co (Supabase → Project Settings → API). ` +
      `Current value: "${url}". On Vercel: Settings → Environment Variables.`,
  );
}

const supabaseOrigin = originOf(supabase);
const supabaseSocket = supabaseOrigin.replace(/^http/, "ws");
const isDev = process.env.NODE_ENV !== "production";

// Browser-side protections for the admin website.
const contentSecurityPolicy = [
  "default-src 'self'",
  // Next.js needs inline scripts; eval only in development (hot reload).
  // accounts.google.com: Google's "Sign in with Google" button.
  `script-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/client${isDev ? " 'unsafe-eval'" : ""}`,
  "style-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/style",
  "frame-src https://accounts.google.com/gsi/",
  "img-src 'self' data: blob: https:",
  "media-src 'self' blob: https:",
  "font-src 'self' data:",
  // Only our own Supabase project (REST, auth, storage, realtime).
  `connect-src 'self' https://accounts.google.com/gsi/${supabaseOrigin ? ` ${supabaseOrigin} ${supabaseSocket}` : ""}`,
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
].join("; ");

const securityHeaders = [
  { key: "Content-Security-Policy", value: contentSecurityPolicy },
  // Never shown inside another site's frame (prevents click-jacking).
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), payment=()" },
  // Browsers only use HTTPS for this site once it is online.
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
];

const nextConfig: NextConfig = {
  poweredByHeader: false,
  async headers() {
    return [{ source: "/(.*)", headers: securityHeaders }];
  },
};

export default nextConfig;
