BEGIN;
SELECT plan(43);

-- Two identities, owned by auth.users. Custom B seed for isolation tests.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000a');
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000b');
INSERT INTO public.categories (user_id, name)
  VALUES ('00000000-0000-0000-0000-00000000000b', 'Privada B');

SELECT ok(
  (SELECT count(*)::int FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'categories') = 1,
  'categories table exists'
);

SELECT ok(relrowsecurity, 'RLS is enabled on categories')
  FROM pg_class
  WHERE oid = 'public.categories'::regclass;

SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'categories'
      AND constraint_type = 'FOREIGN KEY'),
  1,
  'FK user_id -> auth.users exists'
);

SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL),
  8,
  'system seed has 8 categories'
);

SELECT is(
  (SELECT count(*)::int FROM public.categories
    WHERE user_id IS NULL AND name IN ('Alimentación', 'Transporte', 'Vivienda',
      'Salud', 'Entretenimiento', 'Compras', 'Servicios', 'Otros')),
  8,
  'system seed names match the approved list'
);

SELECT is(
  (SELECT count(*)::int FROM pg_indexes
    WHERE schemaname = 'public' AND tablename = 'categories'
      AND indexname IN ('categories_system_name_uniq', 'categories_user_name_uniq')),
  2,
  'per-scope logical uniqueness indexes exist'
);

-- User A
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL),
  8,
  'A can read system categories'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (name) VALUES ('Mascotas') $$,
  'A can create own category with session-derived ownership'
);
SELECT is(
  (SELECT user_id::text FROM public.categories WHERE name = 'Mascotas' AND user_id IS NOT NULL),
  '00000000-0000-0000-0000-00000000000a',
  'ownership is derived from the authenticated session'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories),
  9,
  'A reads system plus own categories'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (name) VALUES ('Temporal A') $$,
  'A creates a second own category'
);
SELECT lives_ok(
  $$ UPDATE public.categories SET name = 'Renombrada A' WHERE name = 'Temporal A' $$,
  'A can rename own category'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE name = 'Renombrada A'),
  1,
  'rename of own category persisted'
);
SELECT lives_ok(
  $$ DELETE FROM public.categories WHERE name = 'Renombrada A' $$,
  'A can delete own category'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE name = 'Renombrada A'),
  0,
  'own category is gone after delete'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id = '00000000-0000-0000-0000-00000000000b'),
  0,
  'A cannot read B private categories'
);
UPDATE public.categories SET name = 'Hack'
  WHERE user_id = '00000000-0000-0000-0000-00000000000b';
RESET ROLE;
SELECT is(
  (SELECT count(*)::int FROM public.categories
    WHERE user_id = '00000000-0000-0000-0000-00000000000b' AND name = 'Privada B'),
  1,
  'A cannot modify B category'
);
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
DELETE FROM public.categories WHERE user_id = '00000000-0000-0000-0000-00000000000b';
RESET ROLE;
SELECT is(
  (SELECT count(*)::int FROM public.categories
    WHERE user_id = '00000000-0000-0000-0000-00000000000b' AND name = 'Privada B'),
  1,
  'A cannot delete B category'
);
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000b', 'Para B') $$,
  '42501',
  NULL,
  'A cannot create a category for B'
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name) VALUES (NULL, 'Sistema Falso') $$,
  '42501',
  NULL,
  'A cannot create a system category'
);
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = '00000000-0000-0000-0000-00000000000b'
     WHERE name = 'Mascotas' $$,
  '42501',
  NULL,
  'A cannot transfer own category to B'
);
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = NULL WHERE name = 'Mascotas' $$,
  '42501',
  NULL,
  'A cannot convert own category into a system one'
);
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = '00000000-0000-0000-0000-00000000000a'
     WHERE name = 'Mascotas' $$,
  '42501',
  NULL,
  'user_id is not client-editable'
);
UPDATE public.categories SET name = 'Hack' WHERE user_id IS NULL;
RESET ROLE;
SELECT is(
  (SELECT count(*)::int FROM public.categories
    WHERE user_id IS NULL AND name = 'Transporte'),
  1,
  'A cannot modify a system category'
);
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
DELETE FROM public.categories WHERE user_id IS NULL;
RESET ROLE;
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL),
  8,
  'A cannot delete system categories'
);

-- User B (symmetric isolation)
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL),
  8,
  'B can read system categories'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id = '00000000-0000-0000-0000-00000000000a'),
  0,
  'B cannot read A private categories'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (name) VALUES ('Mascotas') $$,
  'B can reuse A private name in its own scope'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE name = 'Mascotas'),
  2,
  'same name lives independently per user'
);

-- Anonymous access
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT count(*) FROM public.categories $$,
  '42501',
  NULL,
  'anonymous cannot read categories'
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (name) VALUES ('Anon') $$,
  '42501',
  NULL,
  'anonymous cannot insert categories'
);
SELECT throws_ok(
  $$ UPDATE public.categories SET name = 'Anon' WHERE name = 'Otros' $$,
  '42501',
  NULL,
  'anonymous cannot update categories'
);
SELECT throws_ok(
  $$ DELETE FROM public.categories WHERE name = 'Otros' $$,
  '42501',
  NULL,
  'anonymous cannot delete categories'
);

-- Name validation (constraints hold for every role)
RESET ROLE;
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', '') $$,
  '23514',
  NULL,
  'empty name is rejected'
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', '   ') $$,
  '23514',
  NULL,
  'blank-only name is rejected'
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', repeat('x', 61)) $$,
  '23514',
  NULL,
  'name longer than 60 chars is rejected'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', repeat('y', 60)) $$,
  '60-char name is accepted'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', 'Viajes') $$,
  'A creates Viajes'
);
SELECT throws_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', ' VIAJES ') $$,
  '23505',
  NULL,
  'logical duplicate of the same user is rejected'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000b', 'Viajes') $$,
  'same name is allowed for a different user'
);
SELECT lives_ok(
  $$ INSERT INTO public.categories (user_id, name)
     VALUES ('00000000-0000-0000-0000-00000000000a', 'Transporte') $$,
  'system name may overlap a private one'
);

-- Ownership follows the user off the platform.
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-00000000000b';
SELECT is(
  (SELECT count(*)::int FROM public.categories
    WHERE user_id = '00000000-0000-0000-0000-00000000000b'),
  0,
  'deleting a user cascades its private categories'
);
SELECT is(
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL),
  8,
  'system categories survive user deletion'
);

SELECT * FROM finish();
ROLLBACK;
