-- Watchlist: one row per (user, anime). RLS-scoped to the signed-in user.
create table public.watchlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  mal_id integer not null,
  title text not null,
  title_japanese text,
  image_url text,
  episodes integer,
  episodes_watched integer not null default 0 check (episodes_watched >= 0),
  score integer check (score between 1 and 5),
  status text not null default 'plan_to_watch'
    check (status in ('plan_to_watch','watching','completed','dropped')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, mal_id)
);

-- Indexes for the status filter tabs and the newest-first list order.
create index watchlist_user_status_idx on public.watchlist (user_id, status);
create index watchlist_user_created_idx on public.watchlist (user_id, created_at desc);

-- Keep updated_at fresh on every update.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger watchlist_set_updated_at
  before update on public.watchlist
  for each row execute function public.set_updated_at();

-- Row Level Security: users can only see and modify their own rows.
alter table public.watchlist enable row level security;

create policy "own rows - select" on public.watchlist
  for select using (auth.uid() = user_id);
create policy "own rows - insert" on public.watchlist
  for insert with check (auth.uid() = user_id);
create policy "own rows - update" on public.watchlist
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows - delete" on public.watchlist
  for delete using (auth.uid() = user_id);
