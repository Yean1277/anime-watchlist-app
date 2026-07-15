-- Client-side clamping is not a constraint: enforce non-negative progress
-- in the database, and forbid self-follows.
alter table public.user_anime
  add constraint user_anime_episodes_watched_nonneg check (episodes_watched >= 0);
alter table public.follows
  add constraint follows_no_self check (follower_id <> following_id);
