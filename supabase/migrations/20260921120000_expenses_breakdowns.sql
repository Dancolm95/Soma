-- Tarea 4.2: deterministic category/merchant breakdowns (PEN-only).
-- Same authority pattern as Task 4.1: PostgreSQL RPC, SECURITY INVOKER,
-- RLS, auth.uid(), minimal grants, month-only input canonicalized
-- server-side over expense_date. Small specific functions, no JSON
-- mega-function, no views, no cache.
create function public.expenses_spending_by_category(p_month date)
returns table (category_id uuid, category_name text, total numeric)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_month_start date;
  v_next_month_start date;
begin
  -- NULL is a contract error, never silently "current month".
  if p_month is null then
    raise exception 'p_month must not be null'
      using errcode = '22004';
  end if;
  -- No authenticated identity means no usable metrics: fail closed
  -- instead of ever returning a cross-user (or global) aggregate.
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  v_month_start := date_trunc('month', p_month)::date;
  v_next_month_start := (v_month_start + interval '1 month')::date;
  -- Grouped by category identity (id), not by name: a global and a
  -- private category stay distinct even with similar names. The join
  -- runs as the invoker under RLS, so only visible categories (global
  -- or own) can appear; the expense ownership invariant guarantees a
  -- valid expense never references anything else.
  return query
    select c.id, c.name, sum(e.amount)
      from public.expenses e
      join public.categories c on c.id = e.category_id
     where e.user_id = auth.uid()
       and e.expense_date >= v_month_start
       and e.expense_date < v_next_month_start
     group by c.id, c.name
     order by sum(e.amount) desc, c.name asc, c.id asc;
end;
$$;

-- Top 5 reuses the single grouping implementation above instead of
-- duplicating the aggregation; only ordering/limit are applied here.
create function public.expenses_top_categories(p_month date)
returns table (category_id uuid, category_name text, total numeric)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
begin
  if p_month is null then
    raise exception 'p_month must not be null'
      using errcode = '22004';
  end if;
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  return query
    select s.category_id, s.category_name, s.total
      from public.expenses_spending_by_category(p_month) s
     order by s.total desc, s.category_name asc, s.category_id asc
     limit 5;
end;
$$;

create function public.expenses_top_merchants(p_month date)
returns table (merchant text, total numeric)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_month_start date;
  v_next_month_start date;
begin
  if p_month is null then
    raise exception 'p_month must not be null'
      using errcode = '22004';
  end if;
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  v_month_start := date_trunc('month', p_month)::date;
  v_next_month_start := (v_month_start + interval '1 month')::date;
  -- merchants group by the exact persisted value: no lower/upper/trim,
  -- no fuzzy matching. 'Metro' and 'metro' stay separate groups.
  return query
    select e.merchant, sum(e.amount)
      from public.expenses e
     where e.user_id = auth.uid()
       and e.expense_date >= v_month_start
       and e.expense_date < v_next_month_start
     group by e.merchant
     order by sum(e.amount) desc, e.merchant asc
     limit 5;
end;
$$;

-- Least privilege per function: revoke platform defaults explicitly,
-- then grant only authenticated. service_role keeps no EXECUTE here;
-- future backend use requires an explicit, reviewed grant.
revoke all on function public.expenses_spending_by_category(date) from public;
revoke all on function public.expenses_spending_by_category(date) from anon;
revoke all on function public.expenses_spending_by_category(date) from service_role;
grant execute on function public.expenses_spending_by_category(date) to authenticated;

revoke all on function public.expenses_top_categories(date) from public;
revoke all on function public.expenses_top_categories(date) from anon;
revoke all on function public.expenses_top_categories(date) from service_role;
grant execute on function public.expenses_top_categories(date) to authenticated;

revoke all on function public.expenses_top_merchants(date) from public;
revoke all on function public.expenses_top_merchants(date) from anon;
revoke all on function public.expenses_top_merchants(date) from service_role;
grant execute on function public.expenses_top_merchants(date) to authenticated;
