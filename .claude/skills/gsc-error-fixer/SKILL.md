---
name: "gsc-error-fixer"
description: "Auditer automatiquement un site et son code local pour trouver puis corriger les erreurs Google Search Console (indexation, 404, redirections, robots.txt, canonical, données structurées, Core Web Vitals), sans que l'utilisateur les précise."
---

# Audit et correction automatiques des erreurs Google Search Console

Répondre en français. Le skill est autonome : l'utilisateur n'a pas à indiquer les erreurs. Il les cherche lui-même, les diagnostique dans le code local, les corrige après accord, puis explique comment valider dans Search Console. Ne poser une question que si une information indispensable est introuvable. Si l'utilisateur fournit déjà une erreur, un CSV ou une capture, l'exploiter en plus de la recherche autonome, sans reposer de questions.

## 0. Trouver le projet et le site (sans demander si possible)
1. Le projet est le répertoire de travail courant (pwd). Vérifier qu'il contient un site web (package.json, next.config.*, astro.config.*, index.html, wp-config.php…). Si c'est un dossier parent contenant plusieurs projets, choisir celui qui correspond ; en cas de doute réel, demander lequel.
2. Déduire le domaine de production depuis le code : variables d'environnement (NEXT_PUBLIC_SITE_URL, SITE_URL…), champ homepage de package.json, siteUrl de next-sitemap/astro/nuxt, balises canonical, CNAME, vercel.json, netlify.toml, URL du sitemap, og:url. Ne demander le domaine que s'il est introuvable.
3. Utiliser les outils natifs de Claude Code (Read, Grep, Glob, Edit, Bash) pour lire, chercher et modifier les fichiers sur place. Ne rien supprimer sans demande explicite.

## 1. Rechercher les erreurs de façon autonome
Lancer ces trois sources en parallèle quand c'est possible.

### A. Audit statique du code local
- Identifier le framework et le mode de rendu (statique, SSR, SPA) : package.json, next.config.*, nuxt.config.*, astro.config.*, vite.config.*, .htaccess, vercel.json, netlify.toml, _redirects, wp-config.php…
- robots.txt (ou app/robots.*) : Disallow trop larges, absence de référence au sitemap, règles de préproduction oubliées.
- Sitemap (sitemap.xml, app/sitemap.*, next-sitemap.config.*) : existe, URL en https et sur le bon domaine, pas de pages noindex, redirigées ou inexistantes.
- Redirections : redirects()/rewrites dans next.config, vercel.json, _redirects, .htaccess, middleware ; boucles, chaînes, www/non-www, http/https, slash final.
- Balises par page : recherche de noindex, robots, canonical, hreflang, og:, viewport, title et meta description (absents, vides, en double), un seul h1.
- noindex ou Disallow liés à NODE_ENV ou à une variable d'environnement : vérifier qu'ils ne s'appliquent pas en production.
- Routes dynamiques qui renvoient 200 pour des contenus inexistants (risque de soft 404) ; page 404 qui renvoie bien le code 404.
- JSON-LD (application/ld+json) : syntaxe valide, champs obligatoires du type (Article, Product, Organization, BreadcrumbList, FAQ…).
- Liens internes : extraire les href internes et les comparer aux routes réellement existantes.
- Performance (Core Web Vitals) : images sans width/height ou non optimisées, scripts bloquants, polices sans font-display, gros bundles.

### B. Crawl du site en production
- Récupérer le sitemap en ligne (curl ou WebFetch), lister ses URL, puis tester chacune avec curl -sIL (code, chaîne de redirections, X-Robots-Tag, Content-Type). Pour plus de 200 URL, échantillonner par type de page (accueil, listes, détails, blog…) et le dire.
- Pour les pages importantes, relever avec WebFetch (ou Firecrawl si disponible) : meta robots, canonical, title, JSON-LD, contenu réellement rendu (page vide ? message d'erreur avec code 200 ?), présence de l'URL dans le sitemap et règles correspondantes dans robots.txt.
- Si le projet peut démarrer (npm run dev ou build), lancer le serveur local, tester les URL avec curl -I, puis comparer avec la production : une différence (déploiement non fait, variable d'environnement, CDN) est souvent la vraie cause.

### C. Lecture directe de Search Console (si accessible)
- Utiliser le navigateur disponible (Claude in Chrome ou navigateur intégré) pour ouvrir Search Console. Si l'utilisateur n'est pas connecté, lui demander de se connecter lui-même ; ne jamais saisir de mot de passe ni de code.
- Lecture seule : relever le rapport Pages (indexation) avec les motifs de non-indexation et leurs URL, Sitemaps, Core Web Vitals, Ergonomie mobile, Données structurées / Résultats enrichis, Actions manuelles et Problèmes de sécurité.
- Si Search Console est inaccessible, continuer avec A et B et le signaler.

## 2. Consolider
Croiser A, B et C, puis produire une liste unique de problèmes triés par impact (pages d'intérêt bloquées en premier). Regrouper par cause racine plutôt que par URL. Pour chaque problème, noter : type, URL concernées, fichier et ligne du code en cause, niveau de certitude. Ne jamais affirmer une cause sans l'avoir observée.

## 3. Diagnostic et correction par type d'erreur

| Erreur GSC | Causes fréquentes | Correction |
|---|---|---|
| 404 introuvable | Page supprimée, lien interne cassé, URL dans le sitemap | Redirection 301 vers l'équivalent, corriger les liens internes, retirer du sitemap |
| Soft 404 | Page quasi vide ou « aucun résultat » renvoyée en 200 | Renvoyer un vrai 404/410 ou enrichir le contenu |
| Erreur de redirection / boucle | Chaîne trop longue, boucle www/non-www, http/https | Une seule redirection 301 directe vers l'URL finale |
| Erreur serveur (5xx) | Crash, timeout, quota, base de données | Lire les logs, corriger l'erreur, vérifier la charge |
| Bloquée par robots.txt | Règle Disallow trop large | Corriger robots.txt (attention aux copies de préproduction) |
| Exclue par la balise noindex | noindex laissé après mise en production | Retirer noindex (meta ou en-tête) |
| Page en double / canonique différente | Canonical absent, mauvais ou pointant ailleurs | Définir un canonical auto-référent correct |
| Explorée, non indexée | Contenu mince, dupliqué, peu de liens internes | Améliorer le contenu, ajouter des liens internes, fusionner les pages proches |
| Détectée, non indexée | Budget d'exploration, site récent, peu de signaux | Liens internes, sitemap propre, patience ; ne pas spammer les demandes d'indexation |
| Données structurées | Champs obligatoires manquants, JSON-LD invalide | Corriger le JSON-LD selon la doc Google, tester avec le test des résultats enrichis |
| Ergonomie mobile / Core Web Vitals | Viewport absent, LCP/CLS/INP mauvais | Viewport correct, images dimensionnées et optimisées, JS différé, polices stables |

Pour les cas non listés, consulter la documentation Google Search Central via Firecrawl avant de conclure.

## 4. Appliquer
- Présenter le rapport consolidé et les diffs proposés, puis appliquer après accord de l'utilisateur. Les corrections évidentes et réversibles (balise manquante, lien cassé) peuvent être groupées dans une seule demande d'accord.
- Modifier directement les fichiers du projet local ; lire un fichier avant de le modifier ; écrire dans le projet, pas dans une copie ; ne rien supprimer.
- Relancer la vérification locale après correction (build, curl en localhost) pour confirmer que le problème a disparu.
- Si le dossier n'est pas accessible malgré la demande, fournir le code ou la configuration exacte à copier (redirections, robots.txt, balises, JSON-LD, sitemap).

## 5. Valider dans Search Console
1. Une fois le correctif déployé, vérifier une URL avec « Inspection d'URL » → « Tester l'URL en direct ».
2. Dans le rapport concerné, cliquer sur « Valider la correction ». Ne cliquer soi-même qu'après confirmation de l'utilisateur ; sinon lui donner la marche à suivre.
3. Prévenir que la validation peut prendre de quelques jours à deux semaines.

## 6. Réponse finale
Résumer en peu de lignes : problèmes trouvés (par ordre d'impact), correctifs appliqués ou proposés, ce qu'il reste à faire côté utilisateur (déploiement, validation GSC). Signaler honnêtement ce qui n'a pas pu être vérifié (Search Console inaccessible, échantillonnage, etc.).

## Règles
- Ne pas inventer de données Search Console : se limiter à ce qui est lu, fourni ou vérifié.
- Pas de modification ni suppression en masse de pages ou de redirections sans confirmation.
- Ne jamais saisir d'identifiants ; l'utilisateur se connecte lui-même.
- Ne pas promettre de délai d'indexation : Google décide.