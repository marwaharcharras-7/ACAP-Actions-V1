-- Create notifications table for real-time admin notifications
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('user_created', 'user_updated', 'action_created', 'action_completed', 'action_late', 'role_changed')),
  message TEXT NOT NULL,
  related_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  related_action_id UUID REFERENCES public.actions(id) ON DELETE SET NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Only admins can see notifications
CREATE POLICY "Admins can view notifications"
ON public.notifications
FOR SELECT
USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can manage notifications"
ON public.notifications
FOR ALL
USING (has_role(auth.uid(), 'admin'));

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Create function to auto-create notifications on profile insert
CREATE OR REPLACE FUNCTION public.notify_on_profile_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (type, message, related_user_id)
  VALUES (
    'user_created',
    'Nouvel utilisateur: ' || NEW.first_name || ' ' || NEW.last_name,
    NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for new profiles
CREATE TRIGGER on_profile_created
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_profile_created();

-- Create function to notify on action status change
CREATE OR REPLACE FUNCTION public.notify_on_action_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'late' AND OLD.status != 'late' THEN
    INSERT INTO public.notifications (type, message, related_action_id)
    VALUES (
      'action_late',
      'Action en retard: ' || NEW.title,
      NEW.id
    );
  ELSIF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO public.notifications (type, message, related_action_id)
    VALUES (
      'action_completed',
      'Action finalisée: ' || NEW.title,
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for action status changes
CREATE TRIGGER on_action_status_change
  AFTER UPDATE ON public.actions
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.notify_on_action_status_change();