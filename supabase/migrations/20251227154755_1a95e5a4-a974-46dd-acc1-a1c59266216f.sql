-- Ajouter des politiques pour permettre la lecture anonyme (environnement de démo)
-- Ces politiques permettent au frontend de lire les données avant l'authentification Supabase

-- Profiles - lecture pour anon
CREATE POLICY "Anon can view profiles for demo" ON public.profiles FOR SELECT TO anon USING (true);

-- User roles - lecture pour anon (lecture seule, pas de modification)
CREATE POLICY "Anon can view roles for demo" ON public.user_roles FOR SELECT TO anon USING (true);

-- Services - lecture pour anon
CREATE POLICY "Anon can view services for demo" ON public.services FOR SELECT TO anon USING (true);

-- Lines - lecture pour anon
CREATE POLICY "Anon can view lines for demo" ON public.lines FOR SELECT TO anon USING (true);

-- Teams - lecture pour anon
CREATE POLICY "Anon can view teams for demo" ON public.teams FOR SELECT TO anon USING (true);

-- Posts - lecture pour anon
CREATE POLICY "Anon can view posts for demo" ON public.posts FOR SELECT TO anon USING (true);

-- Factories - lecture pour anon
CREATE POLICY "Anon can view factories for demo" ON public.factories FOR SELECT TO anon USING (true);

-- Actions - lecture pour anon
CREATE POLICY "Anon can view actions for demo" ON public.actions FOR SELECT TO anon USING (true);

-- Attachments - lecture pour anon
CREATE POLICY "Anon can view attachments for demo" ON public.attachments FOR SELECT TO anon USING (true);