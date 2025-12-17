# Gluetun Port Forward Sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Image Size](https://img.shields.io/docker/image-size/go0ners/gluetun-pfw-sync/latest)](https://hub.docker.com/r/go0ners/gluetun-pfw-sync)
[![Docker Pulls](https://img.shields.io/docker/pulls/go0ners/gluetun-pfw-sync)](https://hub.docker.com/r/go0ners/gluetun-pfw-sync)
[![GitHub stars](https://img.shields.io/github/stars/Go0ners/gluetun-pfw-sync?style=social)](https://github.com/Go0ners/gluetun-pfw-sync)

**Synchronisez automatiquement le port forwarded de Gluetun vers qBittorrent en temps réel.**

Un conteneur Docker léger qui surveille en continu le port forwarded par Gluetun (VPN) et met à jour automatiquement la configuration de qBittorrent. Plus besoin de configurer manuellement le port après chaque redémarrage ou changement de VPN !

## 📋 Overview

Lorsque vous utilisez Gluetun comme conteneur VPN avec port forwarding, le port assigné peut changer à chaque redémarrage ou reconnexion. Ce conteneur résout ce problème en :
- 🔄 Surveillant automatiquement les changements de port via l'API Gluetun
- ⚡ Mettant à jour instantanément qBittorrent avec le nouveau port
- 🔁 Vérifiant périodiquement que tout reste synchronisé
- 📊 Fournissant des logs clairs et détaillés

## ✨ Features

- ✅ **Synchronisation automatique** : Aucune intervention manuelle nécessaire
- ✅ **Léger** : Basé sur Alpine Linux (~5MB)
- ✅ **Configurable** : Intervalles de vérification personnalisables
- ✅ **Robuste** : Gestion automatique des erreurs et retry
- ✅ **Logs détaillés** : Mode INFO et DEBUG disponibles
- ✅ **Facile à déployer** : Compatible docker-compose

## 🚀 Quick Start

### Prérequis

- [Gluetun](https://github.com/qdm12/gluetun) avec port forwarding activé
- [qBittorrent](https://hub.docker.com/r/linuxserver/qbittorrent) accessible via API
- Docker et Docker Compose

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

## 📦 Exemple complet avec Docker Compose

Voici un exemple complet incluant Gluetun, qBittorrent et le sync :

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - 8080:8080  # qBittorrent WebUI
      - 6881:6881  # qBittorrent TCP
      - 6881:6881/udp  # qBittorrent UDP
    environment:
      - VPN_SERVICE_PROVIDER=your_provider
      - VPN_TYPE=openvpn
      - OPENVPN_USER=your_username
      - OPENVPN_PASSWORD=your_password
      - SERVER_REGIONS=your_region
      - VPN_PORT_FORWARDING=on
      - VPN_PORT_FORWARDING_PROVIDER=your_provider
    restart: unless-stopped

  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:gluetun"  # Utilise le réseau de Gluetun
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
      - WEBUI_PORT=8080
    volumes:
      - ./qbittorrent/config:/config
      - ./downloads:/downloads
    depends_on:
      - gluetun
    restart: unless-stopped

  gluetun-pfw-sync:
    image: go0ners/gluetun-pfw-sync:latest
    container_name: gluetun-pfw-sync
    environment:
      - GLUETUN_API_URL=http://gluetun:8000
      - QBITTORRENT_API_URL=http://gluetun:8080
      - QBITTORRENT_USERNAME=admin
      - QBITTORRENT_PASSWORD=yourpassword
      - CHECK_INTERVAL=300
      - RETRY_INTERVAL=60
      - LOG_LEVEL=INFO
    depends_on:
      - gluetun
      - qbittorrent
    restart: unless-stopped
```

## 🔧 Troubleshooting

### Le conteneur ne peut pas se connecter à Gluetun

**Problème** : `Failed to retrieve port from Gluetun`

**Solutions** :
- Vérifiez que Gluetun est démarré et accessible
- Vérifiez que l'URL de l'API Gluetun est correcte (`http://gluetun:8000`)
- Assurez-vous que le port forwarding est activé dans Gluetun
- Testez manuellement : `curl http://gluetun:8000/v1/openvpn/portforwarded`

### Le conteneur ne peut pas se connecter à qBittorrent

**Problème** : `Failed to login to qBittorrent`

**Solutions** :
- Vérifiez les identifiants qBittorrent (username et password)
- Vérifiez que l'URL de l'API qBittorrent est correcte
- Si qBittorrent utilise le réseau de Gluetun, utilisez `http://gluetun:8080`
- Vérifiez que l'API Web de qBittorrent est activée dans les paramètres

### Le port ne se met pas à jour

**Problème** : Le port reste inchangé dans qBittorrent

**Solutions** :
- Activez le mode DEBUG pour voir les détails : `LOG_LEVEL=DEBUG`
- Vérifiez les logs : `docker logs -f gluetun-pfw-sync`
- Assurez-vous que le port a réellement changé dans Gluetun
- Vérifiez que qBittorrent accepte les changements de port via l'API

### Logs trop verbeux

**Solution** : Utilisez `LOG_LEVEL=INFO` au lieu de `DEBUG`

## 🤝 Contributing

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir une issue pour signaler un bug
- Proposer une pull request pour une amélioration
- Partager vos suggestions et retours

## 📄 License

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## ⭐ Support

Si ce projet vous a été utile, n'hésitez pas à lui donner une étoile sur [GitHub](https://github.com/Go0ners/gluetun-pfw-sync) !

## 🔗 Liens utiles

- [Gluetun Documentation](https://github.com/qdm12/gluetun)
- [qBittorrent Documentation](https://github.com/qbittorrent/qBittorrent)
- [Docker Hub](https://hub.docker.com/r/go0ners/gluetun-pfw-sync)
- [GitHub Repository](https://github.com/Go0ners/gluetun-pfw-sync)
