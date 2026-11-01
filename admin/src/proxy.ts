import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

/**
 * Runs before every page: refreshes the Supabase session cookie and sends
 * signed-out visitors to /login. Role checks (admin / pastor / leader) happen
 * in the dashboard layout and, most importantly, in the database (RLS).
 */
/** Pages anyone can open, signed in or not (required by the app stores). */
const PUBLIC_PAGES = ["/confidentialite", "/privacy", "/suppression-compte", "/delete-account"];

/** The main domain (impact365jours.com) only shows the public pages. */
const PUBLIC_ONLY_HOSTS = ["impact365jours.com", "www.impact365jours.com"];

function isPublicPage(path: string) {
  return PUBLIC_PAGES.some((p) => path === p || path.startsWith(`${p}/`));
}

export async function proxy(request: NextRequest) {
  const path = request.nextUrl.pathname;
  const host = (request.headers.get("host") ?? "").split(":")[0].toLowerCase();

  if (isPublicPage(path)) return NextResponse.next({ request });
  if (PUBLIC_ONLY_HOSTS.includes(host)) {
    return NextResponse.redirect(new URL("/confidentialite", request.url));
  }

  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const { data } = await supabase.auth.getClaims();
  const signedIn = !!data?.claims;
  const onLogin = path.startsWith("/login");

  // Google sign-in comes back here before the session exists.
  if (path.startsWith("/auth/callback")) return response;

  if (!signedIn && !onLogin) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  if (signedIn && onLogin) {
    return NextResponse.redirect(new URL("/", request.url));
  }
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
