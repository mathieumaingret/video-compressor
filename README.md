# Video Compressor

Compresse des vidéos MP4 avec FFmpeg (x265) en conservant les metadata et la date des fichiers. Seules les vidéos absentes de la destination sont traitées ; les sources ne sont jamais modifiées.

## Prérequis

- Docker et `make`
- Pour `compress-native` : `ffmpeg` et `ffprobe` installés sur la machine (`brew install ffmpeg`)

## Utilisation

```bash
make build                                                   # une seule fois
make compress-native SRC=~/Pictures/DCIM DEST=~/Pictures/DCIM-compressed
make check           SRC=~/Pictures/DCIM DEST=~/Pictures/DCIM-compressed
```

| Cible             | Rôle                                                              |
|-------------------|-------------------------------------------------------------------|
| `compress-native` | Compresse avec le FFmpeg de la machine (≈ 2× plus rapide sur Mac) |
| `compress-docker` | Compresse avec le FFmpeg de l'image Docker                        |
| `check`           | Compare metadata et dates entre `SRC` et `DEST`                   |
| `purge`           | Vide `source/`, `dist/` et `logs/` du projet (jamais `SRC`/`DEST`) |

| Variable | Défaut                    |
|----------|---------------------------|
| `SRC`    | `./source`                |
| `DEST`   | `./dist`                  |
| `LOGS`   | `./logs`                  |
| `CODEC`  | `libx265` (ou `libx264`)  |
| `CRF`    | `28` (x265) / `23` (x264) |
| `PRESET` | `medium`                  |

## Logs

Un CSV par exécution dans `LOGS` : statut (`compressed`, `copied` si aucun gain, `failed`), chemins et tailles source / destination (en octets et en Mo), gain et note éventuelle.

## Limites

- Les pistes de données inconnues de FFmpeg sont perdues (ex. piste `mett` des Google Pixel) ; c'est indiqué dans le log et signalé par `make check`.
- Les metadata Dolby Vision ne sont pas conservées.
- Lancer `make check` sur quelques vidéos avant de supprimer des originaux.
