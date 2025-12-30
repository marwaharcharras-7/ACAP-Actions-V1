
-- Add finalized_at column to track when action was finalized (for auto-archiving rule)
ALTER TABLE public.actions ADD COLUMN IF NOT EXISTS finalized_at TIMESTAMP WITH TIME ZONE;

-- Create function to auto-set finalized_at when status changes to 'completed' (finalisée)
CREATE OR REPLACE FUNCTION public.set_finalized_at()
RETURNS TRIGGER AS $$
BEGIN
  -- When status changes to 'completed', set finalized_at
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    NEW.finalized_at = NOW();
  END IF;
  
  -- When status changes away from 'completed', clear finalized_at
  IF NEW.status != 'completed' AND NEW.status != 'validated' AND NEW.status != 'archived' AND OLD.status IN ('completed', 'validated') THEN
    NEW.finalized_at = NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger to auto-set finalized_at
DROP TRIGGER IF EXISTS set_finalized_at_trigger ON public.actions;
CREATE TRIGGER set_finalized_at_trigger
BEFORE UPDATE ON public.actions
FOR EACH ROW
EXECUTE FUNCTION public.set_finalized_at();

-- Create function to check and auto-archive old finalized actions
CREATE OR REPLACE FUNCTION public.check_auto_archive()
RETURNS TRIGGER AS $$
BEGIN
  -- If action is completed/validated and finalized_at is more than 1 year ago, auto-archive
  IF NEW.status IN ('completed', 'validated') 
     AND NEW.finalized_at IS NOT NULL 
     AND NEW.finalized_at <= (NOW() - INTERVAL '1 year') THEN
    NEW.status = 'archived';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger to auto-archive on any update
DROP TRIGGER IF EXISTS check_auto_archive_trigger ON public.actions;
CREATE TRIGGER check_auto_archive_trigger
BEFORE UPDATE ON public.actions
FOR EACH ROW
EXECUTE FUNCTION public.check_auto_archive();
