-- The app writes user_anime.episodes_watched directly and never touches
-- watched_episodes, so this trigger was a second writer for the same counter
-- (guaranteed drift). The direct write is now the single source of truth;
-- reintroduce per-episode syncing when that feature actually ships.
drop trigger if exists on_watched_episodes_change on public.watched_episodes;
drop function if exists public.sync_episodes_watched();
