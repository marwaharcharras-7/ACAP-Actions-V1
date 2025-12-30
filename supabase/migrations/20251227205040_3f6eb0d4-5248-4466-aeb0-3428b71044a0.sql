-- Allow users to delete their own attachments or admins/managers
CREATE POLICY "Users can delete own attachments"
ON public.attachments
FOR DELETE
USING (
  auth.uid() = uploaded_by_id 
  OR has_role(auth.uid(), 'admin'::app_role) 
  OR has_role(auth.uid(), 'manager'::app_role)
);