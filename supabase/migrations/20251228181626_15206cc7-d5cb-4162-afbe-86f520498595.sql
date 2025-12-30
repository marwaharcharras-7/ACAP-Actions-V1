-- Migration pour réaffecter les IDs utilisateurs e10000... vers les vrais UUIDs
-- MAPPING:
-- admin@entreprise.com: e1000000-0000-0000-0000-000000000001 -> a19fea41-ff65-47e0-94fa-6f87068c0762 (existe déjà)
-- meryem.bennani@entreprise.com: e1000000-0000-0000-0000-000000000002 -> 70d50a7b-0d7d-429e-a58b-f03d1660fa97
-- naima.chentouf@entreprise.com: e1000000-0000-0000-0000-000000000003 -> 9012548c-f81b-4bb1-8b2e-181f97f0c308
-- youssef.elamrani@entreprise.com: e1000000-0000-0000-0000-000000000004 -> 09cf7ce7-ddc5-4aed-bba7-a3c2fcd914cf
-- hassan.aouini@entreprise.com: e1000000-0000-0000-0000-000000000005 -> 87beb91d-9c7e-433f-a6af-1d6aff14ff00
-- younes.elhachimi@entreprise.com: e1000000-0000-0000-0000-000000000006 -> 7b820e27-7ed6-4489-a66f-fa4fc0b53f7c
-- rachid.elidrissi@entreprise.com: e1000000-0000-0000-0000-000000000007 -> 46e91637-a27f-4933-b02c-12dfdded2817

-- 1. Mettre à jour les actions.created_by_id
UPDATE actions SET created_by_id = 'a19fea41-ff65-47e0-94fa-6f87068c0762' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000001';
UPDATE actions SET created_by_id = '70d50a7b-0d7d-429e-a58b-f03d1660fa97' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000002';
UPDATE actions SET created_by_id = '9012548c-f81b-4bb1-8b2e-181f97f0c308' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000003';
UPDATE actions SET created_by_id = '09cf7ce7-ddc5-4aed-bba7-a3c2fcd914cf' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000004';
UPDATE actions SET created_by_id = '87beb91d-9c7e-433f-a6af-1d6aff14ff00' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000005';
UPDATE actions SET created_by_id = '7b820e27-7ed6-4489-a66f-fa4fc0b53f7c' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000006';
UPDATE actions SET created_by_id = '46e91637-a27f-4933-b02c-12dfdded2817' WHERE created_by_id = 'e1000000-0000-0000-0000-000000000007';

-- 2. Mettre à jour services.responsible_id
UPDATE services SET responsible_id = 'a19fea41-ff65-47e0-94fa-6f87068c0762' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000001';
UPDATE services SET responsible_id = '70d50a7b-0d7d-429e-a58b-f03d1660fa97' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000002';
UPDATE services SET responsible_id = '9012548c-f81b-4bb1-8b2e-181f97f0c308' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000003';
UPDATE services SET responsible_id = '09cf7ce7-ddc5-4aed-bba7-a3c2fcd914cf' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000004';
UPDATE services SET responsible_id = '87beb91d-9c7e-433f-a6af-1d6aff14ff00' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000005';
UPDATE services SET responsible_id = '7b820e27-7ed6-4489-a66f-fa4fc0b53f7c' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000006';
UPDATE services SET responsible_id = '46e91637-a27f-4933-b02c-12dfdded2817' WHERE responsible_id = 'e1000000-0000-0000-0000-000000000007';

-- 3. Mettre à jour lines.supervisor_id
UPDATE lines SET supervisor_id = '87beb91d-9c7e-433f-a6af-1d6aff14ff00' WHERE supervisor_id = 'e1000000-0000-0000-0000-000000000005';
UPDATE lines SET supervisor_id = '7b820e27-7ed6-4489-a66f-fa4fc0b53f7c' WHERE supervisor_id = 'e1000000-0000-0000-0000-000000000006';

-- 4. Mettre à jour teams.leader_id
UPDATE teams SET leader_id = 'a19fea41-ff65-47e0-94fa-6f87068c0762' WHERE leader_id = 'e1000000-0000-0000-0000-000000000001';
UPDATE teams SET leader_id = '70d50a7b-0d7d-429e-a58b-f03d1660fa97' WHERE leader_id = 'e1000000-0000-0000-0000-000000000002';
UPDATE teams SET leader_id = '9012548c-f81b-4bb1-8b2e-181f97f0c308' WHERE leader_id = 'e1000000-0000-0000-0000-000000000003';
UPDATE teams SET leader_id = '09cf7ce7-ddc5-4aed-bba7-a3c2fcd914cf' WHERE leader_id = 'e1000000-0000-0000-0000-000000000004';
UPDATE teams SET leader_id = '87beb91d-9c7e-433f-a6af-1d6aff14ff00' WHERE leader_id = 'e1000000-0000-0000-0000-000000000005';
UPDATE teams SET leader_id = '7b820e27-7ed6-4489-a66f-fa4fc0b53f7c' WHERE leader_id = 'e1000000-0000-0000-0000-000000000006';
UPDATE teams SET leader_id = '46e91637-a27f-4933-b02c-12dfdded2817' WHERE leader_id = 'e1000000-0000-0000-0000-000000000007';

-- 5. Copier les données de profil des anciens vers les nouveaux profils

-- Meryem Bennani (manager Production)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000002',
  first_name = 'Meryem',
  last_name = 'Bennani'
WHERE id = '70d50a7b-0d7d-429e-a58b-f03d1660fa97';

-- Naima Chentouf (operator Production, Ligne M1, Team M1-A, Poste Montage)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000002',
  line_id = '75d7b97e-6e1e-4653-a4fe-b31254922e88',
  team_id = '4650268f-e122-471b-8226-1bf256b36831',
  post_id = 'e7e19dab-1f01-4a75-9471-ea73b090bf53'
WHERE id = '9012548c-f81b-4bb1-8b2e-181f97f0c308';

-- Youssef El Amrani (operator Production, Ligne Q1, Team Q1-A, Poste Inspection)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000002',
  line_id = 'b3bdef56-7a9e-48b7-bea0-a8a00b5637e4',
  team_id = 'aee0050d-2c1f-46c1-9fca-e63e067da3d0',
  post_id = '1c0448e1-59bc-4ef6-942b-ad75f786e8f7'
WHERE id = '09cf7ce7-ddc5-4aed-bba7-a3c2fcd914cf';

-- Hassan Aouini (supervisor Qualité, Ligne L1)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000001',
  line_id = '93e247dc-6e6d-4f89-b008-a5e7125fa620'
WHERE id = '87beb91d-9c7e-433f-a6af-1d6aff14ff00';

-- Younes El Hachimi (supervisor Qualité, Ligne L2)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000001',
  line_id = '6c7afbfd-3fb7-4ebf-958c-924f94486504'
WHERE id = '7b820e27-7ed6-4489-a66f-fa4fc0b53f7c';

-- Rachid El Idrissi (manager Maintenance)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000003',
  first_name = 'Rachid',
  last_name = 'El Idrissi'
WHERE id = '46e91637-a27f-4933-b02c-12dfdded2817';

-- Admin (service Qualité)
UPDATE profiles SET 
  service_id = 'a1000000-0000-0000-0000-000000000001',
  first_name = 'Admin',
  last_name = 'Système'
WHERE id = 'a19fea41-ff65-47e0-94fa-6f87068c0762';