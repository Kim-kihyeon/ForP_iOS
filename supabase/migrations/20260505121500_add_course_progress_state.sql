alter table public.courses
add column if not exists status text not null default 'planned';

alter table public.courses
add column if not exists visited_orders integer[] not null default '{}';

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'courses_status_check'
    ) then
        alter table public.courses
        add constraint courses_status_check
        check (status in ('planned', 'in_progress', 'completed', 'cancelled'));
    end if;
end $$;

update public.courses
set status = 'completed'
where is_ended = true
  and status = 'planned';

create index if not exists courses_status_idx
on public.courses(status);

create index if not exists courses_user_status_idx
on public.courses(user_id, status);
