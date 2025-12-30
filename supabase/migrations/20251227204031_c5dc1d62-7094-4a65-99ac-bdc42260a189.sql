-- Create action_history table to log all changes
CREATE TABLE public.action_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  action_id UUID NOT NULL REFERENCES public.actions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  user_name TEXT,
  event_type TEXT NOT NULL, -- 'created', 'status_changed', 'updated', 'comment_added'
  old_value TEXT,
  new_value TEXT,
  field_name TEXT, -- which field was changed
  details TEXT, -- additional details
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.action_history ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Authenticated users can view action history"
ON public.action_history
FOR SELECT
USING (true);

CREATE POLICY "System can insert history"
ON public.action_history
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Anon can view history for demo"
ON public.action_history
FOR SELECT
USING (true);

-- Create trigger function to log action changes
CREATE OR REPLACE FUNCTION public.log_action_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  pilot_name TEXT;
BEGIN
  -- Get pilot name for context
  SELECT first_name || ' ' || last_name INTO pilot_name
  FROM public.profiles WHERE id = COALESCE(NEW.pilot_id, OLD.pilot_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.action_history (action_id, user_id, user_name, event_type, new_value, details)
    VALUES (NEW.id, NEW.created_by_id, pilot_name, 'created', NEW.status, 'Action créée: ' || NEW.title);
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Log status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'status_changed', OLD.status, NEW.status, 'status', 
              'Statut changé de ' || OLD.status || ' à ' || NEW.status);
    END IF;
    
    -- Log progress changes
    IF OLD.progress_percent IS DISTINCT FROM NEW.progress_percent THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', OLD.progress_percent::TEXT, NEW.progress_percent::TEXT, 'progress_percent',
              'Progression: ' || OLD.progress_percent || '% → ' || NEW.progress_percent || '%');
    END IF;
    
    -- Log title changes
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', OLD.title, NEW.title, 'title', 'Titre modifié');
    END IF;
    
    -- Log description changes
    IF OLD.description IS DISTINCT FROM NEW.description THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', NULL, NULL, 'description', 'Description modifiée');
    END IF;
    
    -- Log due date changes
    IF OLD.due_date IS DISTINCT FROM NEW.due_date THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', OLD.due_date::TEXT, NEW.due_date::TEXT, 'due_date', 'Échéance modifiée');
    END IF;
    
    -- Log pilot changes
    IF OLD.pilot_id IS DISTINCT FROM NEW.pilot_id THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', OLD.pilot_id::TEXT, NEW.pilot_id::TEXT, 'pilot_id', 'Pilote modifié');
    END IF;
    
    -- Log efficiency changes
    IF OLD.efficiency_percent IS DISTINCT FROM NEW.efficiency_percent THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NEW.pilot_id, pilot_name, 'updated', 
              COALESCE(OLD.efficiency_percent::TEXT, 'N/A'), 
              COALESCE(NEW.efficiency_percent::TEXT, 'N/A'), 
              'efficiency_percent',
              'Efficacité: ' || COALESCE(OLD.efficiency_percent::TEXT, 'N/A') || '% → ' || COALESCE(NEW.efficiency_percent::TEXT, 'N/A') || '%');
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on actions table
CREATE TRIGGER action_history_trigger
AFTER INSERT OR UPDATE ON public.actions
FOR EACH ROW
EXECUTE FUNCTION public.log_action_changes();

-- Create index for faster queries
CREATE INDEX idx_action_history_action_id ON public.action_history(action_id);
CREATE INDEX idx_action_history_created_at ON public.action_history(created_at DESC);