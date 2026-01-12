-- Create task_bundles table
CREATE TABLE IF NOT EXISTS public.task_bundles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT NOT NULL DEFAULT 'list',
  color TEXT NOT NULL DEFAULT '#009688',
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add bundle_id column to tasks table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'tasks'
    AND column_name = 'bundle_id'
  ) THEN
    ALTER TABLE public.tasks ADD COLUMN bundle_id UUID REFERENCES public.task_bundles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Add bundle_order column to tasks table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'tasks'
    AND column_name = 'bundle_order'
  ) THEN
    ALTER TABLE public.tasks ADD COLUMN bundle_order INTEGER;
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_task_bundles_household_id ON public.task_bundles(household_id);
CREATE INDEX IF NOT EXISTS idx_tasks_bundle_id ON public.tasks(bundle_id);

-- Enable Row Level Security
ALTER TABLE public.task_bundles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for task_bundles

-- Users can view bundles in their household
CREATE POLICY "Users can view bundles in their household" ON public.task_bundles
  FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM public.household_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can create bundles in their household
CREATE POLICY "Users can create bundles in their household" ON public.task_bundles
  FOR INSERT
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM public.household_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can update bundles in their household
CREATE POLICY "Users can update bundles in their household" ON public.task_bundles
  FOR UPDATE
  USING (
    household_id IN (
      SELECT household_id FROM public.household_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can delete bundles they created or if they're admin
CREATE POLICY "Users can delete bundles in their household" ON public.task_bundles
  FOR DELETE
  USING (
    household_id IN (
      SELECT household_id FROM public.household_members
      WHERE user_id = auth.uid()
    )
  );
