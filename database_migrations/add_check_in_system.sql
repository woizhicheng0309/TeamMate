-- Add check-in related columns to activities table
ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS check_in_start_time timestamp;
ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS check_in_code varchar;
ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS creator_checked_in boolean DEFAULT false;
ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS creator_check_in_time timestamp;
ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS creator_check_in_location point;

-- Create a participants_check_in table to track who checked in
CREATE TABLE IF NOT EXISTS public.participants_check_in (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  checked_in boolean DEFAULT false,
  check_in_time timestamp,
  check_in_location point,
  created_at timestamp DEFAULT now(),
  UNIQUE(activity_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_activities_check_in_start_time ON public.activities(check_in_start_time);
CREATE INDEX IF NOT EXISTS idx_participants_check_in_activity_id ON public.participants_check_in(activity_id);
CREATE INDEX IF NOT EXISTS idx_participants_check_in_user_id ON public.participants_check_in(user_id);

-- Add RLS policies for participants_check_in
ALTER TABLE public.participants_check_in ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view check-in records for activities they participate in
CREATE POLICY "Users can view their own check-in records" ON public.participants_check_in
  FOR SELECT
  USING (user_id = auth.uid());

-- Policy: Users can update their own check-in status
CREATE POLICY "Users can update their own check-in" ON public.participants_check_in
  FOR UPDATE
  USING (user_id = auth.uid());

-- Policy: Activity creators can view and update all check-in records for their activities
CREATE POLICY "Creators can manage check-ins for their activities" ON public.participants_check_in
  FOR ALL
  USING (
    activity_id IN (
      SELECT id FROM public.activities WHERE creator_id = auth.uid()
    )
  );
