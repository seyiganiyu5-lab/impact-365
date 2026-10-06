# Authentication setup (Supabase) — step by step

Follow these steps once in your Supabase dashboard. They make sign-up, sign-in,
email confirmation and **forgot password** work end to end with the app.

How it works: Supabase sends the emails. Their links point to `impact365://…`,
the app's own link scheme, so tapping the link **opens the app**:
- `impact365://login-callback`: the account is confirmed and the user is signed in.
- `impact365://reset-password`: the app opens the **"Nouveau mot de passe"** screen.

---

## 1. Database

1. **SQL Editor** → run `supabase/migrations/20261004000000_init.sql` (skip it if you already ran it).
2. **SQL Editor** → run `supabase/migrations/20261006000000_profile_self_heal.sql`.
3. **SQL Editor** → run `supabase/verify.sql`. Every line must show ✅. It also repairs accounts created before the database was set up.
4. Make yourself admin (the last check in `verify.sql` shows the exact command).

## 2. URL configuration ⚠️ required

**Authentication → URL Configuration**

| Setting | Value |
|---|---|
| Site URL | `impact365://login-callback` (change it to your admin website address once it is online) |
| Redirect URLs → *Add URL* | `impact365://**` |

Without the redirect URL, email links open a browser page saying "page not found" instead of the app.

## 3. Email sign-in settings

**Authentication → Sign In / Providers → Email**

| Setting | Recommended |
|---|---|
| Enable Email provider | ON |
| Confirm email | **ON** for the real launch. You can turn it OFF while testing so new accounts work immediately. |
| Secure email change | ON |
| Minimum password length | 6 (the app asks for at least 6) |

## 4. Email templates (French / English / Yoruba)

**Authentication → Email Templates.** For each template, paste the subject and the whole file:

| Template | Subject | File |
|---|---|---|
| Confirm signup | `Confirme ton compte IMPACT-365 · Confirm your account` | `supabase/templates/confirmation.html` |
| Reset password | `Réinitialise ton mot de passe · Reset your password` | `supabase/templates/recovery.html` |
| Change email address | `Confirme ta nouvelle adresse · Confirm your new email` | `supabase/templates/email_change.html` |
| Magic link | `Ton lien de connexion · Your sign-in link` | `supabase/templates/magic_link.html` |

The body of each email switches language automatically, using the language the person chose in the app (French by default).

## 5. Sending real emails (SMTP)

Supabase's built-in email service is **for testing only**:
- It only sends to email addresses of people in your Supabase team (your own address works).
- It sends only a few emails per hour.

That is fine while you test with your own email. Before church members use the app, connect a real sender. You do **not** need to buy a domain.

### Option A: a free Gmail account (no domain needed, recommended to start)
1. Create a Gmail account for the app, e.g. `impact365.app@gmail.com`.
2. In that Google account: **Security** → turn on **2-Step Verification**.
3. Then go to https://myaccount.google.com/apppasswords → create an app password named "Supabase". Google shows a 16-letter password: copy it.
4. Supabase → **Authentication → Emails → SMTP Settings** → *Enable custom SMTP*:

   | Field | Value |
   |---|---|
   | Sender email | `impact365.app@gmail.com` |
   | Sender name | `IMPACT-365` |
   | Host | `smtp.gmail.com` |
   | Port | `465` |
   | Username | `impact365.app@gmail.com` |
   | Password | the 16-letter app password (no spaces) |

5. **Authentication → Rate Limits** → "emails per hour": set e.g. `50`.

Gmail allows about 500 emails per day, which is plenty for a church app.

### Option B: later, with your own domain
When the church buys a domain (e.g. `impact365.org`), use a sender such as **Resend** or **Brevo** with `noreply@impact365.org` for the most professional result. Only the SMTP settings change; nothing in the app changes.

## 6. Test checklist (on your phone)

Run the app with `flutter run --dart-define-from-file=env.json`, then check each item:

- [ ] **Sign up** with a real email → "Vérifie ta boîte mail" appears.
- [ ] The confirmation email arrives (check spam) and shows the IMPACT-365 design.
- [ ] Tapping **Confirmer mon e-mail** opens the app and you land on the home screen.
- [ ] **Renvoyer l'e-mail** works after the 60-second wait.
- [ ] **Sign out** (Profile tab) → **sign in** with the same account → home screen.
- [ ] Wrong password → "E-mail ou mot de passe incorrect."
- [ ] Signing up again with the same email → "Un compte existe déjà avec cet e-mail."
- [ ] **Mot de passe oublié ?** → enter your email → "Lien envoyé !"
- [ ] The reset email arrives; tapping **Choisir un nouveau mot de passe** opens the app on **Nouveau mot de passe**.
- [ ] Save a new password → you land on the home screen, and you can sign in with the new password.
- [ ] Opening the same reset link a second time → "Ce lien a expiré ou a déjà été utilisé."

Open the email links **on the phone where the app is installed**. For security, a reset link only works on the device that asked for it.

To check that the phone recognises the app's links without sending an email, plug in the Android phone and run:
```bash
adb shell am start -a android.intent.action.VIEW -d "impact365://login-callback"
```
The app should open.

## Troubleshooting

| Problem | Fix |
|---|---|
| The link opens a browser saying "page not found" or "localhost" | Step 2: add `impact365://**` to Redirect URLs. |
| No email arrives | Check spam. With the built-in sender, only team members receive emails (step 5). With Gmail, check that the app password has no spaces. |
| "Email not confirmed" when signing in | Open the confirmation email, or use **Renvoyer l'e-mail**. |
| "Trop de tentatives" | You hit the email rate limit; wait or raise it (step 5.4). |
| The app shows an error right after signing in | Run `supabase/verify.sql`: a ❌ line tells you what is missing. |
| "Ce lien a expiré" | Reset links last one hour and work once. Request a new one. |
