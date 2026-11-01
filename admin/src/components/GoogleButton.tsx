"use client";

import { useEffect, useRef } from "react";

/**
 * Google's own "Sign in with Google" button (Google Identity Services).
 * Google shows the website's address on its sign-in window (not the
 * Supabase address), and hands back an ID token that we pass to Supabase.
 *
 * Needs NEXT_PUBLIC_GOOGLE_CLIENT_ID: the *Web* client ID from Google Cloud
 * (the same one Supabase uses), with this site in "Authorized JavaScript
 * origins".
 */

type GsiCredential = { credential?: string };

type Gsi = {
  accounts: {
    id: {
      initialize(options: {
        client_id: string;
        callback: (response: GsiCredential) => void;
        nonce: string;
        ux_mode?: "popup";
        auto_select?: boolean;
        itp_support?: boolean;
        use_fedcm_for_button?: boolean;
      }): void;
      renderButton(
        parent: HTMLElement,
        options: Record<string, string | number>,
      ): void;
    };
  };
};

declare global {
  interface Window {
    google?: Gsi;
  }
}

export const googleClientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";

const SCRIPT_SRC = "https://accounts.google.com/gsi/client";

function loadScript(): Promise<void> {
  if (window.google?.accounts?.id) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(`script[src="${SCRIPT_SRC}"]`);
    const script = existing ?? document.createElement("script");
    script.addEventListener("load", () => resolve(), { once: true });
    script.addEventListener("error", () => reject(new Error("gsi_load")), { once: true });
    if (!existing) {
      script.src = SCRIPT_SRC;
      script.async = true;
      document.head.appendChild(script);
    }
  });
}

/** Random one-time value, and its SHA-256 (hex) for Google. */
async function makeNonce(): Promise<{ raw: string; hashed: string }> {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const raw = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(raw));
  const hashed = Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
  return { raw, hashed };
}

export function GoogleButton({
  lang,
  disabled,
  onToken,
  onError,
}: {
  lang: "fr" | "en";
  disabled?: boolean;
  /** Google's ID token + the raw nonce, to give to Supabase. */
  onToken: (idToken: string, nonce: string) => void;
  onError: () => void;
}) {
  const box = useRef<HTMLDivElement>(null);
  // Latest callbacks without re-creating the button.
  const handlers = useRef({ onToken, onError });
  useEffect(() => {
    handlers.current = { onToken, onError };
  });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await loadScript();
        const { raw, hashed } = await makeNonce();
        const gsi = window.google;
        if (cancelled || !box.current || !gsi) return;
        gsi.accounts.id.initialize({
          client_id: googleClientId,
          nonce: hashed,
          ux_mode: "popup",
          auto_select: false,
          itp_support: true,
          use_fedcm_for_button: true,
          callback: (response) => {
            if (response.credential) {
              handlers.current.onToken(response.credential, raw);
            } else {
              handlers.current.onError();
            }
          },
        });
        box.current.innerHTML = "";
        gsi.accounts.id.renderButton(box.current, {
          type: "standard",
          theme: "outline",
          size: "large",
          text: "continue_with",
          shape: "rectangular",
          logo_alignment: "center",
          width: Math.min(box.current.clientWidth || 320, 400),
          locale: lang,
        });
      } catch {
        if (!cancelled) handlers.current.onError();
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [lang]);

  return (
    <div
      ref={box}
      aria-busy={disabled}
      className={`flex min-h-11 w-full justify-center ${disabled ? "pointer-events-none opacity-60" : ""}`}
    />
  );
}
