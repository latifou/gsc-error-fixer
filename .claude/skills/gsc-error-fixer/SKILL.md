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
- robots.txt (ou app/robots.*) : Disallow trop larges, absence de référence au sitemap, règles de préproduction oubliées, CSS/JS bloqués (Google ne peut alors pas rendre la page), directives ignorées par Google (`noindex`, `crawl-delay`) utilisées à tort.
- Sitemap (sitemap.xml, app/sitemap.*, next-sitemap.config.*) : existe, URL absolues en https et sur le bon domaine, uniquement des URL canoniques en 200 (pas de noindex, redirigées ou inexistantes), ≤ 50 000 URL et ≤ 50 Mo non compressé par fichier (sinon index de sitemaps), UTF-8, `lastmod` exact (pas la date du build partout) ; `priority`/`changefreq` sont ignorés.
- Redirections : redirects()/rewrites dans next.config, vercel.json, _redirects, .htaccess, middleware ; boucles, chaînes, www/non-www, http/https, slash final.
- Balises par page : recherche de noindex, robots, canonical, hreflang, og:, viewport, title et meta description (absents, vides, en double), un seul h1.
- Canonical : URL absolue, une seule par page, dans un `<head>` HTML valide, identique dans le HTML initial et après JS, cohérente avec le sitemap, les redirections et le hreflang ; jamais vers une URL en http, redirigée, en noindex ou avec fragment `#`.
- hreflang : chaque version se liste elle-même et liste toutes les autres (liens retour obligatoires, sinon ignorés), URL absolues, codes ISO 639-1 (+ région ISO 3166-1 alpha-2 : `en-GB` et non `en-UK`, pas de `EU`/`es-419`), `x-default` pour le repli.
- Rendu JavaScript (SPA/CSR) : liens en `<a href>` réels (pas de `onClick` seul ni de routage par `#`), routage via History API, title/meta/canonical présents dans le HTML serveur de préférence ; un `noindex` dans le HTML initial empêche le rendu (le retirer en JS ne sert à rien) ; pour une route introuvable côté client, rediriger en JS vers une URL qui renvoie un vrai 404 ou injecter `noindex`.
- noindex ou Disallow liés à NODE_ENV ou à une variable d'environnement : vérifier qu'ils ne s'appliquent pas en production.
- Routes dynamiques qui renvoient 200 pour des contenus inexistants (risque de soft 404) ; page 404 qui renvoie bien le code 404.
- JSON-LD (application/ld+json) : syntaxe valide, champs obligatoires du type (Article, Product, Organization, BreadcrumbList, FAQ…).
- Liens internes : extraire les href internes et les comparer aux routes réellement existantes.
- Performance (Core Web Vitals) : images sans width/height ou non optimisées, scripts bloquants, polices sans font-display, gros bundles.

### B. Crawl du site en production
- Récupérer le sitemap en ligne (curl ou WebFetch), lister ses URL, puis tester chacune avec curl -sIL (code, chaîne de redirections, X-Robots-Tag, Content-Type). Pour plus de 200 URL, échantillonner par type de page (accueil, listes, détails, blog…) et le dire.
- Crawler avec un user-agent de navigateur, pas en imitant Googlebot : les CDN et pare-feu (Hostinger, Cloudflare…) bloquent souvent un faux Googlebot qui ne vient pas d'une IP Google, ce qui donne des 403 trompeurs. Ne jamais conclure à un blocage de Googlebot à partir d'un user-agent imité : le vérifier dans Search Console (Inspection de l'URL → « Récupération de page », ou Statistiques sur l'exploration → état de l'hôte).
- Pour les pages importantes, relever avec WebFetch (ou Firecrawl si disponible) : meta robots, canonical, title, JSON-LD, contenu réellement rendu (page vide ? message d'erreur avec code 200 ?), présence de l'URL dans le sitemap et règles correspondantes dans robots.txt.
- Si le projet peut démarrer (npm run dev ou build), lancer le serveur local, tester les URL avec curl -I, puis comparer avec la production : une différence (déploiement non fait, variable d'environnement, CDN) est souvent la vraie cause.

### C. Lecture directe de Search Console (si accessible)
- Utiliser le navigateur disponible (Claude in Chrome ou navigateur intégré) pour ouvrir Search Console. Si l'utilisateur n'est pas connecté, lui demander de se connecter lui-même ; ne jamais saisir de mot de passe ni de code.
- Lecture seule : relever le rapport Pages (indexation) avec les motifs de non-indexation et leurs URL, Sitemaps, Core Web Vitals, rapports de résultats enrichis (Améliorations), Statistiques sur l'exploration (Paramètres → état de l'hôte : robots.txt, DNS, connectivité serveur), Actions manuelles et Problèmes de sécurité. Le rapport « Ergonomie mobile » et le test d'optimisation mobile n'existent plus depuis décembre 2023 : ne pas les chercher.
- Pour une URL précise, utiliser « Inspection de l'URL » en saisissant l'URL dans la barre de recherche en haut de Search Console (« Inspecter n'importe quelle URL de … ») puis Entrée : une adresse directe construite à la main (`/search-console/inspect?...&id=<url>`) renvoie une erreur 404. Inspecter aussi la canonique choisie par Google via le bouton « Inspecter » de la fiche. On y lit la version indexée (canonique déclarée vs canonique choisie par Google, date d'exploration, robots/noindex détectés) et « Tester l'URL en direct » → « Afficher la page testée » (HTML rendu, capture, en-têtes HTTP, console JS). Le test en direct ne vérifie pas les doublons/canoniques, la présence dans le sitemap, ni les actions manuelles.
- Le rapport Pages ne liste que les 404 vues le mois écoulé, et un problème disparaît du tableau 90 jours après sa dernière occurrence.
- Si Search Console est inaccessible, continuer avec A et B et le signaler.

## 2. Consolider
Croiser A, B et C, puis produire une liste unique de problèmes triés par impact (pages d'intérêt bloquées en premier). Regrouper par cause racine plutôt que par URL. Pour chaque problème, noter : type, URL concernées, fichier et ligne du code en cause, niveau de certitude. Ne jamais affirmer une cause sans l'avoir observée.

## 3. Diagnostic et correction par type d'erreur

Libellés exacts du rapport Pages (FR / EN) et conduite à tenir, d'après l'aide officielle Search Console :

| Motif GSC | Ce que Google dit | Correction |
|---|---|---|
| Erreur serveur (5xx) / Server error | Googlebot n'a pas pu accéder à l'URL (5xx, timeout, site surchargé). Les 5xx et 429 font ralentir l'exploration ; une URL déjà indexée est conservée puis retirée si l'erreur persiste | Logs serveur, charge, requêtes à paramètres trop lentes ; vérifier qu'un pare-feu/anti-DDoS/CDN ne bloque pas Googlebot ; consulter l'état de l'hôte dans Statistiques sur l'exploration |
| Erreur liée à des redirections / Redirect error | Chaîne trop longue (Google suit au plus 10 sauts), boucle, URL finale trop longue, URL vide ou invalide dans la chaîne | Une seule redirection 301/308 directe vers l'URL finale en 200 ; vérifier http→https, www, slash final, middleware |
| Bloquée par le fichier robots.txt / Blocked by robots.txt | La page n'est pas explorée, mais l'URL peut quand même être indexée via des liens | Si la page doit être indexée : retirer la règle. Si elle doit être exclue : retirer le blocage ET mettre `noindex` (Google doit pouvoir explorer pour voir le noindex) |
| Exclue par la balise « noindex » / Excluded by 'noindex' tag | noindex trouvé dans `<meta name="robots">` ou l'en-tête `X-Robots-Tag` | Si voulu : rien à faire. Sinon retirer meta et en-tête (chercher aussi les conditions sur NODE_ENV, CMS, plugin SEO), puis tester en direct et demander l'indexation |
| Soft 404 | Page renvoyée en 200 qui ressemble à une erreur ou est vide : include serveur manquant, base de données injoignable, recherche interne sans résultat, fichier JS non chargé, page sans contenu principal | Contenu disparu : vrai 404/410, ou 301 vers un équivalent réel (pas vers l'accueil). Page légitime : s'assurer qu'elle se rend pour Googlebot (ressources non bloquées, pas de message d'erreur visible) et a un contenu principal |
| Introuvable (404) / Not found (404) | Pas forcément un problème si la page a été supprimée sans remplacement ; Google la réessaiera de moins en moins | Ne corriger que les 404 liées depuis le site ou présentes dans le sitemap ; 301 si la page a déménagé ; corriger les liens internes |
| Bloquée en raison d'une demande non autorisée (401) / d'une interdiction d'accès (403) / d'un autre problème 4xx | Googlebot n'envoie jamais d'identifiants ; 400-411 sont traités comme « contenu inexistant » | Rendre la page publique si elle doit être indexée, ou vérifier que la protection (WAF, géoblocage, auth de préproduction) ne s'applique pas à la production |
| Explorée, actuellement non indexée / Crawled - currently not indexed | Google n'indexe pas tout ; pas forcément une erreur | Seulement pour les pages importantes : contenu unique et substantiel, liens internes, pas de quasi-doublon ; ne pas spammer « Demander une indexation » |
| Détectée, actuellement non indexée / Discovered - currently not indexed | Google voulait explorer mais a reporté pour ne pas surcharger le site (date d'exploration vide) | Temps de réponse serveur, réduire les URL inutiles (filtres, paramètres, facettes), maillage interne vers les pages clés, sitemap propre |
| Autre page avec balise canonique correcte / Alternate page with proper canonical tag | Fonctionnement normal | Rien à faire |
| Page en double sans URL canonique sélectionnée par l'utilisateur / Duplicate without user-selected canonical | Google a choisi une autre URL comme canonique | Déclarer un canonical explicite ; si la page n'est pas un doublon, différencier réellement le contenu ; paramètres de tri/filtre → canonical vers la version propre |
| Page en double : Google n'a pas choisi la même URL canonique que l'utilisateur / Duplicate, Google chose different canonical than user | Google juge que la canonique déclarée n'est pas l'équivalent de la page | Comparer dans Inspection d'URL canonique déclarée vs choisie ; aligner canonical, redirections, liens internes, sitemap et hreflang sur la même URL ; une canonique doit être quasi identique |
| Page avec redirection / Page with redirect | URL non canonique qui redirige : normal, non indexée | Rien à faire, sauf si elle figure dans le sitemap ou les liens internes : les remplacer par l'URL finale |
| Indexée, mais bloquée par robots.txt / Indexed, though blocked by robots.txt | Indexée grâce à des liens externes, sans extrait | Exclure : débloquer + `noindex`. Garder : débloquer |
| Page indexée sans contenu / Page indexed without content | Google n'a pas pu lire le contenu (cloaking ou format non lisible), pas un blocage robots.txt | Inspecter la page rendue ; vérifier que le serveur sert le même contenu à Googlebot qu'aux visiteurs |
| Données structurées (rapports Améliorations) | Une propriété obligatoire manquante rend l'élément inéligible ; un balisage valide ne garantit pas le résultat enrichi | JSON-LD recommandé ; propriétés obligatoires puis recommandées selon la page du type ; ne baliser que du contenu visible ; tester avec le test des résultats enrichis |
| Core Web Vitals | Données terrain CrUX, 75e centile, par groupes d'URL ; pas assez de trafic = pas de données | Bon : LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1 (mauvais : > 4 s, > 500 ms, > 0,25). Images dimensionnées et optimisées, LCP non lazy-loadé, JS différé/scindé, polices stables, réserver l'espace des éléments injectés |

Pour les cas non listés ou douteux, consulter la page officielle correspondante (voir « Référentiel Google » ci-dessous) via WebFetch ou Firecrawl avant de conclure : la documentation Google change régulièrement.

## 4. Appliquer
- Présenter le rapport consolidé et les diffs proposés, puis appliquer après accord de l'utilisateur. Les corrections évidentes et réversibles (balise manquante, lien cassé) peuvent être groupées dans une seule demande d'accord.
- Modifier directement les fichiers du projet local ; lire un fichier avant de le modifier ; écrire dans le projet, pas dans une copie ; ne rien supprimer.
- Relancer la vérification locale après correction (build, curl en localhost) pour confirmer que le problème a disparu.
- Si le dossier n'est pas accessible malgré la demande, fournir le code ou la configuration exacte à copier (redirections, robots.txt, balises, JSON-LD, sitemap).

## 5. Valider dans Search Console
1. Une fois le correctif déployé, vérifier une URL avec « Inspection de l'URL » → « Tester l'URL en direct ». Pour une page importante corrigée, « Demander une indexation » (quota quotidien limité) ; pour beaucoup d'URL, soumettre plutôt le sitemap avec des `lastmod` à jour.
2. Dans le rapport concerné, ouvrir le motif puis cliquer sur « Valider la correction ». Ne cliquer soi-même qu'après confirmation de l'utilisateur ; sinon lui donner la marche à suivre. Ne pas relancer tant que la validation en cours n'est pas terminée (réussie ou échouée). Si le rapport est filtré sur un sitemap, la validation ne porte que sur ses URL.
3. Prévenir : la validation prend généralement jusqu'à environ deux semaines, parfois plus ; pour les Core Web Vitals, la période de suivi est de 28 jours. Une URL devenue inaccessible (404, noindex) compte comme corrigée (état « Autre »). En cas d'échec, « Voir les détails » donne l'URL fautive, puis « Démarrer une nouvelle validation ».

## 6. Réponse finale
Résumer en peu de lignes : problèmes trouvés (par ordre d'impact), correctifs appliqués ou proposés, ce qu'il reste à faire côté utilisateur (déploiement, validation GSC). Signaler honnêtement ce qui n'a pas pu être vérifié (Search Console inaccessible, échantillonnage, etc.).

## Référentiel Google (sources officielles, vérifiées le 26/11/2026)
Faits à appliquer sans les réinventer ; en cas de doute, relire la source.

**Codes HTTP** ([doc](https://developers.google.com/crawling/docs/troubleshooting/http-status-codes))
- 200 : contenu traité ; s'il ressemble à une erreur → soft 404. 204 : aucun contenu.
- 301/308 : signal fort que la cible est canonique. 302/307/303 : signal faible (la source reste affichée). Meta refresh à 0 s = permanent, > 0 s = temporaire ; les redirections JS sont suivies mais moins fiables qu'une 301 serveur. Google suit au plus 10 sauts.
- 400, 401, 403, 404, 410, 411 : traités pareil (contenu inexistant, retiré de l'index, exploration réduite). 429 et 5xx : surcharge, exploration ralentie, URL indexées conservées un temps puis retirées.

**robots.txt** ([doc](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec))
- Valable uniquement pour le protocole, l'hôte et le port où il est servi (http/https et www/non-www sont distincts). Taille max 500 Kio ; mis en cache jusqu'à 24 h.
- Directives prises en charge : `user-agent`, `allow`, `disallow`, `sitemap` ; `noindex` et `crawl-delay` sont ignorés. Jokers `*` et `$`. La règle la plus longue l'emporte ; à égalité, la moins restrictive.
- Réponse 4xx (sauf 429) = aucune restriction. 5xx ou erreur réseau : exploration arrêtée 12 h, puis dernière version valide pendant 30 jours. Redirections suivies jusqu'à 5 sauts.
- Une URL bloquée peut être indexée sans contenu ; pour désindexer, utiliser `noindex` sur une page explorable.

**noindex** ([doc](https://developers.google.com/search/docs/crawling-indexing/block-indexing)) : `<meta name="robots" content="noindex">` dans le `<head>` ou en-tête `X-Robots-Tag: noindex` (seule option pour PDF/images). Inefficace si l'URL est bloquée par robots.txt.

**Canonical** ([doc](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)) : signaux du plus fort au plus faible : redirection, `rel="canonical"`, sitemap. Ne pas canonicaliser via robots.txt, noindex ou l'outil de suppression d'URL. Ne pas mélanger balise HTML et en-tête `Link`. Certificat TLS invalide ou redirection https→http fait préférer http. Les paramètres de tri/filtre sont la première cause de doublons massifs.

**Redirections** ([doc](https://developers.google.com/search/docs/crawling-indexing/301-redirects)) : 301/308 pour un déménagement définitif, 302/307 seulement si temporaire.

**Sitemaps** ([doc](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)) : 50 000 URL / 50 Mo non compressé par fichier, UTF-8, URL absolues canoniques ; `lastmod` utilisé seulement s'il est exact ; `priority` et `changefreq` ignorés. Soumission via le rapport Sitemaps, l'API ou une ligne `Sitemap:` dans robots.txt. Un sitemap non soumis ne couvre que son dossier et ses sous-dossiers.

**JavaScript** ([doc](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics)) : les pages en 200 sont rendues plus tard (file de rendu) ; liens découverts uniquement via `<a href>` ; pas de routage par fragment ; Googlebot met en cache agressivement → empreintes dans les noms de fichiers (`main.2bb85551.js`).

**hreflang** ([doc](https://developers.google.com/search/docs/specialty/international/localized-versions)) : via HTML, en-tête HTTP ou sitemap ; liens réciproques obligatoires ; canonical dans la même langue.

**Données structurées** ([règles générales](https://developers.google.com/search/docs/appearance/structured-data/sd-policies), [types pris en charge](https://developers.google.com/search/docs/appearance/structured-data/search-gallery)) :
- Types encore pris en charge : Article, Breadcrumb, Carousel, Course list, Dataset, Discussion forum, Education Q&A, Employer aggregate rating, Event, Image metadata, Job posting, Local business, Math solver, Movie, Organization, Product, Profile page, Q&A, Recipe, Review snippet, Software app, Speakable, Paywalled content, Vacation rental, Video.
- Retirés : HowTo (2023) ; Book actions, Course info, Claim review, Estimated salary, Learning video, Special announcement, Vehicle listing (2025) ; Practice problem (janvier 2026) ; FAQ (rich result abandonné en mai 2026). Leur présence n'est pas une erreur et ne nuit pas, mais ne rien promettre en résultats enrichis et ne pas en ajouter pour Google.
- Spam de données structurées (contenu invisible, faux avis) → action manuelle qui retire l'éligibilité aux résultats enrichis.

**Aide Search Console** : [rapport Pages](https://support.google.com/webmasters/answer/7440203), [Inspection de l'URL](https://support.google.com/webmasters/answer/9012289), [Core Web Vitals](https://support.google.com/webmasters/answer/9205520), [dépannage de l'exploration](https://developers.google.com/search/docs/crawling-indexing/troubleshoot-crawling-errors), [journal des changements](https://developers.google.com/search/updates) (à consulter si un comportement semble différent).

## Règles
- Ne pas inventer de données Search Console : se limiter à ce qui est lu, fourni ou vérifié.
- Pas de modification ni suppression en masse de pages ou de redirections sans confirmation.
- Ne jamais saisir d'identifiants ; l'utilisateur se connecte lui-même.
- Ne pas promettre de délai d'indexation ni d'indexation complète : Google n'indexe pas toutes les pages, et une indexation prend en général un à deux jours, parfois une à deux semaines.
- Pour un site de moins de 500 pages, Google indique que le rapport Pages est souvent superflu : vérifier d'abord les pages clés avec `site:` et l'Inspection de l'URL.