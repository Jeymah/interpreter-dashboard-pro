INTERPRETER DASHBOARD PRO — PACK DE BASE

CONTENU
- index.html : interface web et connexion
- app.js : tableau de bord, clients, missions, factures, paiements, dépenses, calendrier et statistiques
- styles.css : interface responsive PC / Android
- config.js : paramètres publics du NOUVEAU projet Supabase (à renseigner)
- setup_supabase.sql : création des tables, fonction d'espace et règles RLS
- manifest.webmanifest et sw.js : base PWA installable

IMPORTANT — NOUVELLE INSTALLATION
Ce pack ne pointe plus vers l'ancien projet Supabase. L'URL et la clé sont volontairement des valeurs de remplacement dans config.js. Ne publiez jamais une clé service_role ou une clé secrète dans le navigateur.

ÉTAPES DE MISE EN SERVICE
1. Créer un nouveau projet dans Supabase.
2. Dans Supabase > SQL Editor, ouvrir setup_supabase.sql, coller tout son contenu et exécuter.
3. Dans Supabase > Project Settings > API, copier l'URL du projet et la clé publishable.
4. Remplacer les deux valeurs dans config.js.
5. Créer les comptes utilisateurs dans Supabase > Authentication > Users (ou activer une méthode d'inscription adaptée).
6. Publier le contenu de ce dossier dans un nouveau dépôt GitHub.
7. Dans Render, créer un nouveau Static Site connecté au nouveau dépôt. Build Command : laisser vide. Publish Directory : .
8. Activer Realtime pour les tables clients, missions, invoices, payments et expenses dans Supabase > Database > Publications, afin que les changements se synchronisent en direct.
9. Ouvrir le site en HTTPS puis installer l'application depuis le navigateur sur PC et Android.

LIMITES À CONNAÎTRE
- Ce pack est une base applicative, pas une mise en production certifiée. Tester les droits d'accès avec plusieurs comptes avant d'y stocker des données réelles.
- L'invitation et l'administration des collaborateurs, l'export PDF des factures, les sauvegardes automatisées et les tests de sécurité approfondis restent à développer.
- Les données ne sont pas migrées depuis l'ancien Supabase.
- Les comptes utilisateurs se créent dans Supabase Authentication; le premier accès crée automatiquement l'espace de travail.
