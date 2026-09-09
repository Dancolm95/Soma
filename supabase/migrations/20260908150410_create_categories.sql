-- Tarea 3.2: expense categories with ownership (system vs per-user).
-- user_id IS NULL marks a system category; otherwise it references its owner.
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid default auth.uid() references auth.users (id) on delete cascade,
  name text not null
    constraint categories_name_check
    check (char_length(btrim(name)) between 1 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Logical duplicates within the same scope are rejected case-insensitively,
-- ignoring surrounding whitespace. Scopes stay independent: the same name may
-- exist for the system and for different users.
create unique index categories_system_name_uniq
  on public.categories (lower(btrim(name)))
  where user_id is null;

create unique index categories_user_name_uniq
  on public.categories (user_id, lower(btrim(name)))
  where user_id is not null;

-- System-controlled seed. Future changes go through explicit migrations.
insert into public.categories (id, user_id, name)
values
  ('00000000-0000-0000-0000-000000000101', null, 'Alimentación'),
  ('00000000-0000-0000-0000-000000000102', null, 'Transporte'),
  ('00000000-0000-0000-0000-000000000103', null, 'Vivienda'),
  ('00000000-0000-0000-0000-000000000104', null, 'Salud'),
  ('00000000-0000-0000-0000-000000000105', null, 'Entretenimiento'),
  ('00000000-0000-0000-0000-000000000106', null, 'Compras'),
  ('00000000-0000-0000-0000-000000000107', null, 'Servicios'),
  ('00000000-0000-0000-0000-000000000108', null, 'Otros');

create function public.categories_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.categories_touch_updated_at();

-- The client is never an authorization boundary.
alter table public.categories enable row level security;

create policy "categories_select_visible"
  on public.categories
  for select
  to authenticated
  using (user_id is null or user_id = auth.uid());

create policy "categories_insert_own"
  on public.categories
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "categories_update_own"
  on public.categories
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "categories_delete_own"
  on public.categories
  for delete
  to authenticated
  using (user_id = auth.uid());

-- Least privilege: anonymous has no access; authenticated reads visible rows,
-- manages only its own, and may update solely the name. Ownership and
-- timestamps are never client-controlled.
revoke all on table public.categories from anon, authenticated;

grant select, insert, delete on public.categories to authenticated;
grant update (name) on public.categories to authenticated;
