# IMPACT-365 — *1 jour, 1 impact*

A Christian church platform with two parts that share one **Supabase** database:

| Part | Folder | Who uses it | Tech |
|---|---|---|---|
| 📱 **Mobile app** (iOS + Android) | [`mobile/`](mobile) | Church members | Flutter |
| 🖥️ **Admin website** | [`admin/`](admin) | Admins, pastors, leaders | Next.js (React) |
| 🗄️ **Database** | [`supabase/`](supabase) | Both | Supabase (Postgres + Auth + Storage + Realtime) |

Anything an admin publishes on the website (a devotion, a challenge, an announcement, a reply) shows up in the app straight away, because both read the same database.

---

## What's inside

### Mobile app (members)
| Screen (from the design) | What it does |
|---|---|
| **Accueil** | Greeting, day X/365, streak, verse of the day, theme of the day, shortcuts, faith-journey card |
| **Parole** | Today's **morning / afternoon / night** devotions + previous days |
| **5 minutes avec Dieu** | Verse, *Ce que Dieu dit / Ce que je comprends / Ce que je fais*, "J'ai compris" button, audio player, "Ask a question" |
| **Mon Journal** | 3 private reflection questions + gratitude journal, one entry per day |
| **Ma Prayer Room** | My prayer points, answered prayers + testimonies, pray for others (community wall), journal, Holy SOS |
| **Ton impact du jour** | Daily challenge, weekly progress, impact streak, total impacts |
| **Holy SOS** | Ask for help (prayer, financial, health, emotional, studies/work, other), anonymous or not, *leaders only* option; help other members; follow my requests |
| **Messages & Notifications** | **Private 2-way chat with pastors/leaders** (live) + announcements |
| **Mon Profil** | Stats, personal info, language (FR / EN / Yorùbá), sign out |

### Admin website (staff only)
- **Dashboard**: members, open conversations, open SOS requests, prayers this week, devotions read today
- **Devotions**: 3 per day; write each one in **Français / English / Yorùbá**; upload a background image and audio
- **Daily challenges**: same multilingual editor
- **Private messages**: reply to members live, assign a conversation to yourself, close or reopen it
- **Holy SOS**: see every request (with the real name, even when anonymous to the community), change its status, leave a note the member can see, see who offered help
- **Shared prayers**: read and moderate the community prayer wall
- **Announcements**: send to everyone, or only to members of one language
- **Members**: list members; admins can promote people to leader / pastor / admin

### Languages
- **App:** French, English and Yorùbá (`mobile/lib/l10n/app_*.arb`). The Yorùbá text was machine-assisted, so **have a native speaker review `app_yo.arb`**.
- **Content** (devotions, challenges): admins fill in whichever languages they have. If a member's language is missing, the app shows French, then English.
- **Admin website:** French / English switch.

### Security
Every table uses Supabase **Row Level Security**, so the rules hold even if someone bypasses the app:
- A member's **journal** is visible only to that member (not even admins can read it).
- Private conversations are visible only to that member and the staff.
- Members cannot change their own role or publish content.
- Anonymous prayers and SOS requests hide the name from other members.

---

## 🚀 Set-up guide (step by step)

### 0. Install the tools (once)
1. [Visual Studio Code](https://code.visualstudio.com/)
2. [Git](https://git-scm.com/downloads)
3. [Flutter](https://docs.flutter.dev/get-started/install) **3.41 or newer** (includes Dart; check with `flutter --version`). Then run `flutter doctor` and follow its advice (Android Studio for Android, Xcode on a Mac for iOS).
4. [Node.js LTS](https://nodejs.org/) (for the admin website)

### 1. Open the project in VS Code
```bash
git clone https://github.com/seyiganiyu5-lab/impact-365.git
cd impact-365
git checkout claude/pensive-johnson-9y03el
code .
```
VS Code will offer to install the recommended extensions (Flutter, Dart, ESLint, Tailwind). Click **Install**.
To see new work later, run `git pull` (or use the **Source Control** tab → *Pull*).

### 2. Create the Supabase project
1. Go to [supabase.com](https://supabase.com), create a free account, then a **New project**.
2. Open **SQL Editor** → *New query*, paste the whole contents of
   [`supabase/migrations/20261004000000_init.sql`](supabase/migrations/20261004000000_init.sql) and click **Run**.
3. Optional but recommended: run [`supabase/seed.sql`](supabase/seed.sql) the same way. It adds sample devotions, a challenge and an announcement for **today**.
4. Go to **Project Settings → API Keys** and copy:
   - the **Project URL** (`https://xxxx.supabase.co`)
   - the **Publishable key** (`sb_publishable_...`; the older *anon* key also works)

> While testing, you can turn off **Authentication → Sign In / Providers → Email → Confirm email** so new accounts work immediately.

### 3. Run the admin website
```bash
cd admin
cp .env.example .env.local     # then paste your URL + publishable key inside
npm install
npm run dev
```
Open http://localhost:3000.

### 4. Run the mobile app
```bash
cd mobile
cp env.example.json env.json   # then paste your URL + publishable key inside
flutter pub get
flutter run --dart-define-from-file=env.json
```
Or in VS Code: open **Run and Debug** (Ctrl/Cmd + Shift + D), pick **📱 Mobile app (Flutter)** and press **F5**. Start an Android emulator or iOS simulator first, or plug in a phone.

### 5. Make yourself an admin
1. Create an account in the app (or in Supabase → **Authentication → Users → Add user**).
2. In the Supabase **SQL Editor**, run:
   ```sql
   update public.profiles
   set role = 'admin'
   where id = (select id from auth.users where email = 'YOUR-EMAIL@example.com');
   ```
3. Sign in to the admin website with that account. From then on you can promote other pastors and leaders from the **Members** page.

Roles: `member` (app only) · `leader` and `pastor` (admin website) · `admin` (admin website + can change roles).

---

## Project structure
```
impact-365/
├── mobile/                     Flutter app
│   ├── lib/
│   │   ├── main.dart           start-up (Supabase init)
│   │   ├── app.dart            theme + languages + router
│   │   ├── core/               theme colors, router, language controller
│   │   ├── data/               models + repository (all Supabase calls)
│   │   ├── features/           one folder per screen (home, devotion, prayer, sos, inbox…)
│   │   ├── widgets/            shared UI pieces (cards, buttons, logo…)
│   │   └── l10n/               app_fr.arb, app_en.arb, app_yo.arb (translations)
│   └── test/                   unit tests
├── admin/                      Next.js admin website
│   └── src/
│       ├── app/login/          sign-in page
│       ├── app/(admin)/        dashboard, devotions, challenges, concerns, sos, prayers, announcements, members
│       ├── components/         shared UI
│       ├── lib/                Supabase client, FR/EN dictionary, staff context
│       └── proxy.ts            redirects signed-out visitors to /login
└── supabase/
    ├── migrations/             database schema + security rules
    └── seed.sql                sample content
```

## Useful commands
| | Mobile (`cd mobile`) | Admin (`cd admin`) |
|---|---|---|
| Run | `flutter run --dart-define-from-file=env.json` | `npm run dev` |
| Check code | `flutter analyze` | `npm run lint` |
| Tests / build | `flutter test` | `npm run build` |
| After editing translations | `flutter gen-l10n` | — |
| After changing the app icon (`mobile/assets/icon/`) | `dart run flutter_launcher_icons` | — |

## Next steps (not built yet)
- Push notifications (Firebase Cloud Messaging) for new devotions, replies and reminders (*Rappels* screen)
- *Mon groupe* (groups, discussions, group challenges)
- Audio teaching library (*Lecture audio*) and offline downloads
- Deploying the admin website (e.g. Vercel) and publishing the app to the stores
