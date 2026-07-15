-- Libraries were public-by-default, which contradicts the app's assumption
-- that RLS returns only the caller's rows. Sharing becomes opt-in.
alter table public.profiles alter column is_library_public set default false;
update public.profiles set is_library_public = false where is_library_public;
