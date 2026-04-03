-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 0. Clean Slate (Drop existing tables/types/triggers if they exist)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP TRIGGER IF EXISTS lists_updated_at ON public.lists;
DROP TRIGGER IF EXISTS tasks_updated_at ON public.tasks;
DROP FUNCTION IF EXISTS handle_updated_at();

DROP TABLE IF EXISTS public.activity_logs CASCADE;
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.list_members CASCADE;
DROP TABLE IF EXISTS public.lists CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP TYPE IF EXISTS task_priority CASCADE;
DROP TYPE IF EXISTS member_role CASCADE;

-- 1. Create Tables

CREATE TABLE public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.lists (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  title text NOT NULL,
  owner_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  is_shared boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TYPE member_role AS ENUM ('owner', 'editor', 'viewer');

CREATE TABLE public.list_members (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id uuid REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role member_role DEFAULT 'viewer' NOT NULL,
  invited_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(list_id, user_id)
);

CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high');

CREATE TABLE public.tasks (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id uuid REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text,
  is_completed boolean DEFAULT false,
  priority task_priority DEFAULT 'medium',
  due_date timestamp with time zone,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.activity_logs (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id uuid REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
  task_id uuid REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  action text NOT NULL,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Setup Triggers for updated_at

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lists_updated_at BEFORE UPDATE ON public.lists FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- 3. Trigger for new user signup (creates profile)

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger whenever auth.users gets a new user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- 4. Enable Row Level Security (RLS)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

-- Profiles
CREATE POLICY "Users can view their own profile or profiles they share lists with"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR EXISTS (
      SELECT 1 FROM public.list_members lm1
      JOIN public.list_members lm2 ON lm1.list_id = lm2.list_id
      WHERE lm1.user_id = auth.uid() AND lm2.user_id = profiles.id
    )
  );

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Lists
CREATE POLICY "Users can view lists they own or are members of"
  ON public.lists FOR SELECT
  USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = lists.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert lists"
  ON public.lists FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update lists they own or are editors for"
  ON public.lists FOR UPDATE
  USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = lists.id AND user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "Users can delete own lists"
  ON public.lists FOR DELETE
  USING (auth.uid() = owner_id);

-- List Members
CREATE POLICY "Users can view members of lists they have access to"
  ON public.list_members FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.lists WHERE id = list_members.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members lm WHERE lm.list_id = list_members.list_id AND lm.user_id = auth.uid()
    )
  );

CREATE POLICY "Only list owners can manage members"
  ON public.list_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = list_members.list_id AND owner_id = auth.uid()
    )
  );

-- Tasks
CREATE POLICY "Users can view tasks in lists they have access to"
  ON public.tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = tasks.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = tasks.list_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert tasks in lists they own or edit"
  ON public.tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = tasks.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = tasks.list_id AND user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "Users can update tasks in lists they own or edit"
  ON public.tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = tasks.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = tasks.list_id AND user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "Users can delete tasks in lists they own or edit"
  ON public.tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = tasks.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = tasks.list_id AND user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

-- Activity Logs
CREATE POLICY "Users can view logs of lists they have access to"
  ON public.activity_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = activity_logs.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = activity_logs.list_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert logs in lists they have access to"
  ON public.activity_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.lists WHERE id = activity_logs.list_id AND owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.list_members WHERE list_id = activity_logs.list_id AND user_id = auth.uid()
    )
  );

-- 6. Enable Realtime for relevant tables globally
-- The realtime functionality uses Supabase publications
ALTER PUBLICATION supabase_realtime ADD TABLE public.lists;
ALTER PUBLICATION supabase_realtime ADD TABLE public.list_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
