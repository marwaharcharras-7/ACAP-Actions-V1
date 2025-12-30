-- Drop existing update policy for pilots
DROP POLICY IF EXISTS "Pilots can update their actions" ON public.actions;

-- Create new policy: Pilots can update actions they're assigned to
CREATE POLICY "Pilots can update assigned actions" 
ON public.actions 
FOR UPDATE 
USING (auth.uid() = pilot_id OR auth.uid() = created_by_id);

-- Create policy: Team leaders can update actions in their team scope
CREATE POLICY "Team leaders can update team actions" 
ON public.actions 
FOR UPDATE 
USING (
  has_role(auth.uid(), 'team_leader'::app_role) 
  AND (
    -- Action is in the team leader's team
    team_id IN (
      SELECT t.id FROM teams t WHERE t.leader_id = auth.uid()
    )
    OR
    -- Action is in a line where the team leader has a team
    line_id IN (
      SELECT t.line_id FROM teams t WHERE t.leader_id = auth.uid()
    )
    OR
    -- Action is in the team leader's assigned team/line/service
    team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid())
    OR line_id IN (SELECT line_id FROM profiles WHERE id = auth.uid())
    OR service_id IN (SELECT service_id FROM profiles WHERE id = auth.uid())
  )
);

-- Create policy: Supervisors can update actions in their line/service scope
CREATE POLICY "Supervisors can update line actions" 
ON public.actions 
FOR UPDATE 
USING (
  has_role(auth.uid(), 'supervisor'::app_role) 
  AND (
    -- Action is in a line supervised by this user
    line_id IN (
      SELECT l.id FROM lines l WHERE l.supervisor_id = auth.uid()
    )
    OR
    -- Action is in the supervisor's service
    service_id IN (SELECT service_id FROM profiles WHERE id = auth.uid())
    OR
    -- Action is in a team under the supervisor's line
    team_id IN (
      SELECT t.id FROM teams t 
      WHERE t.line_id IN (SELECT l.id FROM lines l WHERE l.supervisor_id = auth.uid())
    )
  )
);