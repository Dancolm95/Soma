BEGIN;
SELECT plan(90);

-- Fixtures: D (ties, 6 categories/merchants, out-of-month, above-max
-- October sum), E (same merchant text, same private-category name, own
-- totals), F (no expenses). Owner inserts; RPCs exercised only as roles.
INSERT INTO auth.users (id) VALUES ('44444444-4444-4444-8444-444444444444');
INSERT INTO auth.users (id) VALUES ('55555555-5555-5555-8555-555555555555');
INSERT INTO auth.users (id) VALUES ('66666666-6666-6666-8666-666666666666');
INSERT INTO public.categories (id, user_id, name) VALUES
  ('44444444-4444-4444-8444-444444444d01',
    '44444444-4444-4444-8444-444444444444', 'Mascotas'),
  ('44444444-4444-4444-8444-444444444d02',
    '44444444-4444-4444-8444-444444444444', 'Juegos'),
  ('55555555-5555-5555-8555-555555555e01',
    '55555555-5555-5555-8555-555555555555', 'Privada E'),
  ('55555555-5555-5555-8555-555555555e02',
    '55555555-5555-5555-8555-555555555555', 'Mascotas');
INSERT INTO public.expenses (user_id, amount, expense_date, merchant, category_id)
VALUES
  ('44444444-4444-4444-8444-444444444444', 10.00, '2026-09-05', 'Metro',
    '00000000-0000-0000-0000-000000000101'),
  ('44444444-4444-4444-8444-444444444444', 0.05, '2026-09-06', 'metro',
    '00000000-0000-0000-0000-000000000101'),
  ('44444444-4444-4444-8444-444444444444', 30.00, '2026-09-07', 'Metro',
    '00000000-0000-0000-0000-000000000102'),
  ('44444444-4444-4444-8444-444444444444', 100.00, '2026-09-08', 'Vet',
    '44444444-4444-4444-8444-444444444d01'),
  ('44444444-4444-4444-8444-444444444444', 100.00, '2026-09-09', 'Steam',
    '44444444-4444-4444-8444-444444444d02'),
  ('44444444-4444-4444-8444-444444444444', 5.00, '2026-09-10', 'Farmacia',
    '00000000-0000-0000-0000-000000000104'),
  ('44444444-4444-4444-8444-444444444444', 200.00, '2026-09-11', 'Luz del Sur',
    '00000000-0000-0000-0000-000000000103'),
  ('44444444-4444-4444-8444-444444444444', 1000.00, '2026-08-31', 'Out-ago',
    '00000000-0000-0000-0000-000000000101'),
  ('44444444-4444-4444-8444-444444444444', 9999999999.99, '2026-10-15', 'Big1',
    '00000000-0000-0000-0000-000000000102'),
  ('44444444-4444-4444-8444-444444444444', 9999999999.99, '2026-10-20', 'Big2',
    '00000000-0000-0000-0000-000000000102'),
  ('55555555-5555-5555-8555-555555555555', 777.77, '2026-09-12', 'Metro',
    '55555555-5555-5555-8555-555555555e01'),
  ('55555555-5555-5555-8555-555555555555', 50.00, '2026-09-13', 'E-pet',
    '55555555-5555-5555-8555-555555555e02'),
  ('55555555-5555-5555-8555-555555555555', 1.00, '2026-09-14', 'E-shop',
    '00000000-0000-0000-0000-000000000104');

-- spending_by_category contract.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_spending_by_category'),
  1, 'spending_by_category exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_spending_by_category'),
  false, 'spending_by_category is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending_by_category pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'p_month date', 'spending takes only the month, no user_id');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'TABLE(category_id uuid, category_name text, total numeric)',
  'spending returns category identity, name and numeric total');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending total stays numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_spending_by_category'),
  's', 'spending_by_category is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending identity comes from auth.uid()');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expense_date%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending filters on expense_date');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_spending_by_category'),
  'spending rejects NULL deterministically');
SELECT is(has_function_privilege('public', 'public.expenses_spending_by_category(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on spending');
SELECT is(has_function_privilege('anon', 'public.expenses_spending_by_category(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on spending');
SELECT is(has_function_privilege('authenticated', 'public.expenses_spending_by_category(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on spending');
SELECT is(has_function_privilege('service_role', 'public.expenses_spending_by_category(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on spending');

-- top_categories contract.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_categories'),
  1, 'top_categories exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_categories'),
  false, 'top_categories is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'p_month date', 'top_categories takes only the month, no user_id');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'TABLE(category_id uuid, category_name text, total numeric)',
  'top_categories returns category identity, name and numeric total');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories total stays numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_categories'),
  's', 'top_categories is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories identity comes from auth.uid()');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expenses_spending_by_category%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories reuses the single grouping implementation');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_categories'),
  'top_categories rejects NULL deterministically');
SELECT is(has_function_privilege('public', 'public.expenses_top_categories(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on top_categories');
SELECT is(has_function_privilege('anon', 'public.expenses_top_categories(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on top_categories');
SELECT is(has_function_privilege('authenticated', 'public.expenses_top_categories(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on top_categories');
SELECT is(has_function_privilege('service_role', 'public.expenses_top_categories(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on top_categories');

-- top_merchants contract.
SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_merchants'),
  1, 'top_merchants exists');
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_merchants'),
  false, 'top_merchants is SECURITY INVOKER');
SELECT ok(
  (SELECT proconfig::text LIKE '%search_path=public, pg_temp%' FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants pins search_path');
SELECT is(
  (SELECT pg_get_function_arguments(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'p_month date', 'top_merchants takes only the month, no user_id');
SELECT is(
  (SELECT pg_get_function_result(oid) FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'TABLE(merchant text, total numeric)',
  'top_merchants returns exact merchant and numeric total');
SELECT ok(
  (SELECT pg_get_function_result(oid) LIKE '%numeric%'
      AND pg_get_function_result(oid) NOT LIKE '%double%'
      AND pg_get_function_result(oid) NOT LIKE '%float%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants total stays numeric, never float');
SELECT is(
  (SELECT provolatile FROM pg_proc WHERE pronamespace = 'public'::regnamespace
     AND proname = 'expenses_top_merchants'),
  's', 'top_merchants is STABLE');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%auth.uid()%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants identity comes from auth.uid()');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%expense_date%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants filters on expense_date');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%created_at%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants never uses created_at');
SELECT ok(
  (SELECT pg_get_functiondef(oid) NOT LIKE '%lower(%'
      AND pg_get_functiondef(oid) NOT LIKE '%upper(%'
      AND pg_get_functiondef(oid) NOT LIKE '%trim(%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'merchants group by the exact persisted value');
SELECT ok(
  (SELECT pg_get_functiondef(oid) LIKE '%22004%'
    FROM pg_proc WHERE pronamespace = 'public'::regnamespace
      AND proname = 'expenses_top_merchants'),
  'top_merchants rejects NULL deterministically');
SELECT is(has_function_privilege('public', 'public.expenses_top_merchants(date)', 'EXECUTE'), false,
  'PUBLIC has no EXECUTE on top_merchants');
SELECT is(has_function_privilege('anon', 'public.expenses_top_merchants(date)', 'EXECUTE'), false,
  'anon has no EXECUTE on top_merchants');
SELECT is(has_function_privilege('authenticated', 'public.expenses_top_merchants(date)', 'EXECUTE'), true,
  'authenticated has EXECUTE on top_merchants');
SELECT is(has_function_privilege('service_role', 'public.expenses_top_merchants(date)', 'EXECUTE'), false,
  'service_role has no EXECUTE on top_merchants');

-- No new stored objects: RLS stays on, no tables/views/indexes added.
SELECT ok(relrowsecurity, 'RLS is enabled on expenses')
  FROM pg_class WHERE oid = 'public.expenses'::regclass;
SELECT ok(relrowsecurity, 'RLS is enabled on categories')
  FROM pg_class WHERE oid = 'public.categories'::regclass;
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

-- User D: spending, grouping, deterministic order, boundaries.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.expenses_spending_by_category('2026-09-01')),
  6, 'D september spending has six categories (out-of-month excluded)');
SELECT is(
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_spending_by_category('2026-09-01') s),
  ARRAY['Vivienda','Juegos','Mascotas','Transporte','Alimentación','Salud'],
  'spending order is total DESC with name tie-break (Juegos before Mascotas)');
SELECT is(
  (SELECT array_agg(s.total::text ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_spending_by_category('2026-09-01') s),
  ARRAY['200.00','100.00','100.00','30.00','10.05','5.00'],
  'spending totals are exact (same-category sums, no float)');
SELECT is(
  (SELECT category_id::text FROM public.expenses_spending_by_category('2026-09-01')
    WHERE category_name = 'Mascotas'),
  '44444444-4444-4444-8444-444444444d01',
  'grouping is by category identity, name comes from the join');
SELECT is(
  (SELECT total FROM public.expenses_spending_by_category('2026-09-01')
    WHERE category_name = 'Alimentación'),
  10.05::numeric, 'global category sums only in-month rows (1000.00 of 08-31 excluded)');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_spending_by_category('2026-09-01')
    WHERE category_name = 'Entretenimiento'),
  0, 'category without spend is absent, never zero-filled');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_categories('2026-09-01')),
  5, 'top_categories returns at most five rows');
SELECT is(
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_top_categories('2026-09-01') s),
  ARRAY['Vivienda','Juegos','Mascotas','Transporte','Alimentación'],
  'top five categories are the correct ones in order');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_categories('2026-09-01')
    WHERE category_name = 'Salud'),
  0, 'sixth category is excluded from the top');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_merchants('2026-09-01')),
  5, 'top_merchants returns at most five rows');
SELECT is(
  (SELECT array_agg(s.merchant ORDER BY s.total DESC, s.merchant ASC)
     FROM public.expenses_top_merchants('2026-09-01') s),
  ARRAY['Luz del Sur','Steam','Vet','Metro','Farmacia'],
  'merchant order is total DESC with merchant ASC tie-break (Steam before Vet)');
SELECT is(
  (SELECT array_agg(s.total::text ORDER BY s.total DESC, s.merchant ASC)
     FROM public.expenses_top_merchants('2026-09-01') s),
  ARRAY['200.00','100.00','100.00','40.00','5.00'],
  'merchant totals are exact (Metro sums two expenses)');
SELECT is(
  (SELECT total FROM public.expenses_top_merchants('2026-09-01')
    WHERE merchant = 'Metro'),
  40.00::numeric, 'Metro total excludes lowercase metro (exact grouping)');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_merchants('2026-09-01')
    WHERE merchant = 'metro'),
  0, 'lowercase metro stays a separate group outside the top');
SELECT is(
  (SELECT pg_typeof(total)::text FROM public.expenses_spending_by_category('2026-09-01') LIMIT 1),
  'numeric', 'runtime total type is numeric');
SELECT is(
  (SELECT total::text FROM public.expenses_spending_by_category('2026-10-01')
    WHERE category_name = 'Transporte'),
  '19999999999.98', 'aggregate exceeds the one-row maximum exactly');
SELECT is(
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_spending_by_category('2026-09-20') s),
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_spending_by_category('2026-09-01') s),
  'spending canonicalizes any day of the month');
SELECT is(
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_top_categories('2026-09-20') s),
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_top_categories('2026-09-01') s),
  'top_categories canonicalizes any day of the month');
SELECT is(
  (SELECT array_agg(s.merchant ORDER BY s.total DESC, s.merchant ASC)
     FROM public.expenses_top_merchants('2026-09-20') s),
  (SELECT array_agg(s.merchant ORDER BY s.total DESC, s.merchant ASC)
     FROM public.expenses_top_merchants('2026-09-01') s),
  'top_merchants canonicalizes any day of the month');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_spending_by_category(NULL) $$,
  '22004', NULL, 'spending NULL is rejected, never current month');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_categories(NULL) $$,
  '22004', NULL, 'top_categories NULL is rejected, never current month');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_merchants(NULL) $$,
  '22004', NULL, 'top_merchants NULL is rejected, never current month');
RESET ROLE;

-- User E: isolation with same merchant text and same private name.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-5555-8555-555555555555","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT array_agg(s.category_name ORDER BY s.total DESC, s.category_name ASC, s.category_id ASC)
     FROM public.expenses_spending_by_category('2026-09-01') s),
  ARRAY['Privada E','Mascotas','Salud'],
  'E september spending is only E');
SELECT is(
  (SELECT category_id::text FROM public.expenses_spending_by_category('2026-09-01')
    WHERE category_name = 'Mascotas'),
  '55555555-5555-5555-8555-555555555e02',
  'same private name is a different identity per user');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_spending_by_category('2026-09-01')
    WHERE category_id = '44444444-4444-4444-8444-444444444d01'),
  0, 'D private category never leaks into E');
SELECT is(
  (SELECT total FROM public.expenses_top_merchants('2026-09-01')
    WHERE merchant = 'Metro'),
  777.77::numeric, 'same merchant text keeps per-user totals');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_categories('2026-09-01')),
  3, 'fewer than five categories returns all of them');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_merchants('2026-09-01')),
  3, 'fewer than five merchants returns all of them');
RESET ROLE;

-- D again: E rows never contaminate D.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT total FROM public.expenses_top_merchants('2026-09-01')
    WHERE merchant = 'Metro'),
  40.00::numeric, 'D Metro total unaffected by E same-text merchant');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_spending_by_category('2026-09-01')),
  6, 'D still sees only its six categories');
RESET ROLE;

-- User F: empty month yields empty sets, never zero rows.
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"66666666-6666-6666-8666-666666666666","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::int FROM public.expenses_spending_by_category('2026-09-01')),
  0, 'empty month spending is an empty set');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_categories('2026-09-01')),
  0, 'empty month top_categories is an empty set');
SELECT is(
  (SELECT count(*)::int FROM public.expenses_top_merchants('2026-09-01')),
  0, 'empty month top_merchants is an empty set');
RESET ROLE;

-- No usable metrics without an authenticated identity, per function.
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_spending_by_category('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute spending');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_categories('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute top_categories');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_merchants('2026-09-01') $$,
  '42501', NULL, 'anon cannot execute top_merchants');
RESET ROLE;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_spending_by_category('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no spending');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_categories('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no top_categories');
SELECT throws_ok(
  $$ SELECT * FROM public.expenses_top_merchants('2026-09-01') $$,
  '42501', NULL, 'no identity without a grant yields no top_merchants');

SELECT * FROM finish();
ROLLBACK;
