-- =============================================================================
-- IMPACT-365 — profile photos
-- Members upload their photo to the "avatars" bucket, in a folder named after
-- their user id: avatars/<user id>/<file>. Anyone can view a photo (it is
-- shown in the app), but only its owner can add, replace or remove it.
-- =============================================================================

-- Public bucket: photos are served from their public URL.
-- 2 MB max (the app sends a resized ~600 px JPEG, usually under 150 KB),
-- images only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars', 'avatars', true, 2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- How many photos a member has stored (security definer: counts through RLS).
create or replace function public.avatar_file_count(uid uuid)
returns integer
language sql stable security definer set search_path = public, storage
as $$
  select count(*)::int
  from storage.objects
  where bucket_id = 'avatars'
    and (storage.foldername(name))[1] = uid::text;
$$;

revoke execute on function public.avatar_file_count(uuid) from public, anon;
grant execute on function public.avatar_file_count(uuid) to authenticated;

-- Owner sees their own files (needed to list and remove them).
create policy "avatars: owner reads own folder"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Owner uploads into their own folder only, and keeps at most 3 files there
-- (the app removes the previous photo after each upload).
create policy "avatars: owner uploads to own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.avatar_file_count(auth.uid()) < 3
  );

create policy "avatars: owner updates own files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars: owner deletes own files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- profiles.avatar_url: a member may only point it at a photo in their own
-- avatars folder, or clear it. (Stops anyone using an outside link, such as
-- a tracking image, as their photo.) Admins and the sign-up trigger, which
-- copies the Google photo, are not limited.
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

  if new.avatar_url is distinct from old.avatar_url
     and new.avatar_url is not null
     and auth.uid() is not null
     and not public.is_admin()
     and new.avatar_url !~ (
       '^https://[a-z0-9-]+\.supabase\.co/storage/v1/object/public/avatars/'
       || auth.uid()::text || '/[A-Za-z0-9._-]+$'
     ) then
    raise exception using errcode = 'P0001', message = 'avatar_url_not_allowed';
  end if;

  new.updated_at := now();
  return new;
end;
$$;
