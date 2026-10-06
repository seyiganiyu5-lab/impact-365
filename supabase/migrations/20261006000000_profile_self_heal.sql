-- Let a signed-in user create their OWN profile row if it is missing
-- (e.g. accounts created before the first migration). The role is forced
-- to 'member', so nobody can make themselves admin this way.
create policy "profiles: insert own (member only)"
  on public.profiles for insert
  with check (id = auth.uid() and role = 'member');
