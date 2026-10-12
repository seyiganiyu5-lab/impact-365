-- =============================================================================
-- IMPACT-365 — sign in with Google / Apple
-- New profiles also take the name Google or Apple sends ("name"), not only
-- the one typed in the app's sign-up form ("full_name").
-- =============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url, preferred_language)
  values (
    new.id,
    left(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      split_part(new.email, '@', 1)
    ), 80),
    -- Google profile photo, when there is one.
    left(nullif(new.raw_user_meta_data ->> 'avatar_url', ''), 500),
    case when new.raw_user_meta_data ->> 'preferred_language' in ('fr', 'en', 'yo')
         then (new.raw_user_meta_data ->> 'preferred_language')::public.app_language
         else 'fr' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
