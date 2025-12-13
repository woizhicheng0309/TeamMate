-- Add is_pinned column to chats table
ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_chats_is_pinned ON public.chats(is_pinned DESC);
