FROM --platform=linux/amd64 alpine:latest

# Install dependencies
RUN apk add --no-cache curl jq

# Copy sync script
COPY sync-port.sh /usr/local/bin/sync-port.sh
RUN chmod +x /usr/local/bin/sync-port.sh

# Environment variables with default values
ENV GLUETUN_API_URL=http://gluetun:8000
ENV QBITTORRENT_API_URL=http://qbittorrent:8080
ENV QBITTORRENT_USERNAME=admin
ENV QBITTORRENT_PASSWORD=adminadmin
ENV CHECK_INTERVAL=300
ENV RETRY_INTERVAL=60
ENV LOG_LEVEL=INFO

# Run the sync script
CMD ["/usr/local/bin/sync-port.sh"]
