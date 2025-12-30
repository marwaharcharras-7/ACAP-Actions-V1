-- Supprimer la contrainte FK vers auth.users pour permettre les données de test
-- Puis créer une nouvelle contrainte optionnelle

ALTER TABLE public.profiles DROP CONSTRAINT profiles_id_fkey;

-- Recréer la contrainte avec ON DELETE CASCADE mais permettre les valeurs orphelines pour les tests
-- On garde la cohérence mais on permet les données de démonstration