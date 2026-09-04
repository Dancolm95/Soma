BEGIN;
SELECT plan(14);

-- Two identities, owned by auth.users. Profiles are created by the trigger.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000a');
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000b');
UPDATE public.profiles SET base_currency = 'PEN'
  WHERE id = '00000000-0000-0000-0000-00000000000a';

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

-- A updates own profile
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
UPDATE public.profiles SET base_currency = 'EUR'
  WHERE id = '00000000-0000-0000-0000-00000000000a';
RESET ROLE;
SELECT is(
  (SELECT base_currency FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000a'),
  'EUR',
  'A can update own profile'
);

-- A attempts to update B
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
UPDATE public.profiles SET base_currency = 'EUR'
  WHERE id = '00000000-0000-0000-0000-00000000000b';
RESET ROLE;
SELECT is(
  (SELECT base_currency FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000b'),
  'USD',
  'A cannot update B profile'
);

-- B updates own profile
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
UPDATE public.profiles SET base_currency = 'PEN'
  WHERE id = '00000000-0000-0000-0000-00000000000b';
RESET ROLE;
SELECT is(
  (SELECT base_currency FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000b'),
  'PEN',
  'B can update own profile'
);

-- B attempts to update A
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
UPDATE public.profiles SET base_currency = 'USD'
  WHERE id = '00000000-0000-0000-0000-00000000000a';
RESET ROLE;
SELECT is(
  (SELECT base_currency FROM public.profiles WHERE id = '00000000-0000-0000-0000-00000000000a'),
  'EUR',
  'B cannot update A profile'
);

-- Anonymous access
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

-- Currency constraint
RESET ROLE;
SELECT throws_ok(
  $$ UPDATE public.profiles SET base_currency = 'GBP'
     WHERE id = '00000000-0000-0000-0000-00000000000a' $$,
  '23514',
  NULL,
  'base_currency outside PEN/USD/EUR is rejected'
);

SELECT * FROM finish();
ROLLBACK;
