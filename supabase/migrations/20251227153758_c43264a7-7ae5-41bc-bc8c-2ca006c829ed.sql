-- Supprimer la contrainte FK sur user_roles pour les données de test
ALTER TABLE public.user_roles DROP CONSTRAINT user_roles_user_id_fkey;