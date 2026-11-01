import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";

/**
 * Google sends the leader back here with a one-time code. We swap it for a
 * session (saved in cookies), then open the dashboard. Whether the account
 * may use the admin area is checked by the dashboard layout and the
 * database, exactly as for email sign-in.
 */
export async function GET(request: NextRequest) {
  const url = request.nextUrl;
  const code = url.searchParams.get("code");
  const failed = new URL("/login?error=google", url.origin);

  if (!code) return NextResponse.redirect(failed);

  const cookieStore = await cookies();
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        },
      },
    },
  );

  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return NextResponse.redirect(failed);

  // Always our own dashboard: never a destination taken from the address.
  return NextResponse.redirect(new URL("/", url.origin));
}
