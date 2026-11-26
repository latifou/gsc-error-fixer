# gsc-error-fixer

Skill Claude Code qui audite automatiquement un site et son code local pour trouver, puis corriger, les erreurs Google Search Console (indexation, 404, redirections, robots.txt, canonical, données structurées, Core Web Vitals).

## Installation

Globale (tous vos projets) :

    git clone https://github.com/latifou/gsc-error-fixer
    cd gsc-error-fixer && ./install.sh

Dans un seul projet :

    ./install.sh /chemin/vers/mon-projet

## Utilisation

Dans le dossier du site, lancez `claude`, puis tapez par exemple :

    Audite mon site et corrige les erreurs Search Console

Le skill déduit le domaine depuis le code, teste le site en production, lit Search Console si vous êtes connecté dans Chrome (Claude in Chrome), puis propose les corrections.
