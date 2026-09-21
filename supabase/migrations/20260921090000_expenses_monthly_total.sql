-- Tarea 4.1: deterministic monthly expense total (PEN-only).
-- Authority for metrics is PostgreSQL. The client sends only a month; the
-- range is derived server-side from expense_date (never created_at, never a
-- client-supplied range). SECURITY INVOKER + RLS + auth.uid() + minimal
-- grants is the mandatory pattern for all Phase 4 RPCs.
create function public.expenses_monthly_total(p_month date)
returns table (period_start date, total numeric)
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
  -- No authenticated identity means no usable metrics. This can only be
  -- reached by roles that bypass RLS/grants, so fail closed instead of
  -- ever returning a cross-user (or global) aggregate.
  if auth.uid() is null then
    raise exception 'not authenticated'
      using errcode = '42501';
  end if;
  -- Any day of the month canonicalizes to that month; ranges stay
  -- server-derived so the client cannot request arbitrary periods.
  v_month_start := date_trunc('month', p_month)::date;
  v_next_month_start := (v_month_start + interval '1 month')::date;
  return query
    select v_month_start, coalesce(sum(e.amount), 0::numeric)
      from public.expenses e
     where e.user_id = auth.uid()
       and e.expense_date >= v_month_start
       and e.expense_date < v_next_month_start;
end;
$$;

-- Least privilege: PostgreSQL grants EXECUTE to PUBLIC by default on new
-- functions, and platform default privileges pre-grant the Data API roles,
-- so revoke explicitly before granting only authenticated. service_role
-- keeps no EXECUTE on this function: future backend use requires an
-- explicit, reviewed grant.
revoke all on function public.expenses_monthly_total(date) from public;
revoke all on function public.expenses_monthly_total(date) from anon;
revoke all on function public.expenses_monthly_total(date) from service_role;
grant execute on function public.expenses_monthly_total(date) to authenticated;
