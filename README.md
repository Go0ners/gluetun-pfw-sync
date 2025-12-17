# Gluetun Port Forward Sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Image Size](https://img.shields.io/docker/image-size/go0ners/gluetun-pfw-sync/latest)](https://hub.docker.com/r/go0ners/gluetun-pfw-sync)
[![Docker Pulls](https://img.shields.io/docker/pulls/go0ners/gluetun-pfw-sync)](https://hub.docker.com/r/go0ners/gluetun-pfw-sync)
[![GitHub stars](https://img.shields.io/github/stars/Go0ners/gluetun-pfw-sync?style=social)](https://github.com/Go0ners/gluetun-pfw-sync)

Synchronise automatiquement le port forwarded de Gluetun vers qBittorrent.

## Utilisation

### Avec docker run

```bash
docker run -d \
  --name gluetun-pfw-sync \
  --restart unless-stopped \
  -e GLUETUN_API_URL=http://gluetun:8000 \
  -e QBITTORRENT_API_URL=http://qbittorrent:8080 \
  -e QBITTORRENT_USERNAME=admin \
  -e QBITTORRENT_PASSWORD=yourpassword \
  -e CHECK_INTERVAL=300 \
  go0ners/gluetun-pfw-sync:latest
```

### Avec docker-compose

```yaml
services:
  gluetun-pfw-sync:
    image: go0ners/gluetun-pfw-sync:latest
    container_name: gluetun-pfw-sync
    restart: unless-stopped
    depends_on:
      - gluetun
    environment:
      - GLUETUN_API_URL=http://gluetun:8000
      - QBITTORRENT_API_URL=http://qbittorrent:8080
      - QBITTORRENT_USERNAME=admin
      - QBITTORRENT_PASSWORD=yourpassword
      - CHECK_INTERVAL=300
      - RETRY_INTERVAL=60
```

## Construction de l'image (développement)

```bash
docker build -t go0ners/gluetun-pfw-sync:latest .
```

## Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `GLUETUN_API_URL` | URL de l'API Gluetun | `http://gluetun:8000` |
| `QBITTORRENT_API_URL` | URL de l'API qBittorrent | `http://qbittorrent:8080` |
| `QBITTORRENT_USERNAME` | Nom d'utilisateur qBittorrent | `admin` |
| `QBITTORRENT_PASSWORD` | Mot de passe qBittorrent | `adminadmin` |
| `CHECK_INTERVAL` | Intervalle de vérification (secondes) | `300` |
| `RETRY_INTERVAL` | Intervalle de retry en cas d'échec (secondes) | `60` |
| `LOG_LEVEL` | Niveau de verbosité des logs (`INFO` ou `DEBUG`) | `INFO` |

## Logs en temps réel

Pour voir les logs en direct du conteneur :

```bash
# Voir les logs en temps réel
docker logs -f gluetun-pfw-sync

# Avec timestamps
docker logs -f --timestamps gluetun-pfw-sync

# Dernières 50 lignes + suivi
docker logs -f --tail 50 gluetun-pfw-sync
```

### Niveau de logs

- **INFO** (défaut) : Logs essentiels (démarrage, récupération du port, mises à jour)
- **DEBUG** : Logs détaillés incluant les codes HTTP et réponses API

Pour activer le mode DEBUG :

```bash
docker run -d \
  -e LOG_LEVEL=DEBUG \
  go0ners/gluetun-pfw-sync:latest
```

### Exemple de logs

**Mode INFO :**
```
[2025-12-17 10:30:00] [INFO] Starting Gluetun Port Forward Sync...
[2025-12-17 10:30:00] [INFO] Gluetun API: http://gluetun:8000
[2025-12-17 10:30:00] [INFO] qBittorrent API: http://qbittorrent:8080
[2025-12-17 10:30:00] [INFO] Retrieving port from Gluetun...
[2025-12-17 10:30:01] [INFO] Got forwarded port: 54321
[2025-12-17 10:30:01] [INFO] Updating qBittorrent port from 12345 to 54321...
[2025-12-17 10:30:02] [INFO] Port updated successfully!
```

## Fonctionnement

1. Récupère le port forwarded depuis l'API Gluetun
2. Se connecte à l'API qBittorrent
3. Compare le port actuel avec le port forwarded
4. Met à jour qBittorrent si nécessaire
5. Attend `CHECK_INTERVAL` secondes et recommence
