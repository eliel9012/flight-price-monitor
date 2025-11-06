#!/bin/bash

#=============================================
# Script de Inicialização com NordVPN
# Corrige o problema do token e logs
#=============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Iniciando Sistema com NordVPN${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Token do NordVPN
NORDVPN_TOKEN="e9f2ab5aaea92b036aa5225c0b6670d41bf790a090ca5b80e336c8220261c3c6"

# Configurações
NETWORK_NAME="flight_monitor_net"
SUBNET="10.88.0.0/16"
VPN_IP="10.88.0.10"
MONITOR_IP="10.88.0.20"
NGINX_IP="10.88.0.30"

echo -e "${YELLOW}► Parando containers antigos...${NC}"
docker stop nordvpn_container flight_monitor nginx_proxy 2>/dev/null || true
docker rm nordvpn_container flight_monitor nginx_proxy 2>/dev/null || true
echo ""

echo -e "${YELLOW}► Verificando rede...${NC}"
if docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "Rede já existe, removendo..."
    docker network rm $NETWORK_NAME || true
fi

echo "Criando rede com subnet $SUBNET..."
docker network create \
    --subnet=$SUBNET \
    $NETWORK_NAME
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
    -e DEBUG=on \
    --restart unless-stopped \
    ghcr.io/bubuntux/nordvpn:latest

echo "Aguardando VPN conectar (30s)..."
sleep 30
echo ""

echo -e "${GREEN}► Iniciando Flight Monitor...${NC}"
docker run -d \
    --name flight_monitor \
    --network container:nordvpn_container \
    -v $(pwd)/app.py:/app/app.py:ro \
    -v $(pwd)/data:/app/data \
    -e FLASK_PORT=8778 \
    -e PYTHONUNBUFFERED=1 \
    --restart unless-stopped \
    python:3.9-slim bash -c "
        pip install --no-cache-dir flask requests &&
        python /app/app.py
    "
echo ""

echo -e "${GREEN}► Iniciando Nginx...${NC}"
docker run -d \
    --name nginx_proxy \
    --network $NETWORK_NAME \
    --ip $NGINX_IP \
    -p 8080:80 \
    -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
    --restart unless-stopped \
    nginx:alpine
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Sistema Iniciado!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuração:${NC}"
echo "• Rede: $NETWORK_NAME ($SUBNET)"
echo "• NordVPN: $VPN_IP"
echo "• Flight Monitor: via VPN (porta 8778)"
echo "• Nginx: $NGINX_IP (porta 8080)"
echo ""
echo -e "${YELLOW}Acesso:${NC}"
echo "• Interface Web: http://localhost:8080"
echo ""
echo -e "${YELLOW}Comandos úteis:${NC}"
echo "• Ver logs: docker logs -f [container_name]"
echo "• Status VPN: docker exec nordvpn_container nordvpn status"
echo "• Parar tudo: docker stop nordvpn_container flight_monitor nginx_proxy"
echo ""
echo -e "${GREEN}Aguarde ~30s para o sistema ficar completamente operacional${NC}"
echo ""
