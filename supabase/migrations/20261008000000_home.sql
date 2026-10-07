-- =============================================================================
-- IMPACT-365 — home screen
-- 1. my_stats() also returns this week's activity (Mon → Sun) for the
--    "Parcours de foi" chart.
-- 2. Saved devotions (the bookmark on the home card).
-- =============================================================================

create or replace function public.my_stats()
returns json
language plpgsql stable security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  streak int := 0;
  d date := current_date;
  active_days date[];
  week_start date := date_trunc('week', current_date)::date;
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
                                and cc.completed_at >= date_trunc('week', now())),
    -- Devotions + challenges completed on each day of this week, Monday first.
    'week_activity',        (select json_agg(coalesce(n, 0) order by g.i)
                               from generate_series(0, 6) as g(i)
                               left join (
                                 select (a.day - week_start) as i, count(*) as n
                                 from (
                                   select (c.completed_at at time zone 'utc')::date as day
                                     from public.devotion_completions c where c.user_id = uid
                                   union all
                                   select (c.completed_at at time zone 'utc')::date
                                     from public.challenge_completions c where c.user_id = uid
                                 ) a
                                 where a.day >= week_start and a.day < week_start + 7
                                 group by 1
                               ) w on w.i = g.i)
  );
end;
$$;

grant execute on function public.my_stats() to authenticated;

-- Saved devotions: private to each member.
create table if not exists public.devotion_bookmarks (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  devotion_id uuid not null references public.devotions (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, devotion_id)
);

alter table public.devotion_bookmarks enable row level security;

drop policy if exists "devotion_bookmarks: own rows" on public.devotion_bookmarks;
create policy "devotion_bookmarks: own rows"
  on public.devotion_bookmarks for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke insert, update, delete on public.devotion_bookmarks from anon;
