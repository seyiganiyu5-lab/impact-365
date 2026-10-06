# Authentication setup (Supabase) — step by step

Follow these steps once in your Supabase dashboard. They make sign-up, sign-in,
email confirmation and **forgot password** work end to end with the app.

How it works: Supabase sends an email with a **6-digit code**. The person types
it in the app, so it works even if they read their email on a computer:
- **Sign up**: the code confirms the account and signs the person in.
- **Forgot password**: the code opens the **"Nouveau mot de passe"** screen.

(Opening an `impact365://…` link still works too, but the emails now show the code instead.)

---

## 1. Database

1. **SQL Editor** → run `supabase/migrations/20261004000000_init.sql` (skip it if you already ran it).
2. **SQL Editor** → run `supabase/migrations/20261006000000_profile_self_heal.sql`.
3. **SQL Editor** → run `supabase/migrations/20261007000000_security_hardening.sql` (security rules and rate limits, see step 7).
4. **SQL Editor** → run `supabase/verify.sql`. Every line must show ✅. It also repairs accounts created before the database was set up.
5. Make yourself admin (the last check in `verify.sql` shows the exact command).

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
| Secure password change | ON |
| Minimum password length | **8** (the app asks for at least 8) |
| Password Requirements | **Letters and digits** (the app asks for the same) |
| Email OTP Expiration | **`600`** (the code is valid for 10 minutes) |
| Email OTP Length | **`6`** (the app shows 6 boxes) ⚠️ |

## 4. Email templates (French / English / Yoruba)

**Authentication → Email Templates.** For each template, paste the subject and the whole file:

| Template | Subject | File |
|---|---|---|
| Confirm signup | `Ton code IMPACT-365 : {{ .Token }}` | `supabase/templates/confirmation.html` |
| Reset password | `Code pour ton nouveau mot de passe : {{ .Token }}` | `supabase/templates/recovery.html` |
| Change email address | `Confirme ta nouvelle adresse · Confirm your new email` | `supabase/templates/email_change.html` |
| Magic link | `Ton lien de connexion · Your sign-in link` | `supabase/templates/magic_link.html` |

`{{ .Token }}` is replaced by the 6-digit code, so it appears in the subject and in the email. The body of each email switches language automatically, using the language the person chose in the app (French by default).

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

**If the Auth logs show `context deadline exceeded`**, Supabase could not reach Gmail's server in time. Change **Port** to `587`, save, and try again (if you were already on 587, try 465). Then check that *Host* is exactly `smtp.gmail.com` with no spaces. If it still fails, create a new app password and paste it again.

### Option A2: Brevo (free, no domain needed)
Use this if Gmail keeps timing out.
1. Create a free account at https://www.brevo.com (300 emails per day).
2. **Senders, Domains & Dedicated IPs → Senders** → add your Gmail address and confirm it from the email Brevo sends you.
3. **SMTP & API → SMTP** → generate an SMTP key and note the *Login* shown on that page (it looks like `xxxx@smtp-brevo.com`).
4. Supabase → **SMTP Settings**:

   | Field | Value |
   |---|---|
   | Sender email | your confirmed Gmail address |
   | Sender name | `IMPACT-365` |
   | Host | `smtp-relay.brevo.com` |
   | Port | `587` |
   | Username | the Brevo SMTP *Login* (not your Gmail address) |
   | Password | the Brevo SMTP key |

Emails sent "from" a Gmail address through another service sometimes land in spam. Ask testers to check spam and mark the first email "Not spam". A domain (Option B) removes this problem.

### Option B: later, with your own domain
When the church buys a domain (e.g. `impact365.org`), use a sender such as **Resend** or **Brevo** with `noreply@impact365.org` for the most professional result. Only the SMTP settings change; nothing in the app changes.

## 6. Test checklist (on your phone)

Run the app with `flutter run --dart-define-from-file=env.json`, then check each item:

- [ ] **Sign up** with a real email → "Vérifie ta boîte mail" appears with 6 boxes.
- [ ] The email arrives (check spam) with the IMPACT-365 design and a 6-digit code.
- [ ] Type the code → you land on the home screen.
- [ ] A wrong code → "Ce code est incorrect ou a expiré."
- [ ] **Renvoyer le code** works after the 60-second wait (only the newest code works).
- [ ] **Sign out** (Profile tab) → **sign in** with the same account → home screen.
- [ ] Wrong password → "E-mail ou mot de passe incorrect."
- [ ] Signing up again with the same email → "Un compte existe déjà avec cet e-mail."
- [ ] **Mot de passe oublié ?** → enter your email → "Code envoyé !" and the 6 boxes appear.
- [ ] Type the code from the email → **Nouveau mot de passe** opens.
- [ ] Save a new password → you land on the home screen, and you can sign in with the new password.
- [ ] Using the same code a second time → "Ce code est incorrect ou a expiré."

## 7. Security and rate limits

### What is already built in
| Protection | Where |
|---|---|
| Every table is locked by Row Level Security: a member only sees and changes their own data; the journal is private even from leaders | Database |
| Members cannot make themselves leader or admin, edit sent messages, fake a "from the pastor" message, write staff notes, or reach leaders-only requests and private prayers by guessing their id | Database (security migration) |
| **Rate limits per member:** 10 prayer points per hour (30 per day), 3 Holy SOS per hour (10 per day), 10 offers of help per hour, 3 new conversations per hour (10 per day), 15 chat messages per minute (300 per day), 100 "I prayed" per hour. Leaders and admins are not limited | Database (security migration) |
| Size limits on every text field | Database |
| Signed-out visitors cannot write anything | Database |
| 6-digit codes expire after 10 minutes and work once; after 5 wrong codes the app asks for a new one | Supabase + app |
| After 5 failed sign-ins, the app waits 30 s before allowing another try, then longer each time (up to 5 min) | App |
| Passwords: at least 8 characters with letters and digits | Supabase + app |
| After a password reset, every other phone signed in to the account is signed out | App |
| The login session is stored encrypted (Android Keystore / iPhone Keychain) and is not copied into phone backups | App |
| Admin website: blocks being shown inside other sites, only talks to your Supabase project, forces HTTPS once online | Admin website |

### Rate limits in Supabase (do this once)
**Authentication → Rate Limits.** These protect sign-in, sign-up and codes per IP address (one phone or one Wi-Fi network):

| Setting | Recommended | Why |
|---|---|---|
| Rate limit for sending emails | `30` per hour | Stops someone flooding inboxes with codes |
| Rate limit for sign-ups and sign-ins | `30` per 5 minutes | Stops password guessing. Not lower: members on the church Wi-Fi share one IP address |
| Rate limit for token verifications | `30` per 5 minutes | Stops guessing 6-digit codes (1,000,000 possibilities, 30 tries per 5 minutes, codes expire after 10 minutes) |
| Rate limit for token refreshes | keep the default (`150`) | |
| Rate limit for anonymous users | keep the default | The app doesn't use anonymous sign-in |

### Keep these secret
- The app and the admin website only use the **publishable (anon) key**. It is safe to ship because the database rules above protect the data.
- **Never** put the `service_role` / secret key in the app, the admin website, or GitHub. It bypasses every rule.
- Give the admin role to as few people as possible and ask them to use a strong password they don't use anywhere else.

### Optional extras (later)
- **Leaked password protection** (Authentication → Attack Protection): refuses passwords that appeared in known data leaks. It needs the Supabase Pro plan.
- **CAPTCHA** (Authentication → Attack Protection → Cloudflare Turnstile, free): blocks robots on sign-up. The app needs a small change first, so ask before turning it on, otherwise sign-up stops working.
- **Two-step login for admins** on the admin website.

## Troubleshooting

| Problem | Fix |
|---|---|
| The link opens a browser saying "page not found" or "localhost" | Step 2: add `impact365://**` to Redirect URLs. |
| No email arrives | Check spam. With the built-in sender, only team members receive emails (step 5). With Gmail, check that the app password has no spaces. |
| "Email not confirmed" when signing in | Open the confirmation email, or use **Renvoyer l'e-mail**. |
| "Trop de tentatives" | You hit the email rate limit; wait or raise it (step 5.4). |
| "Tu le fais trop souvent" in the app | A member reached a rate limit from step 7 (e.g. more than 3 Holy SOS in an hour). It clears by itself. To change a limit, edit the numbers in `20261007000000_security_hardening.sql`, then drop and recreate that trigger. |
| The app shows an error right after signing in | Run `supabase/verify.sql`: a ❌ line tells you what is missing. |
| "Ce code est incorrect ou a expiré" | Codes last 10 minutes and work once; after **Renvoyer le code**, only the newest code works. |
| The email shows a code with more than 6 digits | Set **Email OTP Length** to `6` (step 3). |
| The email shows a button instead of a code | Paste the new templates again (step 4). |
| The button keeps loading, then "Impossible d'envoyer l'e-mail" or "Le serveur met trop de temps" | Supabase cannot connect to your SMTP sender. Open **Logs → Auth** in Supabase to see the exact error. With Gmail: use the 16-letter **app password** (no spaces), and the same Gmail address in *Username* and *Sender email*. To check everything else works, temporarily switch custom SMTP off and test with your own email. |
| Auth logs say `context deadline exceeded` | Supabase timed out connecting to the SMTP server. Switch the port (465 ↔ 587). If Gmail still fails, use Brevo (Option A2). |
