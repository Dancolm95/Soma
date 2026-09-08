-- Tarea 3.1 (ADR-005 PEN-only): retire profiles.base_currency.
-- Reduces privileges: with no client-updatable columns left, the column-level
-- UPDATE grant and the update policy are removed. SELECT-only for
-- authenticated; anon keeps no access. Trigger, FK, RLS untouched.
revoke update on public.profiles from authenticated;

alter table public.profiles drop column base_currency;

drop policy if exists "profiles_update_own" on public.profiles;
