BEGIN;
SELECT plan(96);

-- Fixtures: A (trend Sep26 + year boundary Feb26), B (isolation),
-- C/D/E (comparison +/-/0), F (prev=0), G (above-max sum),
-- H (empty), I (Jan/Dec). Owner inserts; RPCs exercised only as roles.
INSERT INTO auth.users (id) VALUES
  ('77777777-7777-4777-8777-777777777777'),
  ('88888888-8888-4888-8888-888888888888'),
  ('10101010-1010-4101-8101-101010101010'),
  ('20202020-2020-4202-8202-202020202020'),
  ('30303030-3030-4303-8303-303030303030'),
  ('40404040-4040-4404-8404-404040404040'),
  ('50505050-5050-4505-8505-505050505050'),
  ('60606060-6060-4606-8606-606060606060'),
  ('70707070-7070-4707-8707-707070707070');
INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
VALUES
  ('77777777-7777-4777-8777-777777777777', 999.00, '2025-08-31', 'A-pre', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 5.00, '2025-09-10', 'A-s25', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 7.00, '2025-12-25', 'A-d25', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 11.00, '2026-01-15', 'A-j26', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 13.00, '2026-02-10', 'A-f26', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 999.00, '2026-03-01', 'A-postfeb', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 888.00, '2026-03-31', 'A-prewin', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 10.00, '2026-04-01', 'A-apr', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 20.00, '2026-06-15', 'A-jun', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 30.00, '2026-09-30', 'A-sep', '00000000-0000-0000-0000-000000000101'),
  ('77777777-7777-4777-8777-777777777777', 777.00, '2026-10-01', 'A-oct', '00000000-0000-0000-0000-000000000101'),
  ('88888888-8888-4888-8888-888888888888', 1000.00, '2026-04-10', 'B-apr', '00000000-0000-0000-0000-000000000101'),
  ('88888888-8888-4888-8888-888888888888', 5.00, '2026-09-05', 'B-sep', '00000000-0000-0000-0000-000000000101'),
  ('10101010-1010-4101-8101-101010101010', 100.00, '2026-05-10', 'C-prev', '00000000-0000-0000-0000-000000000101'),
  ('10101010-1010-4101-8101-101010101010', 120.00, '2026-06-12', 'C-cur', '00000000-0000-0000-0000-000000000101'),
  ('20202020-2020-4202-8202-202020202020', 100.00, '2026-05-10', 'D-prev', '00000000-0000-0000-0000-000000000101'),
  ('20202020-2020-4202-8202-202020202020', 80.00, '2026-06-12', 'D-cur', '00000000-0000-0000-0000-000000000101'),
  ('30303030-3030-4303-8303-303030303030', 100.00, '2026-05-10', 'E-prev', '00000000-0000-0000-0000-000000000101'),
  ('30303030-3030-4303-8303-303030303030', 100.00, '2026-06-12', 'E-cur', '00000000-0000-0000-0000-000000000101'),
  ('40404040-4040-4404-8404-404040404040', 50.00, '2026-06-12', 'F-cur', '00000000-0000-0000-0000-000000000101'),
  ('50505050-5050-4505-8505-505050505050', 9999999999.99, '2026-10-15', 'G-big1', '00000000-0000-0000-0000-000000000101'),
  ('50505050-5050-4505-8505-505050505050', 9999999999.99, '2026-10-20', 'G-big2', '00000000-0000-0000-0000-000000000101'),
  ('70707070-7070-4707-8707-707070707070', 40.00, '2025-12-10', 'I-dec', '00000000-0000-0000-0000-000000000101'),
  ('70707070-7070-4707-8707-707070707070', 60.00, '2026-01-12', 'I-jan', '00000000-0000-0000-0000-000000000101');

-- Trend contract.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_trend'),
  1, 'trend exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_trend'),
  false, 'trend is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'p_month date', 'trend takes only the month, no user_id');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'TABLE(period_start date, total numeric)',
  'trend returns period_start and numeric total');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend total stays numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_trend'),
  's', 'trend is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend identity comes from auth.uid()');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expense_date%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend filters on expense_date');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend rejects NULL deterministically');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%generate_series%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_trend'),
  'trend derives the six months server-side');
SELECT is(has_function_privilege('public', 'public.expenses_monthly_trend(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on trend');
SELECT is(has_function_privilege('anon', 'public.expenses_monthly_trend(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on trend');
SELECT is(has_function_privilege('authenticated', 'public.expenses_monthly_trend(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on trend');
SELECT is(has_function_privilege('service_role', 'public.expenses_monthly_trend(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on trend');

-- Comparison contract.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_comparison'),
  1, 'comparison exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_comparison'),
  false, 'comparison is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'p_month date', 'comparison takes only the month, no user_id');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'TABLE(period_start date, current_total numeric, previous_period_start date, previous_total numeric, difference numeric, percentage_change numeric)',
  'comparison returns current/previous, difference and numeric percentage');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
      AND pg_get_function_result(oid) NOT LIKE '%real%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison stays numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_monthly_comparison'),
  's', 'comparison is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison identity comes from auth.uid()');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expense_date%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison filters on expense_date');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'comparison rejects NULL deterministically');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%v_previous > 0%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_monthly_comparison'),
  'percentage is guarded on previous_total > 0');
SELECT is(has_function_privilege('public', 'public.expenses_monthly_comparison(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on comparison');
SELECT is(has_function_privilege('anon', 'public.expenses_monthly_comparison(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on comparison');
SELECT is(has_function_privilege('authenticated', 'public.expenses_monthly_comparison(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on comparison');
SELECT is(has_function_privilege('service_role', 'public.expenses_monthly_comparison(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on comparison');

-- No new stored objects.
SELECT ok(relrowsecurity, 'RLS is enabled on expenses')
  FROM pg_class WHERE oid = 'public.expenses'::regclass;
SELECT is(
  (SELECT count(*)::int FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename NOT IN ('profiles', 'categories', 'expenses')),
  0, 'no new tables');
SELECT is(
  (SELECT count(*)::int FROM pg_views WHERE schemaname = 'public'),
  0, 'no views or materialized views');
SELECT is(
  (SELECT count(*)::int FROM pg_indexes
    WHERE schemaname = 'public' AND tablename = 'expenses'),
  1, 'no new index on expenses (only the pkey)');

-- Trend A: September 2026 window with empty months as zero.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.expenses_monthly_trend('2026-09-15')),
  6, 'A september trend has exactly six rows');
SELECT is(
  (SELECT array_agg(t.period_start ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-15') t),
  ARRAY['2026-04-01','2026-05-01','2026-06-01','2026-07-01','2026-08-01','2026-09-01']::date[],
  'A trend covers M-5..M in ASC order on first days');
SELECT is(
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-15') t),
  ARRAY['10.00','0','20.00','0','0','30.00'],
  'A trend keeps empty months as zero');
SELECT ok(
  (SELECT every(t.total IS NOT NULL) FROM public.expenses_monthly_trend('2026-09-15') t),
  'trend totals are never NULL');
SELECT is(
  (SELECT pg_typeof(total)::text FROM public.expenses_monthly_trend('2026-09-15') LIMIT 1),
  'numeric', 'trend runtime total type is numeric');
SELECT is(
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-01') t),
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-15') t),
  'trend canonicalizes day 1 and day 15');
SELECT is(
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-15') t),
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-30') t),
  'trend canonicalizes day 15 and day 30');
SELECT is(
  (SELECT total FROM public.expenses_monthly_trend('2026-09-15')
    WHERE period_start = '2026-04-01'),
  10.00::numeric, 'expense on window lower bound is included');
SELECT is(
  (SELECT total FROM public.expenses_monthly_trend('2026-09-15')
    WHERE period_start = '2026-09-01'),
  30.00::numeric, 'expense inside M is included, M+1 excluded');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_trend(NULL) $$,
  '22004', NULL, 'trend NULL is rejected, never current month');
RESET ROLE;

-- Trend A: year boundary February 2026.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.expenses_monthly_trend('2026-02-15')),
  6, 'February trend still has six rows across the year boundary');
SELECT is(
  (SELECT array_agg(t.period_start ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-02-15') t),
  ARRAY['2025-09-01','2025-10-01','2025-11-01','2025-12-01','2026-01-01','2026-02-01']::date[],
  'February window spans 2025-09..2026-02');
SELECT is(
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-02-15') t),
  ARRAY['5.00','0','0','7.00','11.00','13.00'],
  'year-boundary totals are exact with zeros preserved');
SELECT is(
  (SELECT total FROM public.expenses_monthly_trend('2026-02-15')
    WHERE period_start = '2025-09-01'),
  5.00::numeric, 'expense before the window (2025-08-31) is excluded');
SELECT is(
  (SELECT total FROM public.expenses_monthly_trend('2026-02-15')
    WHERE period_start = '2026-02-01'),
  13.00::numeric, 'expense after the window (2026-03-01) is excluded');
RESET ROLE;

-- Trend B: isolation.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT array_agg(t.total::text ORDER BY t.period_start)
     FROM public.expenses_monthly_trend('2026-09-15') t),
  ARRAY['1000.00','0','0','0','0','5.00'],
  'B september trend is only B');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total FROM public.expenses_monthly_trend('2026-09-15')
    WHERE period_start = '2026-04-01'),
  10.00::numeric, 'A April unaffected by B same-window spend');
RESET ROLE;
-- Extra isolation probe: A still sees six rows, B never leaks.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.expenses_monthly_trend('2026-09-15')),
  6, 'B trend also has exactly six rows');
RESET ROLE;

-- Trend big sum (G, October 2026).
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"50505050-5050-4505-8505-505050505050","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total::text FROM public.expenses_monthly_trend('2026-10-20')
    WHERE period_start = '2026-10-01'),
  '19999999999.98', 'trend preserves sums above the one-row maximum');
SELECT is(
  (SELECT pg_typeof(total)::text FROM public.expenses_monthly_trend('2026-10-20') LIMIT 1),
  'numeric', 'big trend total stays numeric');
RESET ROLE;

-- Comparison C: previous=100 current=120.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"10101010-1010-4101-8101-101010101010","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-06-15')),
  120.00::numeric, 'C current_total is 120');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-06-15')),
  100.00::numeric, 'C previous_total is 100');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-15')),
  20.00::numeric, 'C difference is 20');
SELECT is(
  (SELECT percentage_change FROM public.expenses_monthly_comparison('2026-06-15')),
  20::numeric, 'C percentage is 20');
RESET ROLE;

-- Comparison D: previous=100 current=80.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"20202020-2020-4202-8202-202020202020","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-06-15')),
  80.00::numeric, 'D current_total is 80');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-06-15')),
  100.00::numeric, 'D previous_total is 100');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-15')),
  (-20.00)::numeric, 'D difference is -20');
SELECT is(
  (SELECT percentage_change FROM public.expenses_monthly_comparison('2026-06-15')),
  (-20)::numeric, 'D percentage is -20');
RESET ROLE;

-- Comparison E: previous=100 current=100.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"30303030-3030-4303-8303-303030303030","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-06-15')),
  100.00::numeric, 'E current_total is 100');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-06-15')),
  100.00::numeric, 'E previous_total is 100');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'E difference is 0');
SELECT is(
  (SELECT percentage_change FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'E percentage is 0');
RESET ROLE;

-- Comparison F: previous=0 current=50.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"40404040-4040-4404-8404-404040404040","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-06-15')),
  50.00::numeric, 'F current_total is 50');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'F previous_total is 0');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-15')),
  50.00::numeric, 'F difference is 50');
SELECT ok(
  (SELECT percentage_change IS NULL FROM public.expenses_monthly_comparison('2026-06-15')),
  'F percentage is NULL when previous is 0');
RESET ROLE;

-- Comparison H: both zero.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"60606060-6060-4606-8606-606060606060","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'H current_total is 0');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'H previous_total is 0');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-15')),
  0::numeric, 'H difference is 0');
SELECT ok(
  (SELECT percentage_change IS NULL FROM public.expenses_monthly_comparison('2026-06-15')),
  'H percentage is NULL when both are 0');
RESET ROLE;

-- Comparison A September: current=30 previous=0.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-09-20')),
  30.00::numeric, 'A september current is 30');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-09-20')),
  0::numeric, 'A august previous is 0');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-09-20')),
  30.00::numeric, 'A difference is 30');
SELECT ok(
  (SELECT percentage_change IS NULL FROM public.expenses_monthly_comparison('2026-09-20')),
  'A percentage is NULL when previous is 0');
RESET ROLE;

-- Comparison canonicalization + January/December + isolation + precision.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"10101010-1010-4101-8101-101010101010","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-01')),
  (SELECT difference FROM public.expenses_monthly_comparison('2026-06-30')),
  'comparison canonicalizes any day of the month');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"70707070-7070-4707-8707-707070707070","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-01-15')),
  60.00::numeric, 'January current is 60');
SELECT is(
  (SELECT previous_total FROM public.expenses_monthly_comparison('2026-01-15')),
  40.00::numeric, 'December previous is 40');
SELECT is(
  (SELECT difference FROM public.expenses_monthly_comparison('2026-01-15')),
  20.00::numeric, 'Jan-Dec difference is 20');
SELECT is(
  (SELECT percentage_change FROM public.expenses_monthly_comparison('2026-01-15')),
  50::numeric, 'Jan-Dec percentage is 50');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-09-15')),
  5.00::numeric, 'B september current is only B');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total FROM public.expenses_monthly_comparison('2026-09-15')),
  30.00::numeric, 'A september current unaffected by B');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"50505050-5050-4505-8505-505050505050","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT current_total::text FROM public.expenses_monthly_comparison('2026-10-20')),
  '19999999999.98', 'comparison preserves sums above the one-row maximum');
SELECT is(
  (SELECT difference::text FROM public.expenses_monthly_comparison('2026-10-20')),
  '19999999999.98', 'big comparison difference is exact');
SELECT ok(
  (SELECT percentage_change IS NULL FROM public.expenses_monthly_comparison('2026-10-20')),
  'big comparison percentage is NULL when previous is 0');
SELECT is(
  (SELECT pg_typeof(percentage_change)::text FROM public.expenses_monthly_comparison('2026-06-15') LIMIT 1),
  'numeric', 'percentage runtime type is numeric');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_comparison(NULL) $$,
  '22004', NULL, 'comparison NULL is rejected, never current month');
RESET ROLE;

-- No usable metrics without an authenticated identity, per function.
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_trend('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute trend');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_comparison('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute comparison');
RESET ROLE;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_trend('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no trend');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_monthly_comparison('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no comparison');

SELECT * FROM finish();
ROLLBACK;
