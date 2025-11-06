#!/bin/bash

echo "🚀 Iniciando Flight Monitor com VPN"
echo "=========================================="

# Parar containers antigos
echo "Parando containers antigos..."
docker stop flight_monitor nordvpn nginx_proxy 2>/dev/null
docker rm flight_monitor nordvpn nginx_proxy 2>/dev/null

# Remover redes antigas
echo "Removendo redes antigas..."
docker network rm flight_network monitor_network 2>/dev/null

# Construir imagem
echo "🔨 Construindo imagem..."
docker build -t flight-monitor-latam .

if [ $? -ne 0 ]; then
    echo "❌ Erro ao construir imagem"
    exit 1
fi

# Criar rede
echo "Criando rede Docker..."
docker network create \
  --driver bridge \
  --subnet=10.88.0.0/16 \
  --gateway=10.88.0.1 \
  monitor_network

# Iniciar NordVPN
echo "1️⃣ Iniciando NordVPN..."
docker run -d \
  --name nordvpn \
  --network monitor_network \
  --ip 10.88.0.2 \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --restart unless-stopped \
  -e TOKEN="${NORDVPN_TOKEN}" \
  -e TECHNOLOGY=NordLynx \
  -e CONNECT=Brazil \
  ghcr.io/bubuntux/nordvpn:latest

sleep 10

# Iniciar Flight Monitor
echo "2️⃣ Iniciando Flight Monitor..."
docker run -d \
  --name flight_monitor \
  --network monitor_network \
  --ip 10.88.0.3 \
  -p 8778:8778 \
  --restart unless-stopped \
  -v "$(pwd)/app.py:/app/app.py:ro" \
  flight-monitor-latam

sleep 5

# Iniciar Nginx na porta 8090
echo "3️⃣ Iniciando Nginx..."
docker run -d \
  --name nginx_proxy \
  --network monitor_network \
  --ip 10.88.0.4 \
  -p 8090:80 \
  --restart unless-stopped \
  -v "$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro" \
  nginx:alpine

echo ""
echo "✅ Sistema iniciado!"
echo "🌐 Acesse: http://localhost:8090"
echo "🌐 Ou direto: http://localhost:8778"
echo ""
echo "📊 Para ver os logs: ./logs.sh"
