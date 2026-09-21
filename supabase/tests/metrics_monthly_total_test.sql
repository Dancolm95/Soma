BEGIN;
SELECT plan(34);

-- Fixtures: A (boundaries + precision + above-max sum), B (isolation),
-- C (no expenses). Inserts run as owner; the RPC itself is exercised only
-- through authenticated roles below.
INSERT INTO auth.users (id) VALUES ('11111111-1111-4111-8111-111111111111');
INSERT INTO auth.users (id) VALUES ('22222222-2222-4222-8222-222222222222');
INSERT INTO auth.users (id) VALUES ('33333333-3333-4333-8333-333333333333');
INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
VALUES
  ('11111111-1111-4111-8111-111111111111', 0.01, '2026-09-01', 'A-b1',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 19.90, '2026-09-15', 'A-b2',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 100.09, '2026-09-30', 'A-b3',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 50.00, '2026-08-31', 'A-aug',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 60.00, '2026-10-01', 'A-oct',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 9999999999.99, '2026-10-15', 'A-big1',
    '00000000-0000-0000-0000-000000000101'),
  ('11111111-1111-4111-8111-111111111111', 9999999999.99, '2026-10-20', 'A-big2',
    '00000000-0000-0000-0000-000000000101'),
  ('22222222-2222-4222-8222-222222222222', 999.99, '2026-09-10', 'B-sep',
    '00000000-0000-0000-0000-000000000101');

-- Contract: existence, signature, volatility, determinism guards.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_total'),
  1, 'monthly total function exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_total'),
  false, 'monthly total is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'monthly total pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'p_month date', 'RPC takes only the month, no user_id parameter');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'TABLE(period_start date, total numeric)',
  'RPC returns period_start and numeric total');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%real%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'total stays exact numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_total'),
  's', 'monthly total is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'identity comes from auth.uid(), not from a parameter');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expense_date%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'period filters on expense_date');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'period never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%date_trunc(''month'', p_month)%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'month is canonicalized server-side');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_total'),
  'NULL month is rejected deterministically');

-- Authorization surface: RLS stays on, least-privilege ACL, no new index.
SELECT ok(relrowsecurity, 'RLS is enabled on expenses')
  FROM pg_class WHERE oid = 'public.expenses'::regclass;
SELECT is(has_function_privilege('public', 'public.expenses_monthly_total(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on the monthly total');
SELECT is(has_function_privilege('anon', 'public.expenses_monthly_total(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on the monthly total');
SELECT is(has_function_privilege('authenticated', 'public.expenses_monthly_total(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on the monthly total');
SELECT is(has_function_privilege('service_role', 'public.expenses_monthly_total(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on the monthly total');
SELECT is(
  (SELECT count(*)::int FROM pg_indexes
    WHERE schemaname = 'public' AND tablename = 'expenses'),
  1, 'no new index on expenses (only the pkey)');

-- User A: precision, boundaries, canonicalization, period_start.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-09-15')),
  120.00::numeric, 'A september total is exact (0.01 + 19.90 + 100.09)');
SELECT is(
  (SELECT total::text FROM public.expenses_monthly_total('2026-09-15')),
  '120.00', 'A september total keeps two decimals');
SELECT is(
  (SELECT period_start FROM public.expenses_monthly_total('2026-09-15')),
  '2026-09-01'::date, 'period_start is the canonical first of month');
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-08-15')),
  50.00::numeric, 'A august total excludes 2026-09-01');
SELECT is(
  (SELECT total::text FROM public.expenses_monthly_total('2026-10-10')),
  '20000000059.98', 'A october total excludes 2026-09-30 and exceeds one-row max');
SELECT is(
  (SELECT period_start FROM public.expenses_monthly_total('2026-10-10')),
  '2026-10-01'::date, 'october period_start is canonical');
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-09-01')),
  (SELECT total FROM public.expenses_monthly_total('2026-09-15')),
  'canonicalization: day 1 and day 15 agree');
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-09-15')),
  (SELECT total FROM public.expenses_monthly_total('2026-09-30')),
  'canonicalization: day 15 and day 30 agree');
SELECT is(
  (SELECT pg_typeof(total)::text FROM public.expenses_monthly_total('2026-09-15')),
  'numeric', 'runtime total type is numeric');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_total(NULL) $$,
  '22004', NULL, 'NULL month is rejected, never current month');
RESET ROLE;

-- User B: isolation in the same month.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-09-01')),
  999.99::numeric, 'B september total is only B (A rows invisible)');
SELECT is(
  (SELECT period_start FROM public.expenses_monthly_total('2026-09-01')),
  '2026-09-01'::date, 'B period_start is canonical');
RESET ROLE;

-- User C: empty month returns 0, never NULL.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total FROM public.expenses_monthly_total('2026-09-01')),
  0::numeric, 'user without expenses gets 0');
SELECT ok(
  (SELECT total IS NOT NULL FROM public.expenses_monthly_total('2026-09-01')),
  'empty month total is 0, never NULL');
RESET ROLE;

-- No usable metrics without an authenticated identity.
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_total('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute the monthly total');
RESET ROLE;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_total('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no metrics');

SELECT * FROM finish();
ROLLBACK;
