-- Tarea 3.3 (corrección definitiva, alternativa B): expenses (PEN-only).
-- Ownership validated procedurally with SECURITY INVOKER triggers.
-- Category UUIDs stay opaque: no owner_key, no scope columns, no reserved
-- id blocks, no inter-table CHECK function, no SECURITY DEFINER.

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  amount numeric(12,2) not null
    constraint expenses_amount_check
    check (amount > 0),
  expense_date date not null,
  merchant text not null
    constraint expenses_merchant_check
    check (char_length(btrim(merchant)) between 1 and 120),
  category_id uuid not null references public.categories (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Expense -> category: only a global or same-owner private category is
-- accepted. A plain SELECT is used because SELECT ... FOR SHARE returns no
-- rows for authenticated here (row locking needs UPDATE privilege, which
-- the client must not have). Concurrency is serialized instead with a
-- per-category advisory xact lock shared with the guard below: any role
-- may take it, no table grants needed, released at transaction end.
create function public.expenses_check_category_owner()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  perform pg_advisory_xact_lock(810311, hashtext(new.category_id::text));
  perform 1
    from public.categories c
   where c.id = new.category_id
     and (c.user_id is null or c.user_id = new.user_id);
  if not found then
    raise exception 'category % is not available to this user', new.category_id
      using errcode = '23503';
  end if;
  return new;
end;
$$;

create trigger expenses_check_category_owner
  before insert or update of category_id, user_id on public.expenses
  for each row execute function public.expenses_check_category_owner();

-- Category -> expenses: an ownership change is rejected while any existing
-- expense would become invalid. Admin/product flows get fail-closed
-- protection for present and future migrations.
create function public.categories_guard_expense_owner()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  perform pg_advisory_xact_lock(810311, hashtext(old.id::text));
  if exists (
    select 1
      from public.expenses e
     where e.category_id = old.id
       and not (new.user_id is null or new.user_id = e.user_id)
  ) then
    raise exception 'cannot transfer category % with existing expenses', old.id
      using errcode = '23503';
  end if;
  return new;
end;
$$;

create trigger categories_guard_expense_owner
  before update of user_id on public.categories
  for each row execute function public.categories_guard_expense_owner();

create function public.expenses_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger expenses_set_updated_at
  before update on public.expenses
  for each row execute function public.expenses_touch_updated_at();

-- The client is never an authorization boundary.
alter table public.expenses enable row level security;

create policy "expenses_select_own"
  on public.expenses
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "expenses_insert_own"
  on public.expenses
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "expenses_update_own"
  on public.expenses
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "expenses_delete_own"
  on public.expenses
  for delete
  to authenticated
  using (user_id = auth.uid());

-- Least privilege: anonymous has no access; authenticated reads/deletes own
-- rows and writes only editable columns. Ownership is session-derived
-- (user_id defaults to auth.uid(), no write grant) and category ownership
-- is enforced by the triggers above, which run with the caller's rights.
revoke all on table public.expenses from anon, authenticated;

grant select, delete on public.expenses to authenticated;
grant insert (amount, expense_date, merchant, category_id) on public.expenses to authenticated;
grant update (amount, expense_date, merchant, category_id) on public.expenses to authenticated;

-- Trigger helpers are not an API: no direct execution for anon, and only
-- the roles that legitimately write (authenticated via triggers,
-- service_role for backend/admin paths) keep EXECUTE. Superuser bypasses
-- these checks; verified below by the adversarial suite.
revoke all on function public.expenses_check_category_owner() from public;
revoke all on function public.categories_guard_expense_owner() from public;
revoke all on function public.expenses_touch_updated_at() from public;

-- Supabase default privileges pre-grant EXECUTE on new functions to named
-- roles, so anon must be revoked explicitly (PUBLIC revoke is not enough).
revoke all on function public.expenses_check_category_owner() from anon;
revoke all on function public.categories_guard_expense_owner() from anon;
revoke all on function public.expenses_touch_updated_at() from anon;

-- Validator and guard fire as triggers, which needs no EXECUTE grant for
-- the writing role, so nobody keeps direct execution on them.
revoke all on function public.expenses_check_category_owner()
  from anon, authenticated, service_role;
revoke all on function public.categories_guard_expense_owner()
  from anon, authenticated, service_role;
grant execute on function public.expenses_touch_updated_at() to authenticated, service_role;
