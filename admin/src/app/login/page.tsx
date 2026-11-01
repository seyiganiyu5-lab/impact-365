"use client";

import { useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase/client";
import { useI18n } from "@/lib/i18n";
import { Logo } from "@/components/Logo";
import { LangSwitch } from "@/components/LangSwitch";
import { GoogleButton, googleClientId } from "@/components/GoogleButton";

export default function LoginPage() {
  const { t, lang } = useI18n();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const [tried, setTried] = useState(false);

  // Back from a Google sign-in that did not complete (?error=google).
  const googleFailed = useSyncExternalStore(
    () => () => {},
    () => new URLSearchParams(window.location.search).get("error") === "google",
    () => false,
  );
  const shownError = error ?? (googleFailed && !tried ? t.login.googleError : null);

  // Google's own button: Google shows this website's address.
  async function onGoogleToken(idToken: string, nonce: string) {
    setTried(true);
    setBusy(true);
    setError(null);
    const { error } = await supabase().auth.signInWithIdToken({
      provider: "google",
      token: idToken,
      nonce,
    });
    if (error) {
      setBusy(false);
      setError(t.login.googleError);
      return;
    }
    router.replace("/");
    router.refresh();
  }

  // Fallback (no Google client ID set): goes through Supabase's address.
  async function onGoogle() {
    setTried(true);
    setBusy(true);
    setError(null);
    const { error } = await supabase().auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    });
    // On success the browser is already leaving for Google.
    if (error) {
      setBusy(false);
      setError(t.login.googleError);
    }
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setTried(true);
    setBusy(true);
    setError(null);
    const { error } = await supabase().auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) {
      setError(t.login.error);
      return;
    }
    router.replace("/");
    router.refresh();
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-b from-purple-dark via-[#7a4e8c] to-gold p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex items-center justify-between">
          <Logo light />
          <LangSwitch dark />
        </div>
        <form onSubmit={onSubmit} className="card space-y-4 p-7">
          <div>
            <h1 className="text-2xl font-extrabold text-purple">{t.login.title}</h1>
            <p className="mt-1 text-sm text-muted">{t.login.subtitle}</p>
          </div>
          <div>
            <label className="label" htmlFor="email">{t.login.email}</label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div>
            <label className="label" htmlFor="password">{t.login.password}</label>
            <input
              id="password"
              type="password"
              required
              autoComplete="current-password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          {shownError && <p className="text-sm text-red-700">{shownError}</p>}
          <button type="submit" disabled={busy} className="btn-gold w-full py-3">
            {busy ? t.common.loading : t.login.submit}
          </button>
          <div className="flex items-center gap-3 text-xs text-muted">
            <span className="h-px flex-1 bg-current opacity-20" />
            {t.login.or}
            <span className="h-px flex-1 bg-current opacity-20" />
          </div>
          {googleClientId ? (
            <GoogleButton
              lang={lang}
              disabled={busy}
              onToken={onGoogleToken}
              onError={() => {
                setTried(true);
                setError(t.login.googleError);
              }}
            />
          ) : (
            <button
              type="button"
              onClick={onGoogle}
              disabled={busy}
              className="flex w-full items-center justify-center gap-3 rounded-xl border border-black/10 bg-white py-3 font-semibold text-ink transition hover:bg-black/[0.03] disabled:opacity-60"
            >
              <GoogleMark />
              {t.login.google}
            </button>
          )}
        </form>
      </div>
    </main>
  );
}

/** Google "G" (official colours), drawn inline: no outside image. */
function GoogleMark() {
  return (
    <svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true">
      <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z" />
      <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z" />
      <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z" />
      <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z" />
    </svg>
  );
}
