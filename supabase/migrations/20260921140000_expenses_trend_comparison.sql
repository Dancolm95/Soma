-- Tarea 4.3: six-month trend and month-over-month comparison (PEN-only).
-- Same authority pattern as Tasks 4.1/4.2: PostgreSQL RPC, SECURITY INVOKER,
-- RLS, auth.uid(), minimal grants, month-only input canonicalized
-- server-side over expense_date. Fixed 6-month window, no calendar table,
-- no views, no cache.
create function public.expenses_monthly_trend(p_month date)
returns table (period_start date, total numeric)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_month_start date;
  v_window_start date;
begin
  -- NULL is a contract error, never silently "current month".
  if p_month is null then
    raise exception 'p_month must not be null'
      using errcode = '22004';
  end if;
  -- No authenticated identity means no usable metrics: fail closed
  -- instead of ever returning zeros that look like valid metrics.
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  -- Any day of the month canonicalizes to that month; the full six-month
  -- window (M-5 .. M) is derived server-side.
  v_month_start := date_trunc('month', p_month)::date;
  v_window_start := (v_month_start - interval '5 months')::date;
  -- generate_series over offsets keeps month arithmetic exact across year
  -- boundaries without manual month-number logic; empty months stay as 0.
  return query
    select m.month_start, coalesce(sum(e.amount), 0::numeric)
      from (
        select ((v_window_start + (g.g * interval '1 month'))::date) as month_start
          from generate_series(0, 5) as g(g)
      ) m
      left join public.expenses e
        on e.user_id = auth.uid()
       and e.expense_date >= m.month_start
       and e.expense_date < (m.month_start + interval '1 month')::date
     group by m.month_start
     order by m.month_start asc;
end;
$$;

create function public.expenses_monthly_comparison(p_month date)
returns table (
  period_start date,
  current_total numeric,
  previous_period_start date,
  previous_total numeric,
  difference numeric,
  percentage_change numeric
)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_current_start date;
  v_previous_start date;
  v_next_start date;
  v_current numeric;
  v_previous numeric;
begin
  if p_month is null then
    raise exception 'p_month must not be null'
      using errcode = '22004';
  end if;
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  v_current_start := date_trunc('month', p_month)::date;
  v_previous_start := (v_current_start - interval '1 month')::date;
  v_next_start := (v_current_start + interval '1 month')::date;
  select coalesce(sum(e.amount), 0::numeric) into v_current
    from public.expenses e
   where e.user_id = auth.uid()
     and e.expense_date >= v_current_start
     and e.expense_date < v_next_start;
  select coalesce(sum(e.amount), 0::numeric) into v_previous
    from public.expenses e
   where e.user_id = auth.uid()
     and e.expense_date >= v_previous_start
     and e.expense_date < v_current_start;
  -- percentage_change stays NULL when previous_total = 0: the comparison
  -- is mathematically undefined and Flutter decides the presentation.
  -- No rounding is imposed here; numeric division stays exact.
  return query
    select v_current_start,
           v_current,
           v_previous_start,
           v_previous,
           v_current - v_previous,
           case
             when v_previous > 0 then ((v_current - v_previous) / v_previous) * 100
             else null::numeric
           end;
end;
$$;

-- Least privilege per function: revoke platform defaults explicitly,
-- then grant only authenticated. service_role keeps no EXECUTE here;
-- future backend use requires an explicit, reviewed grant.
revoke all on function public.expenses_monthly_trend(date) from public;
revoke all on function public.expenses_monthly_trend(date) from anon;
revoke all on function public.expenses_monthly_trend(date) from service_role;
grant execute on function public.expenses_monthly_trend(date) to authenticated;

revoke all on function public.expenses_monthly_comparison(date) from public;
revoke all on function public.expenses_monthly_comparison(date) from anon;
revoke all on function public.expenses_monthly_comparison(date) from service_role;
grant execute on function public.expenses_monthly_comparison(date) to authenticated;
