-- =============================================================================
-- IMPACT-365 — setup check.
-- Run in Supabase → SQL Editor after the migration. Every line should say ✅.
-- Safe to run as many times as you like.
-- =============================================================================

-- Repair: accounts created before the migration was run have no profile row,
-- which makes the app fail after sign-in. Create the missing profiles.
insert into public.profiles (id, full_name, preferred_language)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'full_name', split_part(u.email, '@', 1)),
  case when u.raw_user_meta_data ->> 'preferred_language' in ('fr', 'en', 'yo')
       then (u.raw_user_meta_data ->> 'preferred_language')::public.app_language
       else 'fr' end
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

with checks(item, ok, hint) as (
  -- Tables
  select 'Table ' || t, to_regclass('public.' || t) is not null,
         'Run supabase/migrations/20261004000000_init.sql'
  from unnest(array[
    'profiles', 'devotions', 'devotion_translations', 'devotion_completions',
    'challenges', 'challenge_translations', 'challenge_completions',
    'journal_entries', 'prayer_requests', 'prayer_intercessions',
    'help_requests', 'help_offers', 'conversations', 'messages', 'announcements'
  ]) as t

  -- Row Level Security switched on everywhere
  union all
  select 'RLS on ' || c.relname, c.relrowsecurity, 'Re-run the migration'
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r'

  -- Views and functions used by the app
  union all
  select 'View ' || v, to_regclass('public.' || v) is not null, 'Re-run the migration'
  from unnest(array['community_prayers', 'community_needs']) as v
  union all
  select 'Function ' || f, exists (
           select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = f),
         'Re-run the migration'
  from unnest(array['is_staff', 'is_admin', 'handle_new_user', 'my_stats', 'admin_dashboard']) as f

  -- New sign-ups get a profile automatically
  union all
  select 'Trigger: profile created on sign-up', exists (
           select 1 from pg_trigger where tgname = 'on_auth_user_created'),
         'Re-run the migration'

  -- Every account has a profile (the repair above fixes old accounts)
  union all
  select 'Every account has a profile',
         not exists (select 1 from auth.users u
                     where not exists (select 1 from public.profiles p where p.id = u.id)),
         'Run this script again'

  -- Storage for devotion images / audio
  union all
  select 'Storage bucket "media" (public)',
         exists (select 1 from storage.buckets where id = 'media' and public),
         'Re-run the migration'

  -- Live chat
  union all
  select 'Realtime on messages', exists (
           select 1 from pg_publication_tables
           where pubname = 'supabase_realtime' and tablename = 'messages'),
         'Database → Publications → supabase_realtime → add "messages"'

  -- Someone can open the admin website
  union all
  select 'At least one admin',
         exists (select 1 from public.profiles where role = 'admin'),
         'update public.profiles set role = ''admin'' where id = (select id from auth.users where email = ''YOU@example.com'');'
)
select case when ok then '✅' else '❌' end as status, item, case when ok then '' else hint end as how_to_fix
from checks
order by ok, item;
