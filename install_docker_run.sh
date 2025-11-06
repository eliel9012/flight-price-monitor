#!/bin/bash

echo "================================================================="
echo "🛫 INSTALAÇÃO VIA DOCKER RUN - Monitor de Passagens com VPN"
echo "================================================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado!"
    echo "Instale com: curl -fsSL https://get.docker.com | sudo sh"
    exit 1
fi

echo "✅ Docker encontrado!"
echo ""

# Pedir token NordVPN
read -p "🔑 Digite seu NOVO token NordVPN: " NORDVPN_TOKEN

if [ -z "$NORDVPN_TOKEN" ]; then
    echo "❌ Token não pode estar vazio!"
    exit 1
fi

echo ""
echo "📦 Configurando sistema..."

# Criar rede Docker isolada para VPN
echo "🌐 Criando rede Docker isolada..."
docker network create flight_vpn_network 2>/dev/null || echo "Rede já existe, continuando..."

# Criar volumes para dados persistentes
echo "💾 Criando volumes..."
docker volume create flight_data 2>/dev/null || true
docker volume create flight_logs 2>/dev/null || true

# Parar e remover containers antigos se existirem
echo "🧹 Limpando containers antigos..."
docker stop nordvpn_flight 2>/dev/null || true
docker stop flight_monitor_app 2>/dev/null || true
docker stop nginx_flight_proxy 2>/dev/null || true
docker rm nordvpn_flight 2>/dev/null || true
docker rm flight_monitor_app 2>/dev/null || true
docker rm nginx_flight_proxy 2>/dev/null || true

echo ""
echo "🔨 Construindo imagem do app..."

# Criar Dockerfile temporário
cat > /tmp/Dockerfile.flight << 'EOF'
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget curl chromium chromium-driver \
    fonts-liberation libasound2 libatk-bridge2.0-0 \
    libatk1.0-0 libatspi2.0-0 libcups2 libdbus-1-3 \
    libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 \
    libwayland-client0 libxcomposite1 libxdamage1 \
    libxfixes3 libxkbcommon0 libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir \
    flask==3.0.0 \
    requests==2.31.0 \
    playwright==1.40.0 \
    beautifulsoup4==4.12.2 \
    fake-useragent==1.4.0

RUN playwright install chromium && \
    playwright install-deps

RUN mkdir -p /app/data /app/logs

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Copiar app.py para /tmp
cp app.py /tmp/app.py 2>/dev/null || echo "Usando app.py do diretório atual"

# Build da imagem
docker build -t flight-monitor:latest -f /tmp/Dockerfile.flight . || {
    echo "❌ Erro ao construir imagem"
    exit 1
}

echo ""
echo "🚀 Iniciando containers..."
echo ""

# 1. Iniciar container NordVPN
echo "📡 Iniciando NordVPN (isolado na rede Docker)..."
docker run -d \
    --name nordvpn_flight \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --device /dev/net/tun \
    --sysctl net.ipv4.conf.all.rp_filter=2 \
    --sysctl net.ipv6.conf.all.disable_ipv6=1 \
    -e TOKEN="${NORDVPN_TOKEN}" \
    -e CONNECT=Brazil \
    -e TECHNOLOGY=NordLynx \
    -e NETWORK=172.18.0.0/16 \
    -e TZ=America/Sao_Paulo \
    --network flight_vpn_network \
    --restart unless-stopped \
    ghcr.io/bubuntux/nordvpn:latest

echo "⏳ Aguardando VPN conectar (30s)..."
sleep 30

# 2. Iniciar app usando a rede do container VPN
echo "🐍 Iniciando aplicação Flask..."
docker run -d \
    --name flight_monitor_app \
    --network container:nordvpn_flight \
    -v flight_data:/app/data \
    -v flight_logs:/app/logs \
    -v "$(pwd)/app.py:/app/app.py:ro" \
    -e NORDVPN_TOKEN="${NORDVPN_TOKEN}" \
    --restart unless-stopped \
    flight-monitor:latest

sleep 5

# 3. Iniciar Nginx proxy na porta 1007
echo "🌐 Iniciando Nginx proxy (porta 1007)..."

# Criar configuração Nginx temporária
cat > /tmp/nginx.flight.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream app {
        server nordvpn_flight:5000;
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_connect_timeout 600s;
            proxy_send_timeout 600s;
            proxy_read_timeout 600s;
        }
    }
}
EOF

docker run -d \
    --name nginx_flight_proxy \
    -p 1007:80 \
    -v /tmp/nginx.flight.conf:/etc/nginx/nginx.conf:ro \
    --network flight_vpn_network \
    --restart unless-stopped \
    nginx:alpine

echo ""
echo "================================================================="
echo "✅ SISTEMA INSTALADO E RODANDO!"
echo "================================================================="
echo ""
echo "🌐 Acesse: http://localhost:1007"
echo ""
echo "📊 Comandos úteis:"
echo ""
echo "  # Ver logs do app"
echo "  docker logs -f flight_monitor_app"
echo ""
echo "  # Ver logs da VPN"
echo "  docker logs -f nordvpn_flight"
echo ""
echo "  # Status da VPN"
echo "  docker exec nordvpn_flight nordvpn status"
echo ""
echo "  # Conectar VPN manualmente em país"
echo "  docker exec nordvpn_flight nordvpn c United_States"
echo "  docker exec nordvpn_flight nordvpn c Portugal"
echo ""
echo "  # Ver IP atual (deve ser do país VPN)"
echo "  docker exec flight_monitor_app curl -s https://api.ipify.org"
echo ""
echo "  # Parar tudo"
echo "  docker stop nordvpn_flight flight_monitor_app nginx_flight_proxy"
echo ""
echo "  # Remover tudo"
echo "  docker rm nordvpn_flight flight_monitor_app nginx_flight_proxy"
echo "  docker network rm flight_vpn_network"
echo "  docker volume rm flight_data flight_logs"
echo ""
echo "================================================================="
echo ""
echo "💡 IMPORTANTE:"
echo "   - A VPN está ISOLADA na rede 'flight_vpn_network'"
echo "   - Não afeta outros containers ou seu sistema"
echo "   - App roda na porta 1008 internamente, Nginx expõe na 1007"
echo "   - Todo tráfego do app passa pela VPN"
echo ""
echo "🔒 SEGURANÇA:"
echo "   - VPN funciona APENAS dentro do container"
echo "   - Seu sistema continua usando conexão normal"
echo "   - Outros containers não são afetados"
echo ""

# Verificar se containers estão rodando
echo "🔍 Verificando containers..."
sleep 3

if docker ps | grep -q nordvpn_flight; then
    echo "✅ VPN rodando"
else
    echo "❌ Problema com VPN"
fi

if docker ps | grep -q flight_monitor_app; then
    echo "✅ App rodando"
else
    echo "❌ Problema com App"
fi

if docker ps | grep -q nginx_flight_proxy; then
    echo "✅ Nginx rodando"
else
    echo "❌ Problema com Nginx"
fi

echo ""
echo "================================================================="
