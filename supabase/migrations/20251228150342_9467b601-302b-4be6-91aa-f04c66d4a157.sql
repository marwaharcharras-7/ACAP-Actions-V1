
-- Fix the log_action_changes function to use profiles instead of auth.users
-- and handle the case where user_id might not be in auth.users

CREATE OR REPLACE FUNCTION public.log_action_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  pilot_name TEXT;
BEGIN
  -- Get pilot name for context from profiles table
  SELECT first_name || ' ' || last_name INTO pilot_name
  FROM public.profiles WHERE id = COALESCE(NEW.pilot_id, OLD.pilot_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.action_history (action_id, user_id, user_name, event_type, new_value, details)
    VALUES (NEW.id, NULL, pilot_name, 'created', NEW.status, 'Action créée: ' || NEW.title);
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Log status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'status_changed', OLD.status, NEW.status, 'status', 
              'Statut changé de ' || OLD.status || ' à ' || NEW.status);
    END IF;
    
    -- Log progress changes
    IF OLD.progress_percent IS DISTINCT FROM NEW.progress_percent THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', OLD.progress_percent::TEXT, NEW.progress_percent::TEXT, 'progress_percent',
              'Progression: ' || OLD.progress_percent || '% → ' || NEW.progress_percent || '%');
    END IF;
    
    -- Log title changes
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', OLD.title, NEW.title, 'title', 'Titre modifié');
    END IF;
    
    -- Log description changes
    IF OLD.description IS DISTINCT FROM NEW.description THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', NULL, NULL, 'description', 'Description modifiée');
    END IF;
    
    -- Log due date changes
    IF OLD.due_date IS DISTINCT FROM NEW.due_date THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', OLD.due_date::TEXT, NEW.due_date::TEXT, 'due_date', 'Échéance modifiée');
    END IF;
    
    -- Log pilot changes
    IF OLD.pilot_id IS DISTINCT FROM NEW.pilot_id THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', OLD.pilot_id::TEXT, NEW.pilot_id::TEXT, 'pilot_id', 'Pilote modifié');
    END IF;
    
    -- Log efficiency changes
    IF OLD.efficiency_percent IS DISTINCT FROM NEW.efficiency_percent THEN
      INSERT INTO public.action_history (action_id, user_id, user_name, event_type, old_value, new_value, field_name, details)
      VALUES (NEW.id, NULL, pilot_name, 'updated', 
              COALESCE(OLD.efficiency_percent::TEXT, 'N/A'), 
              COALESCE(NEW.efficiency_percent::TEXT, 'N/A'), 
              'efficiency_percent',
              'Efficacité: ' || COALESCE(OLD.efficiency_percent::TEXT, 'N/A') || '% → ' || COALESCE(NEW.efficiency_percent::TEXT, 'N/A') || '%');
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Also drop the foreign key constraint on action_history.user_id if it exists
ALTER TABLE public.action_history DROP CONSTRAINT IF EXISTS action_history_user_id_fkey;
