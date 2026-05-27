-- Grant access per role for public.profiles
grant select on public.profiles to anon;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.profiles to service_role;

-- Grant access per role for public.lists
grant select on public.lists to anon;
grant select, insert, update, delete on public.lists to authenticated;
grant select, insert, update, delete on public.lists to service_role;

-- Grant access per role for public.list_members
grant select on public.list_members to anon;
grant select, insert, update, delete on public.list_members to authenticated;
grant select, insert, update, delete on public.list_members to service_role;

-- Grant access per role for public.tasks
grant select on public.tasks to anon;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.tasks to service_role;

-- Grant access per role for public.activity_logs
grant select on public.activity_logs to anon;
grant select, insert, update, delete on public.activity_logs to authenticated;
grant select, insert, update, delete on public.activity_logs to service_role;
