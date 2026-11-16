# Audit sécurité et qualité — alexbelgium/hassio-addons

- **Date :** 2026-11-15
- **Commit audité :** `e7871d4041` (branche `fable-security-audit`, à jour avec `master`)
- **Nature :** audit en lecture seule. Aucune correction n'a été appliquée, aucun fichier du dépôt n'a été modifié hormis l'ajout de ce rapport.
- **Périmètre :** 141 répertoires d'add-ons (130 actifs, 11 `zzz_archived_*`), `.templates/` (25 fichiers), `.github/workflows/` (20 fichiers), `.github/scripts/`.

---

## 1. Résumé exécutif

Le dépôt est globalement soigné sur ses parties récentes (builder CI à permissions minimales, `00-global_var.sh` avec auto-test, `claude_desktop` avec vérification de checksums). Les risques réels se concentrent sur **trois familles** :

1. **Des réglages par défaut qui exposent des applications sans authentification sur le réseau local.** Plusieurs add-ons publient leur port sur l'hôte *et* désactivent l'authentification par défaut. Le cas le plus grave concerne les gestionnaires de fichiers, qui montent la configuration Home Assistant, les sauvegardes et les clés TLS en écriture.
2. **Une chaîne d'approvisionnement ouverte à des tiers.** Les images `birdnet-pi` et `birdnet-go-dev` fusionnent au build toutes les pull requests ouvertes d'un dépôt public, sans filtre d'auteur. L'add-on `addons_updater` pousse avec un jeton GitHub après avoir désactivé la vérification TLS.
3. **Des secrets diffusés trop largement.** Le module partagé `00-global_var.sh` recopie toutes les options, mots de passe compris, dans des fichiers lisibles par tous et dans chaque script de service. C'est la même classe de défaut que celui corrigé sur `claude_desktop`, à l'échelle du dépôt.

| Sévérité | Nombre | Thèmes |
|---|---|---|
| Critique | 2 | Gestionnaires de fichiers sans authentification ; fusion automatique de PR tierces au build |
| Haute | 8 | Authentification désactivée par défaut, mot de passe Portainer par défaut, jeton GitHub exposé, panneaux visibles aux non-administrateurs, secrets par défaut partagés |
| Moyenne | 14 | Ingress sans filtrage d'IP, secrets dans les logs et l'environnement, téléchargements non vérifiés, workflows CI, perte de données Jellyfin |
| Basse | 11 | Bugs de robustesse, code mort, duplication, dépendances obsolètes |

**Les cinq actions les plus rentables**

1. Passer `NoAuth`, `auth_method` et `connection_mode` à une valeur authentifiée par défaut, ou ne plus publier le port direct par défaut (C1, H1, H2, H4).
2. Supprimer la fusion automatique de PR des builds publiés, ou la restreindre à une liste d'auteurs (C2).
3. Retirer `http.sslVerify false` de `addons_updater` et sortir le jeton de l'URL du dépôt distant (H5).
4. Ajouter `allow 172.30.32.2; deny all;` dans un include nginx partagé (M1).
5. Épingler par SHA les actions tierces et retirer les références `@main` des workflows disposant d'un jeton en écriture (M7).

**Second avis Codex.** Les dix constats critiques et hauts ont été soumis à Codex en CLI, avec lecture directe des fichiers. Codex en confirme sept sans réserve et nuance les autres ; ses réserves sont reportées dans chaque constat et résumées en section 7.

---

## 2. Méthode et limites

- Lecture intégrale de `.templates/` et des workflows actifs ; analyse programmatique des 141 `config.yaml` (ports, privilèges, cartes de volumes, options par défaut) ; recherches ciblées sur tous les Dockerfiles et scripts ; lecture des scripts des add-ons les plus exposés.
- Trois agents d'exploration ont balayé les scripts de tous les add-ons. Leurs constats cités ici ont été revérifiés ligne par ligne, sauf ceux marqués **(†)**, vérifiés seulement par sondage.
- État des workflows relevé via l'API GitHub (`active` ou `disabled_manually`).

**Ce qui n'a pas pu être vérifié**

- Le comportement par défaut des images amont (authentification de Cloud Commander, de l'interface web LinuxServer, `pg_hba.conf` de PostgreSQL). Les constats qui en dépendent le signalent.
- Les permissions par défaut du `GITHUB_TOKEN` et la protection de branche de `master` : l'API a refusé la lecture. Les commits de bots observés dans l'historique montrent toutefois que le jeton par défaut écrit sur `master`.
- Aucun test dynamique : rien n'a été construit ni exécuté.

---

## 3. Sévérité critique

### C1 — Gestionnaires de fichiers sans authentification, publiés sur le réseau, avec la configuration Home Assistant en écriture

**Axe :** sécurité. **Add-ons :** `filebrowser`, `filebrowser_quantum`, `cloudcommander`.

| Add-on | Défaut | Port publié | Preuve |
|---|---|---|---|
| filebrowser | `NoAuth: true` puis `--noauth`, racine `/` | 8071 | `filebrowser/config.yaml:95`, `:103` ; `filebrowser/rootfs/etc/cont-init.d/99-run.sh:79-86`, `:126` |
| filebrowser_quantum | `auth_method: noauth`, portée `/` | 8071 | `filebrowser_quantum/config.yaml:95`, `:100` ; `rootfs/etc/cont-init.d/99-run.sh:146-150` ; `rootfs/etc/nginx/servers/direct.conf:10` |
| cloudcommander | lancé sans option d'authentification | 8000 | `cloudcommander/config.yaml:71-86` ; `rootfs/etc/cont-init.d/99-run.sh:117` |

Les trois montent en lecture-écriture `homeassistant_config`, `backup`, `ssl`, `addons` et `all_app_configs` (`filebrowser/config.yaml:83-91`).

**Risque.** Toute machine du réseau local lit et modifie `secrets.yaml`, `.storage/auth` (jetons de session), les sauvegardes et les clés privées TLS, sans identifiant. L'écriture dans la configuration Home Assistant donne l'exécution de code dans Home Assistant (`custom_components`, `shell_command`). Cloud Commander ajoute une console intégrée, en root avec `SYS_ADMIN`.

**Réserves.** Pour Cloud Commander, l'absence d'authentification repose sur le défaut de l'image amont `coderaiser/cloudcmd:latest`, non vérifiable localement. Les sauvegardes chiffrées ne livrent pas leur contenu en clair. Le README de `filebrowser_quantum` annonce `password` comme défaut (`README.md:61`), en contradiction avec la configuration livrée.

**Correction suggérée.** Authentification activée par défaut (`NoAuth: false`, `auth_method: password`, `--auth` pour cloudcmd). À défaut, port direct à `null` par défaut : l'accès par Ingress reste protégé par Home Assistant. Refuser de démarrer en mode sans authentification quand le port direct est publié.

### C2 — Les images `birdnet-pi` et `birdnet-go-dev` embarquent toutes les PR ouvertes de dépôts publics, sans filtre d'auteur

**Axe :** sécurité, chaîne d'approvisionnement.

- `birdnet-pi/Dockerfile:97` injecte `merge_open_prs.sh` dans l'installeur amont.
- `birdnet-pi/rootfs/helpers/merge_open_prs.sh:21-22` liste les PR ouvertes non brouillon de `alexbelgium/BirdNET-Pi` ; `:41-44` récupère `refs/pull/N/head` et fusionne. Aucun contrôle d'auteur ni d'approbation.
- `birdnet-go-dev/merge-prs.sh:159-175` fait de même pour `alexbelgium/birdnet-go`, puis `birdnet-go-dev/Dockerfile:43-46` compile le résultat.

**Risque.** N'importe quel compte GitHub peut ouvrir une PR sur ces dépôts publics. Son code est alors exécuté au build suivant puis livré dans l'image publiée sur `ghcr.io`, installée par les utilisateurs. Aujourd'hui, toutes les PR ouvertes sont signées du mainteneur, mais deux d'entre elles ont pour source le fork d'un tiers (`7h30th3r0n3/BirdNET-Pi`, `twinvega/BirdNET-Pi`) : le propriétaire du fork peut y pousser de nouveaux commits, qui seront fusionnés sans relecture.

**Réserves (Codex).** Ouvrir une PR ne déclenche pas le build ; il faut une reconstruction de l'add-on. Un conflit de fusion ou un échec de compilation bloque la publication. `birdnet-go-dev` est explicitement une version de développement.

**Correction suggérée.** Construire à partir d'un commit relu et épinglé. Si la fusion de PR est conservée pour `birdnet-go-dev`, filtrer sur `.user.login` *et* `.head.repo.full_name` appartenant au mainteneur, et retirer ce mécanisme de `birdnet-pi`.

---

## 4. Sévérité haute

### H1 — Les add-ons *arr désactivent l'authentification par défaut alors que leur port reste publié

**Axe :** sécurité. **Add-ons :** `sonarr`, `radarr`, `prowlarr`, `readarr`, `bazarr`.

Le défaut `connection_mode: ingress_noauth` (`sonarr/config.yaml:87`) écrit `AuthenticationMethod=external` (`sonarr/rootfs/etc/cont-init.d/32-nginx_ingress.sh:42-46`). Le port direct reste publié (`sonarr/config.yaml:91`, 8989 ; 7878, 9696, 8787, 6767 pour les autres). Bazarr met `auth.type` à null (`bazarr/rootfs/etc/cont-init.d/32-nginx_ingress.sh:35-44`).

**Risque.** Interface d'administration sans mot de passe sur le réseau local. Ces applications savent lancer des scripts personnalisés, donc exécuter du code dans un conteneur root doté de `SYS_ADMIN`. Le script se contente d'un avertissement dans les logs (`:37`).

**Réserves (Codex).** La modification ne s'applique que si `config.xml` existe, donc pas au premier démarrage. Pour Readarr, `readarr/rootfs/etc/services.d/nginx/run:14-18` supprime ensuite les lignes `external` : l'état final n'y est pas établi.

**Correction suggérée.** Défaut `ingress_auth`. En mode `ingress_noauth`, lier l'application à `127.0.0.1` pour que seul nginx l'atteigne.

### H2 — qBittorrent et Transmission acceptent le réseau local sans mot de passe par défaut

**Axe :** sécurité.

- `qbittorrent/config.yaml:92` : `whitelist: localhost,127.0.0.1,172.30.0.0/16,192.168.0.0/16`. Le script active `AuthSubnetWhitelistEnabled=true` pour ces plages (`qbittorrent/rootfs/etc/cont-init.d/91-qbittorrent_configuration.sh:137-139`). Port 8081 publié (`config.yaml:101`). Les protections CSRF, clickjacking et de validation d'en-tête Host sont désactivées (`:79-82`).
- `transmission/rootfs/etc/cont-init.d/01-config.sh:109-116` : sans option `user`, `rpc-authentication-required=false`. Port 9091 publié (`transmission/config.yaml:96`).

**Risque.** Tout appareil d'un réseau en `192.168.x.x` administre le client torrent sans identifiant. Les deux clients peuvent lancer un programme en fin de téléchargement, donc exécuter du code. Avec la protection CSRF coupée, une page web visitée depuis le réseau local suffit.

**Correction suggérée.** Liste blanche limitée à `127.0.0.1` et à l'adresse d'Ingress `172.30.32.2`. Mot de passe obligatoire pour Transmission dès que le port est publié.

### H3 — Portainer : mot de passe administrateur par défaut connu, avec accès à l'API Docker

**Axe :** sécurité. **Add-ons :** `portainer`, `portainer_be`.

`portainer/config.yaml:8` (`docker_api: true`) et `:24` (`password: homeassistant`) ; mot de passe transmis par `--admin-password-file` (`portainer/rootfs/etc/services.d/portainer/run:53`, `:78`). Le port est publié par défaut (hôte 9000 vers nginx 9099, `rootfs/etc/nginx/templates/ingress.gtpl:2-15`).

**Risque.** Le compte `admin` / `homeassistant` donne le contrôle du démon Docker, donc de l'hôte. Seul garde-fou : l'add-on exige la désactivation du mode protégé (`31-portainer.sh:8`).

**Compléments (Codex).** Changer l'option déplace la base dans `/share` et stocke le mot de passe en clair dans `/data/portainer_password` (`run:62-72`).

**Correction suggérée.** Aucun mot de passe par défaut : laisser l'écran d'initialisation de Portainer, ou générer un secret aléatoire au premier démarrage. Port direct à `null` par défaut.

### H4 — Bureaux web publiés sans mot de passe par défaut

**Axe :** sécurité. **Add-ons :** `browser_chromium` (3000, 3001), `browser_brave` (3001), `calibre` (8181).

Ports publiés et `PUID: 0` avec `SYS_ADMIN` (`browser_chromium/config.yaml:34-62`, `calibre/config.yaml:85-108`). L'option `PASSWORD` est vide par défaut. Le script n'émet qu'un avertissement (`browser_chromium/rootfs/etc/cont-init.d/80-configuration.sh:39-49`), et la copie de Calibre n'en émet aucun (`calibre/rootfs/etc/cont-init.d/80-configuration.sh:48-54`). L'avertissement de Brave exige les ports 3000 *et* 3001, alors que seul 3001 est publié (`browser_brave/.../80-configuration.sh:45`).

**Risque.** Session de bureau root accessible depuis le réseau local, avec `/share`, `/media` et, pour Calibre, la configuration Home Assistant en écriture.

**Réserve.** L'absence d'authentification web dépend des images LinuxServer amont, non vérifiable localement. Par ailleurs, `passwd abc` règle le mot de passe Unix, pas celui de l'interface web.

**Correction suggérée.** Ports à `null` par défaut. Refuser le démarrage si un port direct est publié sans `PASSWORD`.

### H5 — `addons_updater` : vérification TLS désactivée et jeton GitHub dans l'URL du dépôt distant

**Axe :** sécurité.

- `addons_updater/rootfs/etc/cont-init.d/99-run.sh:57` : `git config --system http.sslVerify false`.
- `:511` : `git remote set-url origin "https://${GITUSER}:${GITHUB_API_TOKEN}@github.com/..."`, persistant dans `/data/<repo>/.git/config`.
- `addons_updater/config.yaml:25` : `gitapi: str`, donc affiché en clair dans l'interface. La clé `gitapi` échappe aussi au masquage des logs de `.templates/00-global_var.sh:264`.

**Risque.** Ce jeton écrit sur `master`, d'où partent les builds de toutes les images. Un attaquant en position d'interception réseau le capture au premier `git push`. Le vol de ce jeton compromet toute la chaîne de publication.

**Correction suggérée.** Supprimer la ligne 57. Passer le jeton par un `credential.helper` en mémoire ou par `http.extraheader` plutôt que par l'URL. Typer `gitapi: password`. Révoquer et régénérer le jeton actuel.

### H6 — `panel_admin: false` sur des add-ons dont l'interface donne des droits d'administration

**Axe :** sécurité.

`cloudcommander/config.yaml:83`, `filebrowser_quantum/config.yaml:97`, `webtop/config.yaml:92`, `calibre/config.yaml:89`, `claude_desktop/config.yaml:122`, `portainer/config.yaml:26`, ainsi que `webtop_kde`, `browser_*`, `codex`, `comixed`.

**Risque.** Un utilisateur Home Assistant non administrateur voit le panneau et entre par Ingress. Chemins d'élévation démontrés : `filebrowser_quantum` et `calibre` (configuration Home Assistant en écriture), `claude_desktop` (`hassio_role: manager` et jeton Supervisor utilisé par `ha-cli`, `claude_desktop/config.yaml:74-77`). Pour `webtop` et les navigateurs, qui ne montent pas la configuration Home Assistant, l'élévation n'est pas établie.

**Correction suggérée.** Retirer `panel_admin: false` (le défaut est `true`) sur tous les add-ons qui montent `homeassistant_config`, disposent d'un rôle Supervisor ou offrent un shell.

### H7 — PostgreSQL : mot de passe par défaut, port publié, rôle Supervisor `manager`

**Axe :** sécurité. **Add-ons :** `postgres_15`, `postgres_17`.

`postgres_17/config.yaml:20` (`POSTGRES_PASSWORD: homeassistant`), `:22` (5432 publié), `:10` (`hassio_role: manager`), carte `homeassistant_config:rw`. `listen_addresses='*'` (`postgres_17/Dockerfile:34`).

**Risque.** Le super-utilisateur PostgreSQL au mot de passe connu peut exécuter des commandes (`COPY ... FROM PROGRAM`) dans un conteneur qui détient un jeton Supervisor de rôle `manager` et la configuration Home Assistant en écriture. Le rôle `manager` ne sert qu'à redémarrer les add-ons Immich (`postgres_15/rootfs/etc/cont-init.d/99-run.sh:124-142`).

**Réserve.** `pg_hba.conf` vient de l'image amont, non vérifié.

**Correction suggérée.** Mot de passe généré au premier démarrage. Port à `null` par défaut : les add-ons clients passent par le réseau interne. Remplacer le rôle `manager` par un redémarrage déclenché côté Immich.

### H8 — Secrets cryptographiques par défaut, identiques pour toutes les installations

**Axe :** sécurité.

| Add-on | Secret | Preuve |
|---|---|---|
| openproject | `OPENPROJECT_SECRET_KEY_BASE=addon_secret` | `openproject/config.yaml:9`, `openproject/Dockerfile:30` |
| fireflyiii | `APP_KEY: CHANGEME_32_CHARS_EuC5dfn3LAPzeO` | `fireflyiii/config.yaml:77` |
| tandoor_recipes | `SECRET_KEY: YOUR_SECRET_KEY` | `tandoor_recipes/config.yaml:84` |
| immich (4 variantes) | `JWT_SECRET` fixe, `DB_PASSWORD: homeassistant` | `immich/config.yaml:99`, `:103` |
| seafile | `SEAFILE_ADMIN_PASSWORD: a_very_secret_password` | `seafile/config.yaml:87` |
| flexget | `WebuiPass: homeassistant123` | `flexget/config.yaml:81` |
| linkwarden | mot de passe `postgres` codé en dur | `linkwarden/rootfs/etc/cont-init.d/99-run.sh:76` |
| elasticsearch | sécurité désactivée, `host_network` | `elasticsearch/rootfs/usr/local/bin/addon-init.sh:70-73`, `config.yaml:72` |

**Risque.** Une clé de signature de session connue permet de forger des sessions (Rails, Laravel, Django). Les mots de passe par défaut ouvrent l'administration sur un port publié. Elasticsearch expose ses données sans authentification sur l'interface de l'hôte. `fireflyiii` vérifie la longueur de la clé mais pas qu'elle a été changée (`99-run.sh:14-16`).

**Correction suggérée.** Générer chaque secret au premier démarrage et le stocker dans `/data` ; refuser de démarrer sur la valeur d'exemple. `joal` détecte déjà son jeton par défaut (`joal/rootfs/etc/cont-init.d/99-run.sh:15`) : généraliser ce modèle.

---

## 5. Sévérité moyenne

### M1 — 43 add-ons : serveur nginx d'Ingress sans restriction à `172.30.32.2`

**Axe :** sécurité. Exemples : `sonarr/rootfs/etc/nginx/servers/ingress.conf:2-14`, `cloudcommander/rootfs/etc/nginx/servers/ingress.conf:2-14`. Les includes ne contiennent aucune règle `allow`/`deny`. À l'inverse, `calibre_web/.../ingress.conf:8-9` et `mealie` l'appliquent.

**Risque.** Tout conteneur du réseau `hassio` atteint le port d'Ingress en contournant l'authentification Home Assistant. Combiné à H1, l'application derrière n'a plus aucune protection. Codex compte 45 fichiers sur 43 add-ons et juge la sévérité moyenne en général, haute pour les applications sans authentification.

**Correction suggérée.** Ajouter `allow 172.30.32.2; deny all;` dans `server_params.conf`, fichier déjà dupliqué à l'identique dans 30 add-ons.

### M2 — `00-global_var.sh` diffuse toutes les options, secrets compris (même classe que le bug `claude_desktop`)

**Axe :** sécurité. `.templates/00-global_var.sh`.

- `:350-352` écrit `/.env` et `/etc/environment` avec les permissions par défaut, lisibles par tous.
- `:359-366` injecte le bloc d'exports dans chaque script `run`, chaque script cont-init, `/etc/bash.bashrc` et `$HOME/.bashrc`.
- `:264` masque les logs sur le seul nom de clé : `gitapi`, `DATABASE_URL` ou un `env_vars` au nom neutre sortent en clair.
- `resolve_secret` (`:202-213`) conserve les guillemets YAML de la valeur et utilise le nom du secret comme expression régulière awk non échappée.

**Cas analogues au correctif `claude_desktop`.**

- **Secrets persistés dans des volumes partagés.** Quand `HOME` est un volume persistant, le bloc est écrit dans un `.bashrc` sauvegardé et partagé : `webtop` (`HOME: /share/webtop_kde`, `webtop/config.yaml:70`) dépose `PASSWORD` et `cifspassword` en clair dans `/share`, monté par des dizaines d'add-ons et souvent exporté en Samba. Même schéma sous `/config` pour `calibre`, `calibre_web`, `browser_*`, `signalk`.
- **Ancien schéma non corrigé.** `calibre/rootfs/etc/cont-init.d/20-folders.sh:55-61` et `calibre_web/rootfs/etc/cont-init.d/00-data_location.sh:40-43` ajoutent `HOME=` à `~/.bashrc` à chaque démarrage, sans marqueur ni nettoyage du bloc périmé. `webtop`, `webtop_kde` et `joplin_desktop` ont reçu le correctif. Dans `calibre_web`, l'option `data_location` lue par le script n'est pas déclarée au schéma.

**Réserve (Codex).** Sévérité moyenne en base, haute seulement si une frontière de privilège est franchie (conteneur à utilisateur non root, volume partagé).

**Correction suggérée.**

- `/.env` : créer le fichier temporaire avec `mktemp` (mode 600 dès la création) au lieu de `"$ENV_FILE.tmp"`. Une redirection vers un `/.env.tmp` laissé par une exécution interrompue réutilise son mode, que ni `umask 077` ni `mv` ne corrigent. Le module ne fixe aucun `umask` aujourd'hui.
- `/etc/environment` est écrit par `cp` (`:352`), qui conserve le mode d'un fichier existant : ajouter un `chmod 600 /etc/environment` explicite après la copie.
- Scripts injectés : la boucle de `:359` écrit le bloc complet dans les scripts `run` de `services.d` et de s6-overlay, les `cont-init.d/*.sh`, `/entrypoint.sh`, `/etc/bash.bashrc` et `$HOME/.bashrc`. `inject_block` réécrit chaque fichier avec `cat "$tmp" > "$f"`, qui garde son mode, souvent 755. Ni `umask` ni `chmod` sur les deux fichiers ci-dessus ne protègent ces copies. Ne plus injecter les clés reconnues comme secrètes dans ces fichiers et les fournir par un mécanisme limité au service qui en a besoin (fichier 600 lu au lancement, `s6-envdir` en 700). Retirer les blocs déjà écrits dans les fichiers qui persistent entre redémarrages, notamment les `.bashrc` situés dans un volume. Ne jamais écrire le bloc dans un `HOME` situé sous `/share`. Liste explicite de clés sensibles en complément du motif.

### M3 — Secrets écrits en clair dans les logs de l'add-on

**Axe :** sécurité.

- `tandoor_recipes/rootfs/etc/cont-init.d/99-run.sh:11`, `:14`, `:98` (`SECRET_KEY`, `AI_API_KEY`, `POSTGRES_PASSWORD`)
- `transmission/rootfs/etc/cont-init.d/01-config.sh:111` (utilisateur et mot de passe RPC)
- `transmission_openvpn/rootfs/etc/cont-init.d/99-run.sh:9-10` (toutes les options, dont `OPENVPN_PASSWORD`)
- `monica/rootfs/etc/cont-init.d/99-run.sh:63`, `nextcloud/rootfs/etc/cont-init.d/02-mariadb_discovery.sh:14`, `webtrees/rootfs/etc/scripts/launcher.sh:13` (mot de passe MariaDB du service partagé)
- `birdnet-go/rootfs/etc/cont-init.d/33-mqtt.sh:33`, `enedisgateway2mqtt/rootfs/etc/cont-init.d/91-mqtt_autodiscover.sh:26` (mot de passe MQTT)
- `joal/rootfs/etc/cont-init.d/99-run.sh:118`, `photoprism/rootfs/etc/services.d/photoprism/run:57`, `obsidian_syncserver_npm/run.sh:81`

**Risque.** Les logs sont lisibles dans l'interface, inclus dans les diagnostics et régulièrement collés dans des tickets publics.

**Correction suggérée.** Masquer systématiquement, sur le modèle de `immich/rootfs/etc/cont-init.d/99-run.sh:17`.

### M4 — `transmission_openvpn` : environnement complet dans un fichier lisible par tous

**Axe :** sécurité. `transmission_openvpn/rootfs/etc/cont-init.d/99-run.sh:173-177` : `export -p > /env.sh` puis `chmod 755`. Le fichier contient `OPENVPN_PASSWORD` et `SUPERVISOR_TOKEN`. Actif seulement avec `auto_restart: true`.

**Correction suggérée.** N'exporter que les variables nécessaires au redémarrage, en `chmod 600`.

### M5 — Téléchargements exécutés au démarrage du conteneur, sans vérification

**Axe :** sécurité, chaîne d'approvisionnement.

- `claude_desktop/rootfs/etc/cont-init.d/82-claude_tools.sh:799` : `curl .../JuliusBrussee/caveman/main/install.sh | bash`, dans un conteneur de rôle `manager`. Option `install_caveman` désactivée par défaut.
- `joal/rootfs/etc/cont-init.d/99-run.sh:22` : dernière release téléchargée et exécutée à chaque démarrage.
- `qbittorrent/rootfs/etc/cont-init.d/91-qbittorrent_configuration.sh:204-205` : `vuetorrent.zip` en `/latest`, décompressé dans `/`.
- `webtop_kde/rootfs/etc/cont-init.d/81-microsoft_edge.sh:51` : paquet `.deb` installé en root sans signature.
- `postgres_15/rootfs/etc/cont-init.d/99-run.sh:63`, `:71` : `.deb` dont la bibliothèque est chargée dans PostgreSQL.
- `.templates/01-custom_script.sh:192-193` : modèle de script téléchargé depuis `master`, exécuté aux démarrages suivants.

**Correction suggérée.** Installer au build, avec version épinglée et `sha256sum -c`, comme le fait déjà `claude_desktop/Dockerfile:186-193`.

### M6 — Téléchargements de build non vérifiés et références mouvantes

**Axe :** sécurité, chaîne d'approvisionnement.

- Sur 40 téléchargements `curl`/`wget` dans les Dockerfiles, seuls `claude_desktop`, `scrutiny` et `scrutiny_fa` vérifient une somme de contrôle.
- Installeurs passés directement à un shell : `birdnet-go-dev/Dockerfile:107`, `:112` ; `ente/Dockerfile:29`.
- Code tiré de branches `master`/`main` : `binance-trading-bot/Dockerfile:40-43`, `birdnet-pi/Dockerfile:51`, `:56`, `:74`, `qbittorrent/Dockerfile:75`, `portainer_agent/Dockerfile:32`.
- `.templates/ha_automodules.sh:34` et `.templates/ha_autoapps.sh:78` téléchargent les modules depuis `master` au build : une PR modifiant `.templates/` n'est donc jamais testée par son propre build, et `ha_autoapps.sh:80` passe la liste par `eval`.
- 176 références d'image de base sur 258 utilisent une étiquette mouvante (`latest`, `nightly`, `stable`), aucune n'est épinglée par digest, et `cosign` est désactivé (`.github/workflows/onpush_builder.yaml:328`). Le choix de `:latest` est une convention assumée du dépôt ; sa contrepartie est qu'une version publiée ne correspond pas à un contenu reproductible.

**Correction suggérée.** Somme de contrôle sur chaque binaire téléchargé. Copier les modules depuis le checkout plutôt que depuis `master`. Envisager l'épinglage par digest avec mise à jour par `addons_updater`.

### M7 — CI : actions à référence mouvante exécutées avec un jeton en écriture

**Axe :** CI/CD.

- `.github/workflows/lint.yml:12-14` demande `contents: write` et `pull-requests: write` pour tout le workflow, puis exécute `super-linter/super-linter/slim@main` avec le jeton (`:50-53`, `:99-102`).
- `.github/workflows/weekly_reduceimagesize.yml:21-25` : `calibreapp/image-actions@main` avec le jeton.
- Les actions tierces sont épinglées par étiquette, pas par SHA : `EndBug/add-and-commit@v11.1.1`, `ymwymw/check-mixed-line-endings@v2`, `frenck/action-addon-linter@v2`, `erclu/check-crlf@v1`, `peter-evans/create-pull-request@v8`. Seul `on_claude_mention.yml` épingle par SHA.
- Aucun bloc `permissions:` dans `on_issues.yml`, `daily_README.yaml`, `weekly_stats.yaml`, `helper_stats_graphs.yaml`, `weekly_crlftolf.yaml`, `generate_stargazer_map.yml`, `onpr_check-pr.yaml`, `weekly_reduceimagesize.yml`.

**Risque.** La compromission d'une de ces actions donne l'écriture sur `master`, donc sur les images publiées. Le builder montre la bonne pratique (`onpush_builder.yaml:14-15`).

**Correction suggérée.** Épingler par SHA (Dependabot est déjà configuré pour suivre). `permissions: contents: read` au niveau du workflow, écriture accordée job par job.

### M8 — CI : `on_issues.yml` pousse en force sur `master` à partir de contenu non fiable

**Axe :** CI/CD. `.github/workflows/on_issues.yml`.

- Déclenché par tout ticket ouvert, modifié ou fermé (`:5-8`), sans condition sur le propriétaire du dépôt.
- `:38-39` récupère les titres et ne retire que `<>$'"` ; `:51-53` les insère par `sed` dans les README. Les modèles de ticket posent automatiquement les étiquettes `bug` ou `enhancement` : tout utilisateur peut injecter un lien Markdown dans un README de `master`.
- `:67-68` : `push: --force`. Un commit arrivé sur `master` entre le checkout et le push est écrasé, par exemple un commit du bot de mise à jour.
- `:25` exige `config.json`, que seul `zzz_archived_tor` possède : le workflow est quasiment mort mais tourne à chaque événement. `:31-38` saute le premier ticket, et une seule page de l'API est lue.
- `.github/workflows/generate_stargazer_map.yml:21`, `:35` : `pip install` de paquets non épinglés puis `git push --force`.

**Correction suggérée.** Supprimer `on_issues.yml`, ou le réécrire pour `config.yaml` avec échappement Markdown. Remplacer tous les `--force` par un push normal avec rebase, comme `onpush_builder.yaml:492-505`.

### M9 — `qbittorrent` : `eval` sur une commande contenant le mot de passe, journalisée

**Axe :** sécurité. `qbittorrent/rootfs/etc/services.d/vpn-upnp/run:75-78` (`eval "${cmd}"`), `:155` (mot de passe WebUI interpolé), `:77` et `:66` (commande et configuration journalisées en mode debug).

**Risque.** Un mot de passe contenant `"`, `` ` `` ou `$(` casse la commande ou exécute du code en root. La valeur vient de la configuration de l'add-on, donc d'un administrateur. Même fonction dans `qbittorrent/rootfs/usr/local/sbin/vpn:80`.

**Correction suggérée.** Remplacer `_cmd "chaîne"` par un tableau d'arguments exécuté sans `eval`.

### M10 — Contournements d'authentification propres à certains add-ons

**Axe :** sécurité.

- `birdnet-pi/rootfs/etc/cont-init.d/91-nginx_ingress.sh:59` : `is_authenticated()` renvoie vrai dès que l'en-tête `Referer`, fourni par le client, contient le chemin d'Ingress. Ce chemin n'est pas un secret, et le port 8081 est publié. `birdnet-pi/rootfs/etc/cont-init.d/99-run.sh:34` retire le mot de passe du compte `pi` quand l'option est vide.
- `calibre_web/rootfs/etc/cont-init.d/80-configuration.sh:20-33` : connexion par en-tête `X-WebAuth-User` acceptée depuis tout `172.30.32.0/23`, soit n'importe quel autre add-on.
- `guacamole/rootfs/etc/cont-init.d/90-ingress.sh:48-52` : avec l'extension `auth-header`, le port publié accepte n'importe quel `REMOTE_USER`. L'add-on avertit mais démarre.
- `nginx_webserver_proxy/run.sh:64-66` (†) : `static_site_root` hors des chemins prévus n'entraîne qu'un avertissement, avec `autoindex` sur le port 80.

**Correction suggérée.** Fonder l'authentification Ingress sur l'adresse source `172.30.32.2`, jamais sur un en-tête client. Restreindre la plage de confiance de `calibre_web` à cette adresse.

### M11 — 122 options secrètes typées `str` au lieu de `password`

**Axe :** sécurité, qualité. 24 options seulement utilisent `password`. Sont en `str` : `cifspassword` (dans une soixantaine d'add-ons), `PASSWORD`, `gitapi`, `OPENVPN_PASSWORD`, les clés API Binance (`binance-trading-bot/config.yaml`), `DB_PASSWORD`, `JWT_SECRET`.

**Risque.** Valeurs affichées en clair dans l'interface de configuration, donc visibles à l'écran et dans les captures.

**Correction suggérée.** Typer `password?`. Le changement est compatible avec les valeurs existantes.

### M12 — Injection de valeurs d'options dans des scripts et des requêtes SQL

**Axe :** sécurité, robustesse. Valeurs contrôlées par l'administrateur : le risque est surtout la casse sur caractères spéciaux.

- Écriture non protégée dans un script exécuté : `scrutiny/rootfs/etc/cont-init.d/01-configuration.sh:41`, `scrutiny/.../90-run.sh:49`, `seafile/rootfs/etc/cont-init.d/99-run.sh:274`, `.templates/01-config_yaml.sh:195-200`, `fireflyiii_data_importer/rootfs/etc/cont-init.d/99-run.sh:39`.
- SQL interpolé : `immich/rootfs/etc/cont-init.d/99-run.sh:121`, `postgres_15/rootfs/etc/cont-init.d/99-run.sh:343`, `spotweb/rootfs/etc/cont-init.d/90-spotweb:111` (†), `zoneminder/rootfs/etc/cont-init.d/99-run.sh:120` (†).
- Mots de passe en argument de commande, visibles dans la liste des processus : `.templates/00-smb_mounts.sh:324`, `:379`, `:448` ; `immich/.../99-run.sh:101` ; `postgres_15/.../99-run.sh:168` ; `fireflyiii/.../99-run.sh:145`.

**Correction suggérée.** Pour l'écriture dans un script, ne pas faire passer la valeur par `sed` : `printf %q` échappe les espaces par une barre oblique que `sed -i "1a ..."` retire ensuite (cas de `scrutiny/rootfs/etc/cont-init.d/01-configuration.sh:41`). Écrire la ligne avec `printf 'export TZ=%q\n' "$TZ"` dans un fichier temporaire assemblé par `cat`, ou lire la valeur au lancement depuis un fichier au lieu de l'insérer dans le script. Pour le SQL, `printf %q` ne protège rien : passer les valeurs en paramètres (`psql -v nom="$val"` puis `:'nom'`) ou utiliser l'échappement propre à la base (`quote_literal`, `format('%L')`). Passer les identifiants par fichier ou variable (`PGPASSWORD`, `--defaults-extra-file`, `smbclient -A`).

### M13 — Montages SMB : repli automatique vers SMBv1 et NTLM

**Axe :** sécurité. `.templates/00-smb_mounts.sh:127-142` et `:397` essaient successivement toutes les versions jusqu'à `vers=1.0` et `sec=ntlm`.

**Risque.** Un attaquant sur le réseau local peut provoquer l'échec de la négociation pour forcer un protocole cassé et capturer les identifiants. Seul un avertissement signale SMBv1 après coup (`:429-433`). L'option `smbv1` existe au schéma mais le repli a lieu sans elle.

**Correction suggérée.** Ne descendre sous SMB 2.1 que si `smbv1: true`.

### M14 — Jellyfin : migration de dossiers qui supprime la source même si la copie échoue

**Axe :** robustesse, intégrité des données. `jellyfin/rootfs/etc/cont-init.d/20-folders.sh:31-32`.

**Risque.** Quand un vrai répertoire existe à l'emplacement du lien, le script copie son contenu avec `cp -a ... || true`, puis supprime la source avec `rm -r`. Un échec de copie (disque plein, permissions, volume réseau absent) est ignoré et la suppression a lieu quand même. Aucune sauvegarde n'est faite avant. La perte est irréversible et touche les données de l'utilisateur au démarrage de l'add-on.

**Correction suggérée.** Supprimer la source seulement si la copie réussit : `cp -a "$link_path/." "$target_dir/" && rm -r "$link_path"`, sinon journaliser l'erreur et laisser le répertoire en place. À défaut, renommer la source en `.bak` au lieu de la supprimer.

---

## 6. Sévérité basse

### B1 — CI : injection de script dans le workflow de PR

`.github/workflows/onpr_check-pr.yaml:75-76`, `:147-148`, `:162-172`, `:197` interpolent dans du shell un nom de répertoire issu du diff et des champs du `config.yaml` de la PR. Impact limité : les PR de forks ont un jeton en lecture et aucun secret, et le workflow construit déjà leurs Dockerfiles. `weekly_crlftolf.yaml:48` interpole des noms de fichiers.

**Correction.** Passer ces valeurs par `env:`, comme le fait déjà `onpush_builder.yaml:154-155`.

### B2 — CI : workflows morts, incohérents ou fragiles

- `.github/workflows/weekly_addons_updater` n'a pas d'extension `.yaml` : GitHub ne le charge pas. Il utilise `actions/checkout@v3` et écrit un JSON invalide. `CLAUDE.md` le présente pourtant comme le mécanisme hebdomadaire de mise à jour.
- `lint.yml:78` attend un événement `schedule` absent des déclencheurs : la correction automatique documentée comme hebdomadaire ne tourne que manuellement. Le job `lint-changes` corrige des fichiers sans jamais les committer.
- `weekly_stats.yaml:59`, `:66` : le compteur `c` n'est jamais remis à zéro et la sortie n'a lieu qu'à `c == 10`. Après un premier épuisement, un second échec boucle jusqu'au délai maximal du job.
- `onpr_check-pr.yaml:14` teste `github.event.head_commit.message`, absent des événements `pull_request` : la condition `nobuild` est inopérante. Les branches `armhf`, `armv7`, `i386` (`:212-281`) et l'étiquette `authors=Poeschl` (`:170`) sont des restes.
- `archived_lint-checks.yaml` et `onpr_automerge.old` : désactivés mais conservés, avec `jitterbit/get-changed-files@v1`, action abandonnée. Les cinq workflows IA désactivés gardent leurs déclencheurs et l'usage de `AI_PR_TOKEN` : une réactivation par erreur les rendrait actifs immédiatement.

### B3 — Scripts d'initialisation et d'entrée inscriptibles par tous

117 Dockerfiles font `chmod 777 /ha_entrypoint.sh` (exemple `sonarr/Dockerfile:75`). S'y ajoutent `portainer/Dockerfile:93`, `browser_chromium/Dockerfile:65`, `birdnet-pi/Dockerfile:75`, `resiliosync/rootfs/etc/cont-init.d/01-folders.sh:76`, `photoprism/rootfs/etc/cont-init.d/00-folders.sh:24-31`, `epicgamesfree/rootfs/etc/cont-init.d/99-run.sh:45`, `teamspeak/rootfs/etc/cont-init.d/20-folders.sh:10-14`, `qbittorrent/rootfs/etc/cont-init.d/92-qbit_manage.sh:12` (contient le mot de passe WebUI). Impact limité car le Supervisor recrée le conteneur à chaque redémarrage. `755` suffit.

### B4 — Bugs dans les modules partagés

- `.templates/99-custom_script.sh:9` : `"$CONFIGSOURCE"./script.sh` produit un chemin du type `/config./script.sh`, inexistant.
- `.templates/19-json_repair.sh:18-19` : déplace le fichier de défauts au lieu du fichier utilisateur, puis copie une source qui n'existe plus.
- `.templates/01-config_yaml.sh:162` : `$(... | grep -q ' ')` est toujours vide, la détection de doublons ne se déclenche jamais. `:84` applique `chmod -R 755` au répertoire de configuration.
- `.templates/00-local_mounts.sh:13` écrit un fichier temporaire dans le répertoire courant ; `:65`, `:68` utilisent `grep -q "$disk"` non ancré ; `:95` contient `bashio::log.fatal :`.
- `.templates/90-dns_set.sh:35` passe une valeur utilisateur comme format `printf`.
- `.templates/00-smb_mounts.sh:245-247` : un export NFS se terminant par `..` donne `diskname=..` et un montage sur `/mnt/..`.

### B5 — Bugs dans les add-ons

- `arpspoof/rootfs/etc/cont-init.d/99-run.sh:9` : test inversé (`-n` au lieu de `-z`), l'autodétection ne joue jamais quand l'interface est vide. Le script lancé à la ligne 16 est absent du dépôt.
- `immich/rootfs/etc/cont-init.d/01-migrate.sh:18` : faute `addons_autoscrips`, la migration ne s'exécute jamais.
- `photoprism/rootfs/etc/cont-init.d/00-folders.sh:29-31` : la boucle crée des dossiers nommés littéralement `BACKUP_PATH` au lieu d'utiliser la valeur des variables.
- Perte de données Jellyfin : reclassée en sévérité moyenne, voir M14.
- `lidarr/rootfs/etc/cont-init.d/20-folders.sh:26` : `rm -rf /config/addons_config` sans garde.
- `calibre/rootfs/etc/cont-init.d/80-configuration.sh:49-54` : `passwd -d abc` précède la définition du mot de passe et le bloc finit par `|| true` : un échec laisse le compte sans mot de passe.
- `linkwarden/rootfs/etc/cont-init.d/99-run.sh:81` : échec de l'initialisation de la base avalé par `|| true`.
- `letta_code/rootfs/etc/cont-init.d/20-config_location.sh:26-27`, `qbittorrent/rootfs/etc/cont-init.d/93-openvpn.sh:45-46` : secret écrit avant le `chmod 600`.

### B6 — Code mort

Modules de `.templates/` référencés par aucun Dockerfile : `99-custom_script.sh`, `19-json_repair.sh`, `91-silent.sh`, `91-universal_graphic_drivers.sh`, `00-aaa_dockerfile_backup.sh`, `00-bettercomments.sh`, `ha_entrypoint_modif.sh`. Deux d'entre eux contiennent les bugs de B4, et `00-aaa_dockerfile_backup.sh:50-51` fait `chmod -R 777` sur les scripts d'initialisation. `.templates/bashio-standalone.sh:466` passe une variable d'environnement à `eval`.

### B7 — Duplication

244 copies redondantes strictement identiques sous `rootfs/` : `resolver.conf` (49), `ssl_params.conf` (44), `server_params.conf` (30), `proxy_params.conf` (22), `nginx.conf` (20). `32-nginx_ingress.sh` existe en 43 exemplaires pour 30 contenus distincts, `20-folders.sh` en 39 pour 29. Le bloc de healthcheck est recopié dans 66 Dockerfiles. Conséquence directe : M1 doit être corrigé 43 fois, et le correctif `claude_desktop` n'a pas atteint les copies de `calibre`. Le dépôt sait déjà partager par liens symboliques (60 liens, `webtop` vers `claude_desktop`) et par modules : y déplacer les includes nginx et un `32-nginx_ingress.sh` paramétré.

### B8 — Gestion d'erreurs

42 scripts cont-init sur 312 n'ont pas `set -e`. On compte 354 `|| true` et 98 directives `shellcheck disable`. `.templates/ha_entrypoint.sh:407-425` journalise l'échec d'un script d'initialisation puis continue : un add-on dont la configuration a échoué démarre quand même. C'est un choix de disponibilité, mais il masque des états à moitié configurés, par exemple une authentification non appliquée.

### B9 — Dépendances obsolètes ou non suivies

- `comixed/Dockerfile:20` : `openjdk:17-jdk-slim`, image officielle dépréciée.
- Mises à jour en pause sans raison documentée : `postgres_15`, `postgres_17`, `webtop`, `birdnet-pi`, `battybirdnet-pi`, `inadyn`, `organizr`, `binance-trading-bot`, `fireflyiii_fints_importer`, `obsidian_syncserver_npm`. `postgres_17/updater.json` suit encore la version amont `15.5`.
- Sans mise à jour depuis plus d'un an : `arpspoof` (2021), `xteve` (2022), `booksonic_air` (2023), `comixed`, `spotweb`, `readarr` (projet amont arrêté).
- Sans `updater.json` : `addons_updater`, `netbird-server`, `nginx_webserver_proxy`, `teamspeak`.
- `.templates/ha_automatic_packages.sh:255` : `tempio` figé à `2021.09.0`, sans somme de contrôle.

### B10 — Paramètres TLS

`rootfs/etc/nginx/includes/ssl_params.conf` (44 copies) : TLS 1.2 seul, sans TLS 1.3, avec des suites CBC (`ECDHE-RSA-AES256-SHA384`, `AES256-SHA`). Les healthchecks utilisent `curl -k` vers `127.0.0.1`, ce qui est acceptable.

### B11 — Points non vérifiés à confirmer

- Absence de coupe-circuit VPN (†) : `qbittorrent/rootfs/usr/local/sbin/vpn:209-220` ne pose que des règles `INPUT`, et `transmission_openvpn` n'en pose aucune dans ses propres fichiers. L'image amont peut en fournir.
- Aucun profil AppArmor pour `signalk` (`apparmor: false`). Les autres profils autorisent `file,`, `mount,` et `capability sys_admin` : ils n'apportent presque aucun confinement.
- `netalertx_fa`, `scrutiny_fa`, `portainer_agent` demandent `full_access` ; `portainer_agent` monte en plus la configuration Home Assistant.

---

## 7. Second avis Codex

Deux passes `codex exec`, effort élevé, lecture seule, avec consigne de chercher à réfuter.

| Constat | Verdict Codex | Effet sur le rapport |
|---|---|---|
| C1 file managers | Confirmé pour les deux Filebrowser, partiel pour Cloud Commander | Réserve ajoutée sur le défaut amont de cloudcmd |
| C2 fusion de PR | Confirmé, critique justifié | Précisions : limite de 100 PR, un rebuild est nécessaire |
| H1 *arr | Partiel | Readarr nuancé : son script nginx retire `external` |
| H3 Portainer | Confirmé | Correction du sens du mappage de port ; stockage en clair ajouté |
| H4 bureaux web | Partiel | Dépend des images LinuxServer ; avertissement Brave inopérant ajouté |
| H5 addons_updater | Confirmé, haute | Ajout : `gitapi` échappe au masquage des logs |
| H6 panel_admin | Partiel | Élévation limitée aux add-ons où elle est démontrée |
| M1 Ingress | Confirmé | Décompte ramené de 50 à 43 add-ons, sévérité moyenne |
| M2 00-global_var | Partiel | Abaissé de haute à moyenne |
| M4 env.sh | Confirmé, conditionnel | Abaissé à moyenne ; ajout de la journalisation des options |
| M8 on_issues | Partiel | Portée réduite : un seul add-on concerné |
| M7, B1 | Confirmés | Aucun changement |

Les constats H2, H7, H8 et les sévérités moyennes et basses restantes n'ont pas été soumis à Codex.

---

## 8. Points positifs relevés

- `onpush_builder.yaml` : permissions en lecture par défaut, écriture accordée par job, `persist-credentials: false` au build, valeurs non fiables passées par `env:`, revert borné aux commits de la poussée.
- `00-global_var.sh` : échappement correct des valeurs, auto-test de bout en bout, refus des `env_vars` qui écrasent une option.
- `claude_desktop/Dockerfile:186-193` et `81-codex_cli.sh:171-213` : vérification SHA-256 de chaque binaire téléchargé.
- `00-smb_mounts.sh` : identifiants dans un fichier temporaire en `600`, supprimé après usage, mot de passe masqué dans le log de montage.
- `00-local_mounts.sh:54`, `:133` : refus de `..` et des liens sortant du disque.
- `resolve_symlinks.sh` : échec explicite sur lien cassé plutôt que suppression silencieuse.
- Tous les add-ons actifs livrent un `apparmor.txt`, sauf `signalk`.
- `joal` et `guacamole` détectent et signalent leurs configurations dangereuses.
