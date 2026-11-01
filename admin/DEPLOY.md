# Putting the admin website online

Goal: the admin website at **https://admin.impact365jours.com**, updated
automatically each time the code changes on GitHub. Hosting: **Vercel**
(made by the creators of Next.js; the free *Hobby* plan is enough to start).

You need: the GitHub account that owns `seyiganiyu5-lab/impact-365`, access
to the place where you bought `impact365jours.com` (DNS), and your Supabase
dashboard.

---

## 1. Create the site on Vercel

1. Go to **vercel.com** → **Sign Up** → **Continue with GitHub**.
2. **Add New… → Project**. Find `impact-365` and click **Import**.
   *Not in the list?* Click **Adjust GitHub App Permissions** and allow the
   `impact-365` repository.
3. **Root Directory** → **Edit** → choose **`admin`**. Framework: *Next.js*
   (detected automatically). Leave the build settings as they are.
4. **Environment Variables**: add these two. Copy them from
   `mobile/env.json`; they are the same values as the app:

   | Name | Value |
   |---|---|
   | `NEXT_PUBLIC_SUPABASE_URL` | `https://xxxx.supabase.co` (your `SUPABASE_URL`) |
   | `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_…` (your publishable key) |

   ⚠️ Never put the **secret** / **service_role** key here, or anywhere in
   the website or the app.
5. Click **Deploy**. After about a minute you get an address like
   `impact-365-xxxx.vercel.app`.

## 2. Use your own address: admin.impact365jours.com

1. Vercel → your project → **Settings → Domains** → type
   `admin.impact365jours.com` → **Add**.
2. Vercel shows one DNS record to create, usually:

   | Type | Name | Value |
   |---|---|---|
   | CNAME | `admin` | the value Vercel shows (copy it exactly) |

3. Add it where you manage the domain's DNS (the same place as the Resend
   records). Wait a few minutes until Vercel shows **Valid Configuration**.
   HTTPS (the padlock) is set up automatically.

## 3. Let Google sign-in come back to the website (Supabase)

Supabase → **Authentication → URL Configuration → Redirect URLs** →
**Add URL**:

```
https://admin.impact365jours.com/auth/callback
```

Keep the app's existing entries. Do **not** change the *Site URL*.
(Optional: to test Google sign-in on the `….vercel.app` address too, add
`https://YOUR-ADDRESS.vercel.app/auth/callback` the same way.)

(This return address is used by the fallback Google sign-in; step 4 below
sets up the better one.)

## 4. Show your address on the Google page (instead of supabase.co)

The website uses Google's own sign-in button, so Google's window shows
your site's address. It needs one more setting:

1. **Google Cloud Console → APIs & Services → Credentials** → open your
   **Web** OAuth client (the one whose ID and secret are in Supabase →
   Authentication → Providers → Google).
2. **Authorized JavaScript origins** → **Add URI**:
   `https://admin.impact365jours.com` (and `http://localhost:3000` to test
   on your computer) → **Save**.
3. Copy that **Client ID** (`…apps.googleusercontent.com`).
4. Vercel → **Settings → Environment Variables** → add
   `NEXT_PUBLIC_GOOGLE_CLIENT_ID` = that Client ID, **Type: Config** (a
   client ID is public, not a secret) → **Save** → **Redeploy**.

Without this variable the website still works: the Google button then goes
through Supabase's address, as before.

## 5. Check

- Open https://admin.impact365jours.com → you land on the login page.
- Sign in with your admin account (email + password, or **Continuer avec
  Google**).
- A normal member who signs in sees **"Accès réservé"**: only leaders,
  pastors and admins get in (also enforced by the database).

## Updates

Every push to the GitHub branch Vercel follows redeploys the site
automatically. Vercel → **Deployments** lists each version; **Instant
Rollback** goes back to an earlier one if needed.

## Good to know

- The Hobby plan is meant for non-commercial projects. If Vercel ever asks,
  the **Pro** plan removes that limit.
