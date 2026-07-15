-- 修复 security advisor 警告:
-- handle_new_user 是 security definer 的 trigger function,
-- 不应该通过 PostgREST 的 /rpc/ endpoint 被外部调用。
-- 收回 execute 权限不影响 trigger 触发 (trigger 执行不检查调用者的 execute 权限)。
revoke execute on function public.handle_new_user() from anon, authenticated, public;
