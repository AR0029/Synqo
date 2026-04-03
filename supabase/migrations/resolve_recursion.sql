-- Run this in Supabase SQL Editor to fix the infinite recursion bug

CREATE OR REPLACE FUNCTION current_user_is_owner(l_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS(SELECT 1 FROM lists WHERE id = l_id AND owner_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION current_user_is_member(l_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS(SELECT 1 FROM list_members WHERE list_id = l_id AND user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old recursive policies
DROP POLICY IF EXISTS "Users can view members of lists they have access to" ON public.list_members;
DROP POLICY IF EXISTS "Only list owners can manage members" ON public.list_members;
DROP POLICY IF EXISTS "Users can view lists they own or are members of" ON public.lists;

-- Apply clean non-recursive policies
CREATE POLICY "Users can view members of lists they are part of"
  ON public.list_members FOR SELECT
  USING ( current_user_is_owner(list_id) OR current_user_is_member(list_id) );

CREATE POLICY "Only list owners can manage members"
  ON public.list_members FOR ALL
  USING ( current_user_is_owner(list_id) );

CREATE POLICY "Users can view lists they own or are members of"
  ON public.lists FOR SELECT
  USING ( auth.uid() = owner_id OR current_user_is_member(id) );
