-- set_updated_at() was a byte-identical duplicate of handle_updated_at();
-- every set_updated_at trigger executes handle_updated_at(), so the twin
-- function is dead code.
drop function if exists public.set_updated_at();
