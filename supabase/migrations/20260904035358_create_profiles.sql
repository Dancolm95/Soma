-- Per-user profile, 1:1 with auth.users.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  base_currency text not null default 'USD'
    constraint profiles_base_currency_check
    check (base_currency in ('PEN', 'USD', 'EUR')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Profile is created automatically from the authenticated identity at signup.
-- The id is taken from auth.users; it is never accepted from the client.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.profiles_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.profiles_touch_updated_at();

-- The client is never an authorization boundary.
alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Least privilege: anonymous has no access; authenticated can only read the
-- profile and update base_currency. Creation is handled by the trigger above.
revoke all on table public.profiles from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (base_currency) on public.profiles to authenticated;
