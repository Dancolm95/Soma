BEGIN;
SELECT plan(13);

-- Two identities, owned by auth.users. Profiles are created by the trigger.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000a');
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000b');

SELECT ok(relrowsecurity, 'RLS is enabled on profiles')
  FROM pg_class
  WHERE oid = 'public.profiles'::regclass;

SELECT is(
  (SELECT count(*)::int FROM public.profiles
    WHERE id IN ('00000000-0000-0000-0000-00000000000a',
                 '00000000-0000-0000-0000-00000000000b')),
  2,
  'trigger created one profile per user'
);

SELECT is(
  (SELECT count(*)::int FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles'
      AND column_name = 'base_currency'),
  0,
  'base_currency column is absent (PEN-only)'
);

SELECT is(
  (SELECT count(*)::int FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles'
      AND policyname = 'profiles_update_own'),
  0,
  'profiles_update_own policy is removed'
);

SELECT is(
  has_table_privilege('authenticated', 'public.profiles', 'UPDATE'),
  false,
  'authenticated has no UPDATE privilege on profiles'
);

-- User A
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000a'),
  1,
  'A can read own profile'
);
SELECT is(
  (SELECT count(*)::int FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000b'),
  0,
  'A cannot read B profile'
);

-- User B
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000b'),
  1,
  'B can read own profile'
);
SELECT is(
  (SELECT count(*)::int FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000a'),
  0,
  'B cannot read A profile'
);

-- No client-updatable columns remain: any UPDATE is denied.
SELECT throws_ok(
  $$ UPDATE public.profiles SET updated_at = now()
     WHERE id = '00000000-0000-0000-0000-00000000000b' $$,
  '42501',
  NULL,
  'B cannot update own profile (SELECT-only)'
);

-- Anonymous access
RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT count(*) FROM public.profiles $$,
  '42501',
  NULL,
  'anonymous cannot read profiles'
);

-- A cannot create a profile for another user
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT throws_ok(
  $$ INSERT INTO public.profiles (id) VALUES ('00000000-0000-0000-0000-00000000000b') $$,
  '42501',
  NULL,
  'A cannot create a profile for B'
);

-- A cannot change own profile id
SELECT throws_ok(
  $$ UPDATE public.profiles SET id = '00000000-0000-0000-0000-00000000000b'
     WHERE id = '00000000-0000-0000-0000-00000000000a' $$,
  '42501',
  NULL,
  'A cannot change own profile id'
);

SELECT * FROM finish();
ROLLBACK;
