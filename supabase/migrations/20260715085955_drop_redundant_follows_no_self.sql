-- follows already had an inline check (follower_id <> following_id) named
-- follows_check from the initial schema; follows_no_self duplicated it.
alter table public.follows drop constraint follows_no_self;
