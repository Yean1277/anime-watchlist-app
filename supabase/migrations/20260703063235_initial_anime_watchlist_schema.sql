-- ============================================================
-- Anime Watchlist App — Supabase 完整 Schema
-- Metadata 来源: Jikan (MyAnimeList) API
--
-- 架构分层:
--   [cache 层]  anime / anime_episodes / genres  ← Jikan 同步, client 只读
--   [用户层]    profiles / user_anime / watched_episodes
--   [功能层]    reviews / custom_lists / follows / notifications (先建表, 后接功能)
-- ============================================================

-- ---------- 0. Extensions ----------
create extension if not exists pg_trgm with schema extensions;

-- ---------- 1. Enum ----------
create type public.watch_status as enum (
  'plan_to_watch',
  'watching',
  'completed',
  'on_hold',
  'dropped'
);

-- ============================================================
-- 2. profiles — 用户资料 (1:1 对应 auth.users)
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique check (username ~ '^[a-zA-Z0-9_]{3,20}$'),
  display_name text,
  avatar_url text,
  is_library_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3. anime — Jikan metadata 的本地 cache
-- ============================================================
create table public.anime (
  mal_id bigint primary key,
  title text not null,
  title_english text,
  title_japanese text,
  synopsis text,
  type text,
  source text,
  status text,
  episodes int,
  aired_from date,
  aired_to date,
  season text,
  year int,
  score numeric(4,2),
  rank int,
  popularity int,
  image_url text,
  trailer_url text,
  synced_at timestamptz not null default now()
);

create index anime_title_trgm_idx on public.anime
  using gin (title extensions.gin_trgm_ops);
create index anime_season_year_idx on public.anime (year, season);

-- ---------- 3.1 genres ----------
create table public.genres (
  mal_id bigint primary key,
  name text not null,
  category text not null default 'genre'
);

create table public.anime_genres (
  anime_id bigint not null references public.anime (mal_id) on delete cascade,
  genre_id bigint not null references public.genres (mal_id) on delete cascade,
  primary key (anime_id, genre_id)
);
create index anime_genres_genre_idx on public.anime_genres (genre_id);

-- ---------- 3.2 anime_episodes — 分集 cache ----------
create table public.anime_episodes (
  anime_id bigint not null references public.anime (mal_id) on delete cascade,
  episode_number int not null,
  title text,
  aired date,
  filler boolean not null default false,
  recap boolean not null default false,
  synced_at timestamptz not null default now(),
  primary key (anime_id, episode_number)
);

-- ============================================================
-- 4. user_anime — 用户的 watchlist 主表
-- ============================================================
create table public.user_anime (
  user_id uuid not null references public.profiles (id) on delete cascade,
  anime_id bigint not null references public.anime (mal_id) on delete restrict,
  status public.watch_status not null default 'plan_to_watch',
  score smallint check (score between 1 and 10),
  episodes_watched int not null default 0,
  is_favorite boolean not null default false,
  notify_new_episodes boolean not null default false,
  notes text,
  started_at date,
  finished_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, anime_id)
);

create index user_anime_status_idx on public.user_anime (user_id, status);
create index user_anime_anime_idx on public.user_anime (anime_id);

-- ============================================================
-- 5. watched_episodes — 每一集的打卡记录 (source of truth)
--    FK 指向 user_anime 而非 anime_episodes: cache 滞后不阻塞打卡
-- ============================================================
create table public.watched_episodes (
  user_id uuid not null,
  anime_id bigint not null,
  episode_number int not null check (episode_number >= 0),
  watched_at timestamptz not null default now(),
  primary key (user_id, anime_id, episode_number),
  foreign key (user_id, anime_id)
    references public.user_anime (user_id, anime_id) on delete cascade
);

create index watched_episodes_recent_idx on public.watched_episodes (user_id, watched_at desc);

-- ============================================================
-- 6. 功能层
-- ============================================================
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  anime_id bigint not null references public.anime (mal_id) on delete restrict,
  body text not null check (char_length(body) between 1 and 10000),
  has_spoilers boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, anime_id)
);
create index reviews_anime_idx on public.reviews (anime_id, created_at desc);

create table public.custom_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  description text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index custom_lists_user_idx on public.custom_lists (user_id);

create table public.custom_list_items (
  list_id uuid not null references public.custom_lists (id) on delete cascade,
  anime_id bigint not null references public.anime (mal_id) on delete restrict,
  position int not null default 0,
  added_at timestamptz not null default now(),
  primary key (list_id, anime_id)
);

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);
create index follows_following_idx on public.follows (following_id);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_inbox_idx on public.notifications (user_id, created_at desc);

-- ============================================================
-- 7. Functions & Triggers
-- ============================================================
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at before update on public.profiles
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.user_anime
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.reviews
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.custom_lists
  for each row execute function public.handle_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.sync_episodes_watched()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.user_anime
       set episodes_watched = episodes_watched + 1
     where user_id = new.user_id and anime_id = new.anime_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.user_anime
       set episodes_watched = greatest(episodes_watched - 1, 0)
     where user_id = old.user_id and anime_id = old.anime_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger on_watched_episodes_change
  after insert or delete on public.watched_episodes
  for each row execute function public.sync_episodes_watched();

-- ============================================================
-- 8. Row Level Security
-- ============================================================
alter table public.profiles          enable row level security;
alter table public.anime             enable row level security;
alter table public.genres            enable row level security;
alter table public.anime_genres      enable row level security;
alter table public.anime_episodes    enable row level security;
alter table public.user_anime        enable row level security;
alter table public.watched_episodes  enable row level security;
alter table public.reviews           enable row level security;
alter table public.custom_lists      enable row level security;
alter table public.custom_list_items enable row level security;
alter table public.follows           enable row level security;
alter table public.notifications     enable row level security;

create policy "profiles_select_all" on public.profiles
  for select using (true);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "anime_select_all" on public.anime
  for select using (true);
create policy "genres_select_all" on public.genres
  for select using (true);
create policy "anime_genres_select_all" on public.anime_genres
  for select using (true);
create policy "anime_episodes_select_all" on public.anime_episodes
  for select using (true);

create policy "user_anime_select" on public.user_anime
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.profiles p
      where p.id = user_id and p.is_library_public
    )
  );
create policy "user_anime_insert_own" on public.user_anime
  for insert with check (auth.uid() = user_id);
create policy "user_anime_update_own" on public.user_anime
  for update using (auth.uid() = user_id);
create policy "user_anime_delete_own" on public.user_anime
  for delete using (auth.uid() = user_id);

create policy "watched_select" on public.watched_episodes
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.profiles p
      where p.id = user_id and p.is_library_public
    )
  );
create policy "watched_insert_own" on public.watched_episodes
  for insert with check (auth.uid() = user_id);
create policy "watched_delete_own" on public.watched_episodes
  for delete using (auth.uid() = user_id);

create policy "reviews_select_all" on public.reviews
  for select using (true);
create policy "reviews_insert_own" on public.reviews
  for insert with check (auth.uid() = user_id);
create policy "reviews_update_own" on public.reviews
  for update using (auth.uid() = user_id);
create policy "reviews_delete_own" on public.reviews
  for delete using (auth.uid() = user_id);

create policy "lists_select" on public.custom_lists
  for select using (auth.uid() = user_id or is_public);
create policy "lists_insert_own" on public.custom_lists
  for insert with check (auth.uid() = user_id);
create policy "lists_update_own" on public.custom_lists
  for update using (auth.uid() = user_id);
create policy "lists_delete_own" on public.custom_lists
  for delete using (auth.uid() = user_id);

create policy "list_items_select" on public.custom_list_items
  for select using (
    exists (
      select 1 from public.custom_lists l
      where l.id = list_id
        and (l.user_id = auth.uid() or l.is_public)
    )
  );
create policy "list_items_write" on public.custom_list_items
  for all using (
    exists (
      select 1 from public.custom_lists l
      where l.id = list_id and l.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.custom_lists l
      where l.id = list_id and l.user_id = auth.uid()
    )
  );

create policy "follows_select_all" on public.follows
  for select using (true);
create policy "follows_insert_own" on public.follows
  for insert with check (auth.uid() = follower_id);
create policy "follows_delete_own" on public.follows
  for delete using (auth.uid() = follower_id);

create policy "notifications_select_own" on public.notifications
  for select using (auth.uid() = user_id);
create policy "notifications_update_own" on public.notifications
  for update using (auth.uid() = user_id);
create policy "notifications_delete_own" on public.notifications
  for delete using (auth.uid() = user_id);
