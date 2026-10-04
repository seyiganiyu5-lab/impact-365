-- =============================================================================
-- IMPACT-365 — initial schema
-- Mobile app (Flutter) = members.  Admin website (Next.js) = admin / pastor / leader.
-- Every table is protected by Row Level Security (RLS).
-- =============================================================================

create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- Enums
-- -----------------------------------------------------------------------------
create type public.user_role         as enum ('member', 'leader', 'pastor', 'admin');
create type public.app_language      as enum ('fr', 'en', 'yo');
create type public.devotion_slot     as enum ('morning', 'afternoon', 'night');
create type public.help_category     as enum ('prayer', 'financial', 'health', 'emotional', 'studies_work', 'other');
create type public.help_status       as enum ('open', 'in_progress', 'resolved');
create type public.conversation_status as enum ('open', 'closed');

-- -----------------------------------------------------------------------------
-- Profiles (1 row per auth user)
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  full_name          text,
  avatar_url         text,
  phone              text,
  role               public.user_role    not null default 'member',
  preferred_language public.app_language not null default 'fr',
  created_at         timestamptz         not null default now(),
  updated_at         timestamptz         not null default now()
);

-- Staff = anyone allowed into the admin website.
create or replace function public.is_staff()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('leader', 'pastor', 'admin')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- Create a profile automatically when someone signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, preferred_language)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data ->> 'preferred_language')::public.app_language, 'fr')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Members must not be able to promote themselves. The SQL editor / service
-- role has no auth.uid(), which is how the very first admin is created.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only admins can change roles';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_protect_role
  before update on public.profiles
  for each row execute function public.protect_profile_role();

alter table public.profiles enable row level security;

create policy "profiles: read own or staff reads all"
  on public.profiles for select
  using (id = auth.uid() or public.is_staff());

create policy "profiles: update own"
  on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

create policy "profiles: admin updates any"
  on public.profiles for update
  using (public.is_admin());

-- -----------------------------------------------------------------------------
-- Devotions — 3 per day (morning / afternoon / night), translated FR / EN / YO
-- -----------------------------------------------------------------------------
create table public.devotions (
  id            uuid primary key default gen_random_uuid(),
  devotion_date date                 not null,
  slot          public.devotion_slot not null,
  image_url     text,
  is_published  boolean              not null default false,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz          not null default now(),
  updated_at    timestamptz          not null default now(),
  unique (devotion_date, slot)
);

create table public.devotion_translations (
  devotion_id     uuid not null references public.devotions (id) on delete cascade,
  lang            public.app_language not null,
  theme           text,               -- "Thème du jour"
  verse_reference text not null,      -- e.g. "Matthieu 6:33"
  verse_text      text not null,
  god_says        text not null,      -- "Ce que Dieu dit"
  i_understand    text not null,      -- "Ce que je comprends"
  i_do            text not null,      -- "Ce que je fais"
  audio_url       text,               -- optional audio for this language
  primary key (devotion_id, lang)
);

create table public.devotion_completions (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  devotion_id  uuid not null references public.devotions (id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key (user_id, devotion_id)
);

alter table public.devotions             enable row level security;
alter table public.devotion_translations enable row level security;
alter table public.devotion_completions  enable row level security;

create policy "devotions: members read published, staff read all"
  on public.devotions for select
  using ((is_published and devotion_date <= current_date) or public.is_staff());
create policy "devotions: staff write"
  on public.devotions for all
  using (public.is_staff()) with check (public.is_staff());

create policy "devotion_translations: readable when devotion readable"
  on public.devotion_translations for select
  using (exists (select 1 from public.devotions d where d.id = devotion_id));
create policy "devotion_translations: staff write"
  on public.devotion_translations for all
  using (public.is_staff()) with check (public.is_staff());

create policy "devotion_completions: own rows"
  on public.devotion_completions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "devotion_completions: staff read"
  on public.devotion_completions for select
  using (public.is_staff());

-- -----------------------------------------------------------------------------
-- Daily challenges ("Ton impact du jour")
-- -----------------------------------------------------------------------------
create table public.challenges (
  id             uuid primary key default gen_random_uuid(),
  challenge_date date    not null unique,
  image_url      text,
  is_published   boolean not null default false,
  created_by     uuid references public.profiles (id) on delete set null,
  created_at     timestamptz not null default now()
);

create table public.challenge_translations (
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  lang         public.app_language not null,
  title        text not null,
  description  text,
  verse_reference text,
  verse_text      text,
  primary key (challenge_id, lang)
);

create table public.challenge_completions (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  note         text,
  completed_at timestamptz not null default now(),
  primary key (user_id, challenge_id)
);

alter table public.challenges             enable row level security;
alter table public.challenge_translations enable row level security;
alter table public.challenge_completions  enable row level security;

create policy "challenges: members read published, staff read all"
  on public.challenges for select
  using ((is_published and challenge_date <= current_date) or public.is_staff());
create policy "challenges: staff write"
  on public.challenges for all
  using (public.is_staff()) with check (public.is_staff());

create policy "challenge_translations: readable when challenge readable"
  on public.challenge_translations for select
  using (exists (select 1 from public.challenges c where c.id = challenge_id));
create policy "challenge_translations: staff write"
  on public.challenge_translations for all
  using (public.is_staff()) with check (public.is_staff());

create policy "challenge_completions: own rows"
  on public.challenge_completions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "challenge_completions: staff read"
  on public.challenge_completions for select
  using (public.is_staff());

-- -----------------------------------------------------------------------------
-- Journal ("Mon Journal") — strictly private, not even staff can read it
-- -----------------------------------------------------------------------------
create table public.journal_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  entry_date  date not null default current_date,
  god_shows   text check (char_length(god_shows)   <= 500),
  must_change text check (char_length(must_change) <= 500),
  pray_for    text check (char_length(pray_for)    <= 500),
  gratitude   text check (char_length(gratitude)   <= 500),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, entry_date)
);

alter table public.journal_entries enable row level security;

create policy "journal: owner only"
  on public.journal_entries for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Prayer points ("Ma Prayer Room")
-- -----------------------------------------------------------------------------
create table public.prayer_requests (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  title        text not null check (char_length(title) <= 120),
  details      text check (char_length(details) <= 1000),
  is_shared    boolean not null default false,   -- visible to community for intercession
  is_anonymous boolean not null default false,
  is_answered  boolean not null default false,
  testimony    text,                              -- how God answered
  answered_at  timestamptz,
  created_at   timestamptz not null default now()
);

create table public.prayer_intercessions (
  prayer_id  uuid not null references public.prayer_requests (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (prayer_id, user_id)
);

alter table public.prayer_requests      enable row level security;
alter table public.prayer_intercessions enable row level security;

create policy "prayers: owner full access"
  on public.prayer_requests for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "prayers: staff read + moderate"
  on public.prayer_requests for select using (public.is_staff());
create policy "prayers: staff delete"
  on public.prayer_requests for delete using (public.is_staff());

create policy "intercessions: own rows"
  on public.prayer_intercessions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Community wall: shared prayers, with the author hidden when anonymous.
create or replace view public.community_prayers
with (security_invoker = false) as
select
  p.id,
  p.title,
  p.details,
  p.is_answered,
  p.testimony,
  p.created_at,
  case when p.is_anonymous then null else pr.full_name end as author_name,
  (select count(*) from public.prayer_intercessions i where i.prayer_id = p.id) as intercession_count,
  exists (select 1 from public.prayer_intercessions i
          where i.prayer_id = p.id and i.user_id = auth.uid()) as i_prayed
from public.prayer_requests p
join public.profiles pr on pr.id = p.user_id
where p.is_shared and auth.uid() is not null;

grant select on public.community_prayers to authenticated;

-- -----------------------------------------------------------------------------
-- Holy SOS — ask for help / offer help
-- -----------------------------------------------------------------------------
create table public.help_requests (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  category      public.help_category not null,
  description   text not null check (char_length(description) <= 500),
  is_anonymous  boolean not null default true,
  leaders_only  boolean not null default false,  -- true = only leaders see it, never the community
  status        public.help_status not null default 'open',
  staff_note    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.help_offers (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid not null references public.help_requests (id) on delete cascade,
  helper_id   uuid not null references public.profiles (id) on delete cascade,
  message     text not null check (char_length(message) <= 500),
  created_at  timestamptz not null default now()
);

alter table public.help_requests enable row level security;
alter table public.help_offers   enable row level security;

create policy "help_requests: owner full access"
  on public.help_requests for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "help_requests: staff read"
  on public.help_requests for select using (public.is_staff());
create policy "help_requests: staff update"
  on public.help_requests for update using (public.is_staff());

create policy "help_offers: helper writes own"
  on public.help_offers for insert
  with check (helper_id = auth.uid());
create policy "help_offers: helper, requester and staff read"
  on public.help_offers for select
  using (
    helper_id = auth.uid()
    or public.is_staff()
    or exists (select 1 from public.help_requests r where r.id = request_id and r.user_id = auth.uid())
  );

-- Public board of needs (identity hidden when anonymous; leaders_only never shown).
create or replace view public.community_needs
with (security_invoker = false) as
select
  r.id,
  r.category,
  r.description,
  r.status,
  r.created_at,
  case when r.is_anonymous then null else p.full_name end as author_name,
  (r.user_id = auth.uid()) as is_mine,
  (select count(*) from public.help_offers o where o.request_id = r.id) as offer_count
from public.help_requests r
join public.profiles p on p.id = r.user_id
where not r.leaders_only and r.status <> 'resolved' and auth.uid() is not null;

grant select on public.community_needs to authenticated;

-- -----------------------------------------------------------------------------
-- Private conversations with leaders ("pour out your mind")
-- -----------------------------------------------------------------------------
create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  subject         text not null check (char_length(subject) <= 150),
  status          public.conversation_status not null default 'open',
  assigned_to     uuid references public.profiles (id) on delete set null,
  last_message_at timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references public.profiles (id) on delete cascade,
  body            text not null check (char_length(body) between 1 and 4000),
  is_from_staff   boolean not null default false,
  read_at         timestamptz,
  created_at      timestamptz not null default now()
);

create index messages_conversation_idx on public.messages (conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.messages      enable row level security;

create policy "conversations: owner read/create"
  on public.conversations for select using (user_id = auth.uid());
create policy "conversations: owner insert"
  on public.conversations for insert with check (user_id = auth.uid());
create policy "conversations: staff all"
  on public.conversations for all
  using (public.is_staff()) with check (public.is_staff());

create policy "messages: participants read"
  on public.messages for select
  using (
    public.is_staff()
    or exists (select 1 from public.conversations c where c.id = conversation_id and c.user_id = auth.uid())
  );
create policy "messages: participants send"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and (
      public.is_staff()
      or exists (select 1 from public.conversations c
                 where c.id = conversation_id and c.user_id = auth.uid() and c.status = 'open')
    )
  );
create policy "messages: participants mark read"
  on public.messages for update
  using (
    public.is_staff()
    or exists (select 1 from public.conversations c where c.id = conversation_id and c.user_id = auth.uid())
  );

-- Stamp is_from_staff server-side and bump the conversation.
create or replace function public.on_message_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  new.is_from_staff := exists (
    select 1 from public.conversations c
    where c.id = new.conversation_id and c.user_id <> new.sender_id
  ) and public.is_staff();
  update public.conversations set last_message_at = now() where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_before_insert
  before insert on public.messages
  for each row execute function public.on_message_insert();

-- -----------------------------------------------------------------------------
-- Announcements (admin -> all members, shown in "Notifications")
-- -----------------------------------------------------------------------------
create table public.announcements (
  id           uuid primary key default gen_random_uuid(),
  lang         public.app_language,           -- null = all languages
  title        text not null,
  body         text not null,
  is_published boolean not null default true,
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now()
);

alter table public.announcements enable row level security;

create policy "announcements: members read published"
  on public.announcements for select
  using (is_published or public.is_staff());
create policy "announcements: staff write"
  on public.announcements for all
  using (public.is_staff()) with check (public.is_staff());

-- -----------------------------------------------------------------------------
-- Stats for the home / profile screens
-- -----------------------------------------------------------------------------
create or replace function public.my_stats()
returns json
language plpgsql stable security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  streak int := 0;
  d date := current_date;
  active_days date[];
begin
  select array_agg(distinct day) into active_days from (
    select (c.completed_at at time zone 'utc')::date as day from public.devotion_completions c where c.user_id = uid
    union
    select (c.completed_at at time zone 'utc')::date from public.challenge_completions c where c.user_id = uid
  ) s;

  -- A streak survives if today isn't done yet but yesterday was.
  if active_days is not null and not (d = any (active_days)) then
    d := d - 1;
  end if;
  while active_days is not null and d = any (active_days) loop
    streak := streak + 1;
    d := d - 1;
  end loop;

  return json_build_object(
    'streak',               streak,
    'devotions_completed',  (select count(*) from public.devotion_completions  where user_id = uid),
    'challenges_completed', (select count(*) from public.challenge_completions where user_id = uid),
    'prayers_answered',     (select count(*) from public.prayer_requests where user_id = uid and is_answered),
    'prayers_open',         (select count(*) from public.prayer_requests where user_id = uid and not is_answered),
    'days_since_join',      (select (current_date - created_at::date) + 1 from public.profiles where id = uid),
    'week_challenges',      (select coalesce(json_agg(extract(isodow from cc.completed_at)::int), '[]'::json)
                               from public.challenge_completions cc
                              where cc.user_id = uid
                                and cc.completed_at >= date_trunc('week', now()))
  );
end;
$$;

grant execute on function public.my_stats() to authenticated;

-- Dashboard numbers for the admin website.
create or replace function public.admin_dashboard()
returns json
language plpgsql stable security definer set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'forbidden';
  end if;
  return json_build_object(
    'members',              (select count(*) from public.profiles),
    'open_conversations',   (select count(*) from public.conversations where status = 'open'),
    'open_help_requests',   (select count(*) from public.help_requests where status <> 'resolved'),
    'prayers_this_week',    (select count(*) from public.prayer_requests where created_at >= now() - interval '7 days'),
    'devotions_scheduled',  (select count(*) from public.devotions where devotion_date >= current_date),
    'completions_today',    (select count(*) from public.devotion_completions where completed_at::date = current_date)
  );
end;
$$;

grant execute on function public.admin_dashboard() to authenticated;

-- -----------------------------------------------------------------------------
-- Realtime (live chat + live dashboard)
-- -----------------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.help_requests;

-- -----------------------------------------------------------------------------
-- Storage bucket for devotion images & audio
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

create policy "media: public read"
  on storage.objects for select
  using (bucket_id = 'media');
create policy "media: staff upload"
  on storage.objects for insert
  with check (bucket_id = 'media' and public.is_staff());
create policy "media: staff update"
  on storage.objects for update
  using (bucket_id = 'media' and public.is_staff());
create policy "media: staff delete"
  on storage.objects for delete
  using (bucket_id = 'media' and public.is_staff());
