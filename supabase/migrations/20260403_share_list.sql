-- ==========================================
-- CREATE SECURE RPC: Invite User By Email
-- ==========================================
-- This allows the front-end to pass an email address and securely 
-- add that user to the list members table without exposing all users!

create or replace function invite_user_by_email(p_list_id uuid, p_email text, p_role text default 'editor')
returns void as $$
declare
  v_user_id uuid;
begin
  -- 1. Find the target user's ID by their email in the profiles table
  select id into v_user_id from public.profiles where email = p_email;

  if v_user_id is null then
    raise exception 'User with email % not found. They must register first.', p_email;
  end if;

  -- 2. Security Check: Ensure the person running this function owns the list
  if not exists (select 1 from public.lists where id = p_list_id and owner_id = auth.uid()) then
    raise exception 'You do not have permission to invite members to this list.';
  end if;

  -- 3. Add them to the list_members table 
  -- (If they are already there, ignore the duplicate)
  insert into public.list_members (list_id, user_id, role, invited_by)
  values (p_list_id, v_user_id, p_role::member_role, auth.uid())
  on conflict do nothing;

  -- 4. Mark the list as explicitly shared 
  update public.lists set is_shared = true where id = p_list_id;
end;
$$ language plpgsql security definer;
