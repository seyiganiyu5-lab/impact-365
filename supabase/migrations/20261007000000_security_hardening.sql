-- =============================================================================
-- IMPACT-365 — security hardening
-- 1. Closes write paths that RLS alone left open.
-- 2. Server-side rate limits on everything members can post (staff exempt).
-- 3. Size limits on every free-text column.
-- Safe to run once on top of 20261004000000_init.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Write paths
-- -----------------------------------------------------------------------------

-- Messages: the only thing anyone may change after sending is read_at.
-- (Before: a member could edit any message in their conversation, including
-- the pastor's replies, or set is_from_staff on their own messages.)
revoke update on public.messages from anon, authenticated;
grant update (read_at) on public.messages to authenticated;

-- No anonymous (signed-out) writes anywhere: RLS already refuses them, this
-- removes the table privileges too.
revoke insert, update, delete on all tables in schema public from anon;

-- Help requests: only staff write the staff note.
create or replace function public.protect_help_request()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_staff() and auth.uid() is not null then
    if tg_op = 'INSERT' then
      new.staff_note := null;
      new.status := 'open';
    elsif new.staff_note is distinct from old.staff_note then
      raise exception 'Only leaders can write the staff note';
    end if;
  end if;
  return new;
end;
$$;

create trigger help_requests_protect
  before insert or update on public.help_requests
  for each row execute function public.protect_help_request();

-- Conversations: a member opens a conversation as "open" and unassigned;
-- assignment and status are for staff.
create or replace function public.protect_conversation()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_staff() and auth.uid() is not null then
    new.status := 'open';
    new.assigned_to := null;
    new.last_message_at := now();
    new.created_at := now();
  end if;
  return new;
end;
$$;

create trigger conversations_protect
  before insert on public.conversations
  for each row execute function public.protect_conversation();

-- Help offers: only on needs that are on the public board (not leaders-only,
-- not resolved, not your own).
create or replace function public.can_offer_help(p_request_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.help_requests r
    where r.id = p_request_id
      and not r.leaders_only
      and r.status <> 'resolved'
      and r.user_id <> auth.uid()
  );
$$;

drop policy if exists "help_offers: helper writes own" on public.help_offers;
create policy "help_offers: helper writes own"
  on public.help_offers for insert
  with check (helper_id = auth.uid() and public.can_offer_help(request_id));

-- Intercessions: only on prayers shared with the community (or your own).
create or replace function public.can_intercede(p_prayer_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.prayer_requests p
    where p.id = p_prayer_id and (p.is_shared or p.user_id = auth.uid())
  );
$$;

drop policy if exists "intercessions: own rows" on public.prayer_intercessions;
create policy "intercessions: own rows"
  on public.prayer_intercessions for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.can_intercede(prayer_id));

-- Profiles: cap the name taken from sign-up data.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, preferred_language)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(new.email, '@', 1)), 80),
    case when new.raw_user_meta_data ->> 'preferred_language' in ('fr', 'en', 'yo')
         then (new.raw_user_meta_data ->> 'preferred_language')::public.app_language
         else 'fr' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Rate limits
-- Trigger arguments: user column, max rows, time window.
-- Over the limit → HTTP 429 with code "PT429"; the app shows
-- "Trop de tentatives, patiente un moment".
-- -----------------------------------------------------------------------------
create or replace function public.enforce_rate_limit()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  user_col text     := tg_argv[0];
  max_rows int      := tg_argv[1]::int;
  win      interval := tg_argv[2]::interval;
  uid      uuid     := auth.uid();
  n        int;
begin
  -- SQL editor / server jobs (no user) and staff are not limited.
  if uid is null or public.is_staff() then
    return new;
  end if;
  execute format(
    'select count(*) from %I.%I where %I = $1 and created_at > now() - $2',
    tg_table_schema, tg_table_name, user_col
  ) into n using uid, win;
  if n >= max_rows then
    raise exception using
      errcode = 'PT429',
      message = 'rate_limit',
      detail  = format('%s: at most %s per %s', tg_table_name, max_rows, win);
  end if;
  return new;
end;
$$;

revoke execute on function public.enforce_rate_limit() from public, anon, authenticated;

-- Prayer points: 10 per hour, 30 per day.
create trigger rl_prayer_requests_hour before insert on public.prayer_requests
  for each row execute function public.enforce_rate_limit('user_id', '10', '1 hour');
create trigger rl_prayer_requests_day before insert on public.prayer_requests
  for each row execute function public.enforce_rate_limit('user_id', '30', '1 day');

-- "I prayed": 100 per hour.
create trigger rl_intercessions_hour before insert on public.prayer_intercessions
  for each row execute function public.enforce_rate_limit('user_id', '100', '1 hour');

-- Holy SOS requests: 3 per hour, 10 per day.
create trigger rl_help_requests_hour before insert on public.help_requests
  for each row execute function public.enforce_rate_limit('user_id', '3', '1 hour');
create trigger rl_help_requests_day before insert on public.help_requests
  for each row execute function public.enforce_rate_limit('user_id', '10', '1 day');

-- Offers to help: 10 per hour.
create trigger rl_help_offers_hour before insert on public.help_offers
  for each row execute function public.enforce_rate_limit('helper_id', '10', '1 hour');

-- New conversations with leaders: 3 per hour, 10 per day.
create trigger rl_conversations_hour before insert on public.conversations
  for each row execute function public.enforce_rate_limit('user_id', '3', '1 hour');
create trigger rl_conversations_day before insert on public.conversations
  for each row execute function public.enforce_rate_limit('user_id', '10', '1 day');

-- Chat messages: 15 per minute, 300 per day.
create trigger rl_messages_minute before insert on public.messages
  for each row execute function public.enforce_rate_limit('sender_id', '15', '1 minute');
create trigger rl_messages_day before insert on public.messages
  for each row execute function public.enforce_rate_limit('sender_id', '300', '1 day');

-- Indexes so the counts stay instant.
create index if not exists prayer_requests_user_created_idx on public.prayer_requests (user_id, created_at);
create index if not exists intercessions_user_created_idx   on public.prayer_intercessions (user_id, created_at);
create index if not exists help_requests_user_created_idx   on public.help_requests (user_id, created_at);
create index if not exists help_offers_helper_created_idx   on public.help_offers (helper_id, created_at);
create index if not exists conversations_user_created_idx   on public.conversations (user_id, created_at);
create index if not exists messages_sender_created_idx      on public.messages (sender_id, created_at);

-- -----------------------------------------------------------------------------
-- 3. Size limits on the remaining free-text columns
-- ("not valid" = existing rows are not re-checked, new writes are.)
-- -----------------------------------------------------------------------------
alter table public.profiles
  add constraint profiles_full_name_len  check (char_length(full_name)  <= 80)  not valid,
  add constraint profiles_phone_len      check (char_length(phone)      <= 30)  not valid,
  add constraint profiles_avatar_url_len check (char_length(avatar_url) <= 500) not valid;

alter table public.prayer_requests
  add constraint prayer_requests_testimony_len check (char_length(testimony) <= 1000) not valid;

alter table public.help_requests
  add constraint help_requests_staff_note_len check (char_length(staff_note) <= 1000) not valid;

alter table public.announcements
  add constraint announcements_title_len check (char_length(title) <= 150)  not valid,
  add constraint announcements_body_len  check (char_length(body)  <= 4000) not valid;
