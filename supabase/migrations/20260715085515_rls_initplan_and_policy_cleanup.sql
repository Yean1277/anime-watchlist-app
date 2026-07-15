-- Advisor 0003 (auth_rls_initplan): bare auth.uid() is re-evaluated per row.
-- Recreate every flagged policy with (select auth.uid()) so it runs once as
-- an InitPlan. Semantics are unchanged.

-- profiles
drop policy "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check ((select auth.uid()) = id);
drop policy "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using ((select auth.uid()) = id);

-- user_anime
drop policy "user_anime_select" on public.user_anime;
create policy "user_anime_select" on public.user_anime for select using (
  (select auth.uid()) = user_id
  or exists (select 1 from public.profiles p
             where p.id = user_anime.user_id and p.is_library_public)
);
drop policy "user_anime_insert_own" on public.user_anime;
create policy "user_anime_insert_own" on public.user_anime
  for insert with check ((select auth.uid()) = user_id);
drop policy "user_anime_update_own" on public.user_anime;
create policy "user_anime_update_own" on public.user_anime
  for update using ((select auth.uid()) = user_id);
drop policy "user_anime_delete_own" on public.user_anime;
create policy "user_anime_delete_own" on public.user_anime
  for delete using ((select auth.uid()) = user_id);

-- watched_episodes
drop policy "watched_select" on public.watched_episodes;
create policy "watched_select" on public.watched_episodes for select using (
  (select auth.uid()) = user_id
  or exists (select 1 from public.profiles p
             where p.id = watched_episodes.user_id and p.is_library_public)
);
drop policy "watched_insert_own" on public.watched_episodes;
create policy "watched_insert_own" on public.watched_episodes
  for insert with check ((select auth.uid()) = user_id);
drop policy "watched_delete_own" on public.watched_episodes;
create policy "watched_delete_own" on public.watched_episodes
  for delete using ((select auth.uid()) = user_id);

-- reviews
drop policy "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own" on public.reviews
  for insert with check ((select auth.uid()) = user_id);
drop policy "reviews_update_own" on public.reviews;
create policy "reviews_update_own" on public.reviews
  for update using ((select auth.uid()) = user_id);
drop policy "reviews_delete_own" on public.reviews;
create policy "reviews_delete_own" on public.reviews
  for delete using ((select auth.uid()) = user_id);

-- custom_lists
drop policy "lists_select" on public.custom_lists;
create policy "lists_select" on public.custom_lists
  for select using ((select auth.uid()) = user_id or is_public);
drop policy "lists_insert_own" on public.custom_lists;
create policy "lists_insert_own" on public.custom_lists
  for insert with check ((select auth.uid()) = user_id);
drop policy "lists_update_own" on public.custom_lists;
create policy "lists_update_own" on public.custom_lists
  for update using ((select auth.uid()) = user_id);
drop policy "lists_delete_own" on public.custom_lists;
create policy "lists_delete_own" on public.custom_lists
  for delete using ((select auth.uid()) = user_id);

-- custom_list_items: replace the FOR ALL policy (advisor 0006: it stacked a
-- second permissive SELECT policy on top of list_items_select) with explicit
-- insert/update/delete policies.
drop policy "list_items_select" on public.custom_list_items;
create policy "list_items_select" on public.custom_list_items for select using (
  exists (select 1 from public.custom_lists l
          where l.id = custom_list_items.list_id
            and (l.user_id = (select auth.uid()) or l.is_public))
);
drop policy "list_items_write" on public.custom_list_items;
create policy "list_items_insert_own" on public.custom_list_items for insert with check (
  exists (select 1 from public.custom_lists l
          where l.id = custom_list_items.list_id and l.user_id = (select auth.uid()))
);
create policy "list_items_update_own" on public.custom_list_items for update using (
  exists (select 1 from public.custom_lists l
          where l.id = custom_list_items.list_id and l.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.custom_lists l
          where l.id = custom_list_items.list_id and l.user_id = (select auth.uid()))
);
create policy "list_items_delete_own" on public.custom_list_items for delete using (
  exists (select 1 from public.custom_lists l
          where l.id = custom_list_items.list_id and l.user_id = (select auth.uid()))
);

-- follows
drop policy "follows_insert_own" on public.follows;
create policy "follows_insert_own" on public.follows
  for insert with check ((select auth.uid()) = follower_id);
drop policy "follows_delete_own" on public.follows;
create policy "follows_delete_own" on public.follows
  for delete using ((select auth.uid()) = follower_id);

-- notifications
drop policy "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select using ((select auth.uid()) = user_id);
drop policy "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update using ((select auth.uid()) = user_id);
drop policy "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own" on public.notifications
  for delete using ((select auth.uid()) = user_id);

-- Advisor 0001: unindexed FK custom_list_items.anime_id.
create index custom_list_items_anime_idx on public.custom_list_items (anime_id);
