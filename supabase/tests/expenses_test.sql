BEGIN;
SELECT plan(107);

-- Two identities. Private categories use fixed ids so cross-user negative
-- tests can reference the literal id (a subquery as A would return 0 rows
-- through RLS and insert nothing instead of raising). Ids stay opaque:
-- no scope is inferred from them.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000a');
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-00000000000b');
INSERT INTO public.categories (id, user_id, name)
  VALUES ('22222222-2222-2222-2222-22222222220a',
    '00000000-0000-0000-0000-00000000000a', 'Privada A');
INSERT INTO public.categories (id, user_id, name)
  VALUES ('22222222-2222-2222-2222-22222222220b',
    '00000000-0000-0000-0000-00000000000b', 'Privada B');

SELECT ok(
  (SELECT count(*)::int FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'expenses') = 1,
  'expenses table exists'
);
SELECT ok(relrowsecurity, 'RLS is enabled on expenses')
  FROM pg_class WHERE oid = 'public.expenses'::regclass;
SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND constraint_type = 'PRIMARY KEY'),
  1, 'expenses has a primary key');
SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND constraint_type = 'FOREIGN KEY'),
  2, 'expenses has FKs to user and category');
SELECT is(
  (SELECT confdeltype::text FROM pg_constraint
    WHERE conname = 'expenses_user_id_fkey'),
  'c', 'expenses.user -> auth.users is ON DELETE CASCADE');
SELECT is(
  (SELECT confdeltype::text FROM pg_constraint
    WHERE conname = 'expenses_category_id_fkey'),
  'r', 'expenses.category -> categories is ON DELETE RESTRICT');
SELECT is(
  (SELECT data_type FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'amount'),
  'numeric', 'amount is numeric');
SELECT is(
  (SELECT (numeric_precision::int, numeric_scale::int) FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'amount'),
  ROW(12, 2), 'amount is numeric(12,2)');
SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND constraint_name = 'expenses_amount_check'),
  1, 'amount check exists');
SELECT is(
  (SELECT data_type FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'expense_date'),
  'date', 'expense_date is date');
SELECT is(
  (SELECT count(*)::int FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND column_name = 'category_id' AND is_nullable = 'NO'),
  1, 'category_id is NOT NULL');
SELECT is(
  (SELECT count(*)::int FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND column_name = 'user_id' AND is_nullable = 'NO'),
  1, 'user_id is NOT NULL');
SELECT ok(
  (SELECT column_default FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'user_id')
    ILIKE '%auth.uid()%',
  'user_id defaults to auth.uid()');
SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'expenses'
      AND constraint_name = 'expenses_merchant_check'),
  1, 'merchant check exists');
SELECT is(
  (SELECT count(*)::int FROM information_schema.columns
    WHERE table_schema IN ('public') AND table_name IN ('expenses', 'categories')
      AND column_name IN ('owner_key', 'category_scope')),
  0, 'no owner_key/scope auxiliary columns anywhere');
SELECT is(
  (SELECT count(*)::int FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND constraint_name IN ('expenses_category_owner_check',
        'categories_id_scope_check', 'categories_id_owner_key_uniq')),
  0, 'no scope/check/aux-unique leftovers');
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_category_owned_by'),
  0, 'legacy ownership helper function is gone');
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_check_category_owner'),
  1, 'expense validator function exists');
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'categories_guard_expense_owner'),
  1, 'category guard function exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_check_category_owner'),
  false, 'expense validator is SECURITY INVOKER');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'categories_guard_expense_owner'),
  false, 'category guard is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig IS NOT NULL FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_check_category_owner'),
  'expense validator pins search_path');
SELECT ok(
  (SELECT proconfig IS NOT NULL FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'categories_guard_expense_owner'),
  'category guard pins search_path');
SELECT is(
  (SELECT count(*)::int FROM pg_trigger
    WHERE tgname = 'expenses_check_category_owner'),
  1, 'expense validator trigger exists');
SELECT is(
  (SELECT count(*)::int FROM pg_trigger
    WHERE tgname = 'categories_guard_expense_owner'),
  1, 'category guard trigger exists');
SELECT is(
  (SELECT count(*)::int FROM pg_trigger WHERE tgname = 'expenses_set_updated_at'),
  1, 'updated_at trigger exists');
SELECT is(
  (SELECT count(*)::int FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'expenses'),
  4, 'four RLS policies exist');
SELECT is(has_table_privilege('anon', 'public.expenses', 'SELECT'), false,
  'anon has no SELECT on expenses');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'user_id', 'INSERT'), false,
  'authenticated cannot INSERT user_id');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'amount', 'INSERT'), true,
  'authenticated can INSERT amount');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'user_id', 'UPDATE'), false,
  'authenticated cannot UPDATE user_id');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'amount', 'UPDATE'), true,
  'authenticated can UPDATE amount');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'id', 'UPDATE'), false,
  'authenticated cannot UPDATE id');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'created_at', 'UPDATE'), false,
  'authenticated cannot UPDATE created_at');
SELECT is(has_column_privilege('authenticated', 'public.expenses', 'updated_at', 'UPDATE'), false,
  'authenticated cannot UPDATE updated_at');
SELECT is(has_function_privilege('anon', 'public.expenses_check_category_owner()', 'EXECUTE'), false,
  'anon cannot EXECUTE the expense validator');
SELECT is(has_function_privilege('authenticated', 'public.expenses_check_category_owner()', 'EXECUTE'), false,
  'authenticated has no direct EXECUTE on the validator');
SELECT is(has_function_privilege('service_role', 'public.expenses_check_category_owner()', 'EXECUTE'), false,
  'service_role has no direct EXECUTE on the validator');
SELECT is(has_function_privilege('anon', 'public.categories_guard_expense_owner()', 'EXECUTE'), false,
  'anon cannot EXECUTE the category guard');
SELECT is(has_function_privilege('authenticated', 'public.categories_guard_expense_owner()', 'EXECUTE'), false,
  'authenticated has no direct EXECUTE on the category guard');
SELECT is(has_function_privilege('service_role', 'public.categories_guard_expense_owner()', 'EXECUTE'), false,
  'service_role has no direct EXECUTE on the category guard');
SELECT is(
  (SELECT count(*)::int FROM pg_proc p, LATERAL aclexplode(p.proacl) a
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname = 'expenses_check_category_owner'
      AND a.privilege_type = 'EXECUTE' AND a.grantee <> p.proowner),
  0, 'validator grants nobody: PUBLIC has no EXECUTE');
SELECT is(
  (SELECT count(*)::int FROM pg_proc p, LATERAL aclexplode(p.proacl) a
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname = 'categories_guard_expense_owner'
      AND a.privilege_type = 'EXECUTE' AND a.grantee <> p.proowner),
  0, 'guard grants nobody: PUBLIC has no EXECUTE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%pg_advisory_xact_lock(810311%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_check_category_owner'),
  'validator takes the per-category advisory lock');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%pg_advisory_xact_lock(810311%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'categories_guard_expense_owner'),
  'guard takes the same per-category advisory lock');

-- User A creates with session-derived ownership (validator runs as
-- authenticated under RLS here: proves INVOKER + RLS interoperate).
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT lives_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (19.99, '2026-09-01', 'A-global',
       '00000000-0000-0000-0000-000000000101') $$,
  'A creates expense with global category');
SELECT is(
  (SELECT user_id::text FROM public.expenses WHERE merchant = 'A-global'),
  '00000000-0000-0000-0000-00000000000a',
  'A ownership derived from session');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     SELECT 45.50, '2026-09-02', 'A-private', id FROM public.categories
      WHERE user_id = '00000000-0000-0000-0000-00000000000a' AND name = 'Privada A' $$,
  'A creates expense with own private category');
SELECT is((SELECT count(*)::int FROM public.expenses), 2, 'A reads both own expenses');
SELECT lives_ok(
  $$ UPDATE public.expenses SET amount = 99.99 WHERE merchant = 'A-global' $$,
  'A edits own amount');
SELECT is((SELECT amount::text FROM public.expenses WHERE merchant = 'A-global'),
  '99.99', 'amount edit persisted');
SELECT lives_ok(
  $$ UPDATE public.expenses SET merchant = 'A-global-edited' WHERE merchant = 'A-global' $$,
  'A edits own merchant');
SELECT lives_ok(
  $$ UPDATE public.expenses SET expense_date = '2026-08-15' WHERE merchant = 'A-global-edited' $$,
  'A edits own expense_date');
SELECT lives_ok(
  $$ UPDATE public.expenses SET category_id = (SELECT id FROM public.categories
      WHERE user_id = '00000000-0000-0000-0000-00000000000a' AND name = 'Privada A')
     WHERE merchant = 'A-global-edited' $$,
  'A switches global to own category');
SELECT lives_ok(
  $$ UPDATE public.expenses SET category_id = '00000000-0000-0000-0000-000000000101'
     WHERE merchant = 'A-global-edited' $$,
  'A switches own category back to global');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (5.00, '2026-09-03', 'A-temp',
       '00000000-0000-0000-0000-000000000101') $$,
  'A creates temp expense');
SELECT lives_ok($$ DELETE FROM public.expenses WHERE merchant = 'A-temp' $$,
  'A deletes own expense');
SELECT is((SELECT count(*)::int FROM public.expenses WHERE merchant = 'A-temp'), 0,
  'temp expense gone');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000b', 10.00, '2026-09-01', 'A-for-B',
       '00000000-0000-0000-0000-000000000101') $$,
  '42501', NULL, 'A cannot create expense for B');
RESET ROLE;

-- User B symmetric creation.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
SELECT lives_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (7.25, '2026-09-01', 'B-global',
       '00000000-0000-0000-0000-000000000101') $$,
  'B creates expense with global category');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     SELECT 12.00, '2026-09-02', 'B-private', id FROM public.categories
      WHERE user_id = '00000000-0000-0000-0000-00000000000b' AND name = 'Privada B' $$,
  'B creates expense with own private category');
SELECT is((SELECT count(*)::int FROM public.expenses), 2, 'B reads only own expenses');
RESET ROLE;

-- service_role needs no EXECUTE grant: honest write passes, cross write fails.
SET LOCAL ROLE service_role;
SELECT lives_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 3.00, '2026-09-04', 'Svc-own',
       '22222222-2222-2222-2222-22222222220a') $$,
  'service_role honest write triggers validation and passes');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000b', 3.00, '2026-09-04', 'Svc-cross',
       '22222222-2222-2222-2222-22222222220a') $$,
  '23503', NULL, 'service_role cross write triggers validation and fails');
RESET ROLE;
DELETE FROM public.expenses WHERE merchant LIKE 'Svc-%';

-- Cross-user isolation: A vs B expenses.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT is((SELECT count(*)::int FROM public.expenses WHERE merchant LIKE 'B-%'), 0,
  'A cannot read B expenses');
UPDATE public.expenses SET amount = 0.01 WHERE merchant = 'B-global';
RESET ROLE;
SELECT is((SELECT amount::text FROM public.expenses WHERE merchant = 'B-global'),
  '7.25', 'A cannot modify B expense');
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
DELETE FROM public.expenses WHERE merchant = 'B-global';
RESET ROLE;
SELECT is((SELECT count(*)::int FROM public.expenses WHERE merchant = 'B-global'), 1,
  'A cannot delete B expense');
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT throws_ok(
  $$ UPDATE public.expenses SET user_id = '00000000-0000-0000-0000-00000000000b'
     WHERE merchant = 'A-global-edited' $$,
  '42501', NULL, 'A cannot transfer expense to B');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (10.00, '2026-09-01', 'A-with-B-cat',
       '22222222-2222-2222-2222-22222222220b') $$,
  '23503', NULL, 'A cannot use private B category');
SELECT throws_ok(
  $$ UPDATE public.expenses SET category_id = '22222222-2222-2222-2222-22222222220b'
     WHERE merchant = 'A-global-edited' $$,
  '23503', NULL, 'A cannot switch to private B category');
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = '00000000-0000-0000-0000-00000000000b'
     WHERE id = '22222222-2222-2222-2222-22222222220b' $$,
  '42501', NULL, 'A cannot retarget categories via grants/RLS');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}',
  true
);
SELECT is((SELECT count(*)::int FROM public.expenses WHERE merchant LIKE 'A-%'), 0,
  'B cannot read A expenses');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (10.00, '2026-09-01', 'B-with-A-cat',
       '22222222-2222-2222-2222-22222222220a') $$,
  '23503', NULL, 'B cannot use private A category');
RESET ROLE;

-- Administrative invariant: retargeting private A to B must fail by trigger,
-- even bypassing RLS, while non-key updates keep working.
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = '00000000-0000-0000-0000-00000000000b'
     WHERE id = '22222222-2222-2222-2222-22222222220a' $$,
  '23503', NULL, 'admin cannot retarget private A to B while referenced');
SELECT is(
  (SELECT user_id::text FROM public.categories
    WHERE id = '22222222-2222-2222-2222-22222222220a'),
  '00000000-0000-0000-0000-00000000000a',
  'private A still owned by A after blocked retarget');
SELECT is(
  (SELECT count(*)::int FROM public.expenses
    WHERE category_id = '22222222-2222-2222-2222-22222222220a'
      AND user_id = '00000000-0000-0000-0000-00000000000a'),
  1, 'expense A still references private A');
SELECT throws_ok(
  $$ UPDATE public.categories SET user_id = '00000000-0000-0000-0000-00000000000b'
     WHERE id = '00000000-0000-0000-0000-000000000101' $$,
  '23503', NULL, 'admin cannot privatize a global with other-user expenses');
SELECT is(
  (SELECT user_id FROM public.categories
    WHERE id = '00000000-0000-0000-0000-000000000101'),
  NULL, 'global stays global after blocked privatization');
SELECT lives_ok(
  $$ UPDATE public.categories SET name = 'Privada A renombrada'
     WHERE id = '22222222-2222-2222-2222-22222222220a' $$,
  'non-key category update succeeds');
SELECT is(
  (SELECT count(*)::int FROM public.expenses
    WHERE category_id = '22222222-2222-2222-2222-22222222220a'),
  1, 'relation survives non-key category update');
SELECT lives_ok(
  $$ UPDATE public.categories SET name = 'Privada A'
     WHERE id = '22222222-2222-2222-2222-22222222220a' $$,
  'category name restored');

-- Category DELETE protection while in use.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT throws_ok(
  $$ DELETE FROM public.categories
     WHERE user_id = '00000000-0000-0000-0000-00000000000a' AND name = 'Privada A' $$,
  '23503', NULL, 'category in use cannot be deleted');
RESET ROLE;
SELECT is((SELECT count(*)::int FROM public.expenses WHERE merchant = 'A-private'), 1,
  'expense survives blocked category delete');
UPDATE public.expenses SET updated_at = '2020-01-01T00:00:00Z'
  WHERE merchant = 'A-private';
UPDATE public.expenses SET merchant = 'A-private-touched' WHERE merchant = 'A-private';
SELECT ok(
  (SELECT updated_at > '2020-01-01T00:00:00Z' FROM public.expenses
    WHERE merchant = 'A-private-touched'),
  'updated_at is controlled by DB on update');
UPDATE public.expenses SET merchant = 'A-private' WHERE merchant = 'A-private-touched';
SELECT lives_ok($$ DELETE FROM public.expenses WHERE merchant = 'A-private' $$,
  'remove expense using private A');
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT lives_ok(
  $$ DELETE FROM public.categories
     WHERE user_id = '00000000-0000-0000-0000-00000000000a' AND name = 'Privada A' $$,
  'unused private category can be deleted');
RESET ROLE;
SELECT lives_ok(
  $$ INSERT INTO public.categories (id, user_id, name)
     VALUES ('22222222-2222-2222-2222-22222222220a',
       '00000000-0000-0000-0000-00000000000a', 'Privada A') $$,
  'recreate private A for cascade check');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 45.50, '2026-09-02', 'A-private',
       '22222222-2222-2222-2222-22222222220a') $$,
  'recreate A-private expense for cascade check');

-- Grants: protected columns.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}',
  true
);
SELECT throws_ok(
  $$ UPDATE public.expenses SET id = gen_random_uuid() WHERE merchant = 'A-private' $$,
  '42501', NULL, 'authenticated cannot UPDATE id');
SELECT throws_ok(
  $$ UPDATE public.expenses SET created_at = now() WHERE merchant = 'A-private' $$,
  '42501', NULL, 'authenticated cannot UPDATE created_at');
SELECT throws_ok(
  $$ UPDATE public.expenses SET updated_at = now() WHERE merchant = 'A-private' $$,
  '42501', NULL, 'authenticated cannot UPDATE updated_at');
RESET ROLE;

-- Amount and merchant constraints hold for every role.
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 0, '2026-09-01', 'Zero',
       '00000000-0000-0000-0000-000000000101') $$,
  '23514', NULL, 'zero amount rejected');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', -5.00, '2026-09-01', 'Neg',
       '00000000-0000-0000-0000-000000000101') $$,
  '23514', NULL, 'negative amount rejected');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 19.90, '2026-09-01', 'Exact-pen',
       '00000000-0000-0000-0000-000000000101') $$,
  'positive PEN amount accepted');
SELECT is((SELECT amount::text FROM public.expenses WHERE merchant = 'Exact-pen'),
  '19.90', 'PEN amount stored with two decimals');
DELETE FROM public.expenses WHERE merchant = 'Exact-pen';
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 10.00, '2026-09-01', '',
       '00000000-0000-0000-0000-000000000101') $$,
  '23514', NULL, 'empty merchant rejected');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 10.00, '2026-09-01', '   ',
       '00000000-0000-0000-0000-000000000101') $$,
  '23514', NULL, 'blank merchant rejected');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 10.00, '2026-09-01', repeat('x', 121),
       '00000000-0000-0000-0000-000000000101') $$,
  '23514', NULL, 'merchant over 120 rejected');
SELECT lives_ok(
  $$ INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
     VALUES ('00000000-0000-0000-0000-00000000000a', 10.00, '2026-09-01', repeat('y', 120),
       '00000000-0000-0000-0000-000000000101') $$,
  '120-char merchant accepted');
DELETE FROM public.expenses WHERE merchant = repeat('y', 120);

-- Anonymous has no access.
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok($$ SELECT count(*) FROM public.expenses $$,
  '42501', NULL, 'anonymous cannot SELECT expenses');
SELECT throws_ok(
  $$ INSERT INTO public.expenses (amount, expense_date, merchant, category_id)
     VALUES (10.00, '2026-09-01', 'Anon',
       '00000000-0000-0000-0000-000000000101') $$,
  '42501', NULL, 'anonymous cannot INSERT expenses');
SELECT throws_ok(
  $$ UPDATE public.expenses SET merchant = 'Anon' WHERE merchant = 'A-private' $$,
  '42501', NULL, 'anonymous cannot UPDATE expenses');
SELECT throws_ok(
  $$ DELETE FROM public.expenses WHERE merchant = 'A-private' $$,
  '42501', NULL, 'anonymous cannot DELETE expenses');
RESET ROLE;

-- Deleting a user cascades its expenses and private categories.
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-00000000000a';
SELECT is((SELECT count(*)::int FROM public.expenses
  WHERE user_id = '00000000-0000-0000-0000-00000000000a'), 0,
  'deleting user removes its expenses');
SELECT is((SELECT count(*)::int FROM public.categories
  WHERE user_id = '00000000-0000-0000-0000-00000000000a'), 0,
  'deleting user removes its private categories');
SELECT is((SELECT count(*)::int FROM public.categories WHERE user_id IS NULL), 8,
  'global categories survive user deletion');
SELECT is((SELECT count(*)::int FROM public.expenses
  WHERE user_id = '00000000-0000-0000-0000-00000000000b'), 2,
  'other user expenses survive');

SELECT * FROM finish();
ROLLBACK;
