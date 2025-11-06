#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Flight Monitor - Portas Corretas${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Token do NordVPN
NORDVPN_TOKEN="e9f2ab5aaea92b036aa5225c0b6670d41bf790a090ca5b80e336c8220261c3c6"

# Configurações CORRETAS
NETWORK_NAME="flight_monitor_net"
SUBNET="10.88.0.0/16"
VPN_IP="10.88.0.10"
NGINX_IP="10.88.0.30"
FLASK_PORT=8776  # Flask interno
NGINX_PORT=8777  # Nginx externo

echo -e "${YELLOW}► Parando apenas containers do Flight Monitor...${NC}"
docker stop nordvpn_container flight_monitor nginx_proxy 2>/dev/null || true
docker rm nordvpn_container flight_monitor nginx_proxy 2>/dev/null || true

echo -e "${YELLOW}► Verificando/criando rede específica...${NC}"
if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "Criando rede $NETWORK_NAME..."
    docker network create --subnet=$SUBNET $NETWORK_NAME
else
    echo "Rede $NETWORK_NAME já existe, usando ela..."
fi

echo ""
echo -e "${GREEN}► Iniciando NordVPN...${NC}"
docker run -d \
    --name nordvpn_container \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --device /dev/net/tun \
    --network $NETWORK_NAME \
    --ip $VPN_IP \
    -e TOKEN="$NORDVPN_TOKEN" \
    -e TECHNOLOGY=NordLynx \
    -e CONNECT=Brazil \
    -e NETWORK=$SUBNET \
    -e TZ=America/Sao_Paulo \
    --restart unless-stopped \
    ghcr.io/bubuntux/nordvpn:latest

echo "Aguardando VPN conectar (30s)..."
sleep 30

echo ""
echo -e "${GREEN}► Iniciando Flight Monitor (porta $FLASK_PORT)...${NC}"
docker run -d \
    --name flight_monitor \
    --network container:nordvpn_container \
    -v $(pwd)/app.py:/app/app.py:ro \
    -v $(pwd)/data:/app/data \
    -e FLASK_PORT=$FLASK_PORT \
    -e PYTHONUNBUFFERED=1 \
    --restart unless-stopped \
    python:3.9-slim bash -c "
        pip install --no-cache-dir flask requests &&
        python /app/app.py
    "

echo ""
echo -e "${GREEN}► Iniciando Nginx (porta externa $NGINX_PORT)...${NC}"
docker run -d \
    --name nginx_proxy \
    --network $NETWORK_NAME \
    --ip $NGINX_IP \
    -p $NGINX_PORT:80 \
    -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
    --restart unless-stopped \
    nginx:alpine

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Sistema Pronto!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📌 Configuração:"
echo "   • Flask (interno): porta $FLASK_PORT"
echo "   • Nginx (externo): porta $NGINX_PORT"
echo ""
echo "🌐 Acesse: http://localhost:$NGINX_PORT"
echo ""
echo "📊 Monitoramento:"
echo "   docker logs -f flight_monitor"
echo "   docker exec nordvpn_container nordvpn status"
echo ""
