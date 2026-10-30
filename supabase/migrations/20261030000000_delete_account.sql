-- =============================================================================
-- IMPACT-365 — "Supprimer mon compte" (required by Apple and Google)
-- A signed-in member deletes their own account. Everything that belongs to
-- them (profile, journal, prayers, help requests, conversations...) goes
-- with it, through the "on delete cascade" links.
-- =============================================================================

create or replace function public.delete_my_account()
returns void
language plpgsql security definer set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_signed_in';
  end if;

  -- Never leave the church without an administrator.
  if exists (select 1 from public.profiles where id = uid and role = 'admin')
     and (select count(*) from public.profiles where role = 'admin') <= 1 then
    raise exception using errcode = 'P0001', message = 'last_admin';
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
