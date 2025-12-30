-- ============================================
-- ENUMS
-- ============================================
CREATE TYPE app_role AS ENUM ('operator', 'team_leader', 'supervisor', 'manager', 'admin');
CREATE TYPE action_status AS ENUM ('identified', 'planned', 'in_progress', 'completed', 'late', 'validated', 'archived');
CREATE TYPE action_type AS ENUM ('corrective', 'preventive');
CREATE TYPE urgency_level AS ENUM ('low', 'medium', 'high');
CREATE TYPE category_5m AS ENUM ('main_oeuvre', 'matiere', 'methode', 'milieu', 'machine');

-- ============================================
-- TABLES ORGANISATIONNELLES
-- ============================================

-- Usines
CREATE TABLE public.factories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Services
CREATE TABLE public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  factory_id UUID REFERENCES public.factories(id) ON DELETE CASCADE,
  responsible_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lignes
CREATE TABLE public.lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
  supervisor_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Équipes
CREATE TABLE public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  line_id UUID REFERENCES public.lines(id) ON DELETE CASCADE NOT NULL,
  leader_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Postes
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- TABLES UTILISATEURS
-- ============================================

-- Profils
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  cv_url TEXT,
  date_of_birth DATE,
  hire_date DATE,
  skills TEXT[],
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  line_id UUID REFERENCES public.lines(id) ON DELETE SET NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  factory_id UUID REFERENCES public.factories(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rôles utilisateurs (table séparée pour sécurité)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  UNIQUE(user_id, role)
);

-- ============================================
-- TABLES ACTIONS
-- ============================================

-- Actions
CREATE TABLE public.actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  problem TEXT NOT NULL,
  root_cause TEXT,
  type action_type NOT NULL,
  status action_status NOT NULL DEFAULT 'identified',
  urgency urgency_level NOT NULL DEFAULT 'medium',
  category_5m category_5m,
  pilot_id UUID REFERENCES public.profiles(id) NOT NULL,
  created_by_id UUID REFERENCES public.profiles(id) NOT NULL,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  line_id UUID REFERENCES public.lines(id) ON DELETE SET NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  due_date TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  validated_at TIMESTAMPTZ,
  progress_percent INTEGER NOT NULL DEFAULT 0,
  efficiency_percent INTEGER,
  is_effective BOOLEAN,
  comments TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pièces jointes
CREATE TABLE public.attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_id UUID REFERENCES public.actions(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  size INTEGER NOT NULL,
  url TEXT NOT NULL,
  uploaded_by_id UUID REFERENCES public.profiles(id) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- AJOUTER FK POUR RESPONSABLES/LEADERS
-- ============================================
ALTER TABLE public.services ADD CONSTRAINT services_responsible_id_fkey FOREIGN KEY (responsible_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.lines ADD CONSTRAINT lines_supervisor_id_fkey FOREIGN KEY (supervisor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.teams ADD CONSTRAINT teams_leader_id_fkey FOREIGN KEY (leader_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE public.factories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FONCTIONS SECURITY DEFINER
-- ============================================

-- Fonction pour vérifier si un utilisateur a un rôle
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Fonction pour obtenir le rôle d'un utilisateur
CREATE OR REPLACE FUNCTION public.get_user_role(_user_id UUID)
RETURNS app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.user_roles WHERE user_id = _user_id LIMIT 1
$$;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Factories: lecture pour tous les authentifiés
CREATE POLICY "Authenticated users can view factories" ON public.factories FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage factories" ON public.factories FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Services: lecture pour tous les authentifiés
CREATE POLICY "Authenticated users can view services" ON public.services FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage services" ON public.services FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Lines: lecture pour tous les authentifiés
CREATE POLICY "Authenticated users can view lines" ON public.lines FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage lines" ON public.lines FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Teams: lecture pour tous les authentifiés
CREATE POLICY "Authenticated users can view teams" ON public.teams FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage teams" ON public.teams FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Posts: lecture pour tous les authentifiés
CREATE POLICY "Authenticated users can view posts" ON public.posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage posts" ON public.posts FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Profiles: lecture pour tous les authentifiés, modification de son propre profil
CREATE POLICY "Authenticated users can view profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- User Roles: lecture par admin uniquement (sécurité)
CREATE POLICY "Users can view own role" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage roles" ON public.user_roles FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Actions: lecture et gestion selon rôle
CREATE POLICY "Authenticated users can view actions" ON public.actions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can create actions" ON public.actions FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by_id);
CREATE POLICY "Pilots can update their actions" ON public.actions FOR UPDATE TO authenticated USING (auth.uid() = pilot_id OR auth.uid() = created_by_id);
CREATE POLICY "Admins and managers can manage all actions" ON public.actions FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'manager'));

-- Attachments
CREATE POLICY "Authenticated users can view attachments" ON public.attachments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can create attachments" ON public.attachments FOR INSERT TO authenticated WITH CHECK (auth.uid() = uploaded_by_id);
CREATE POLICY "Admins can manage attachments" ON public.attachments FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger pour créer automatiquement un profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Nouveau'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Utilisateur')
  );
  
  -- Assigner le rôle opérateur par défaut
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'operator');
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger pour mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_actions_updated_at
  BEFORE UPDATE ON public.actions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();