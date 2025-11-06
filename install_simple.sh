#!/bin/bash
# Script de instalação simplificado usando docker run

echo "=========================================="
echo "🛫 Flight Monitor - Instalação Simples"
echo "=========================================="

# Verificar arquitetura
ARCH=$(uname -m)
echo "Arquitetura: $ARCH"

# Verificar Docker
if ! command -v docker &> /dev/null; then
	echo "❌ Docker não encontrado. Instalando..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	sudo usermod -aG docker $USER
	rm get-docker.sh
	echo "✅ Docker instalado"
	echo "⚠️  Faça logout e login novamente para usar Docker sem sudo"
	exit 0
else
	echo "✅ Docker instalado"
fi

# Criar diretórios
echo "Criando diretórios..."
mkdir -p data logs
chmod -R 755 data logs

# Verificar .env
if [ ! -f .env ]; then
	echo "❌ Arquivo .env não encontrado!"
	echo "Criando .env de exemplo..."
	cat > .env << 'EOF'
# Token NordVPN
# Obtenha em: https://my.nordaccount.com/dashboard/nordvpn/
NORDVPN_TOKEN=your_token_here

# Configurações
FLASK_ENV=production
TZ=America/Sao_Paulo
EOF
	echo ""
	echo "⚠️  EDITE o arquivo .env e adicione seu token NordVPN!"
	echo "   nano .env"
	echo ""
	read -p "Pressione ENTER após configurar o token..."
fi

# Carregar variáveis
source .env

if [ "$NORDVPN_TOKEN" = "your_token_here" ]; then
	echo "❌ Token NordVPN não configurado!"
	echo "Edite o arquivo .env primeiro"
	exit 1
fi

# Criar rede Docker
echo "Criando rede Docker..."
docker network create vpn_network 2>/dev/null || echo "Rede já existe"

# Build da imagem
echo ""
echo "Construindo imagem (pode demorar 15-30 min no ARM64)..."
docker build -t flight_monitor:latest .

if [ $? -ne 0 ]; then
	echo "❌ Erro no build"
	exit 1
fi

echo ""
echo "=========================================="
echo "✅ Build concluído!"
echo "=========================================="
echo ""
echo "Para iniciar o sistema, use:"
echo "  ./start.sh"
echo ""
echo "Para parar:"
echo "  ./stop.sh"
echo ""
echo "Para ver logs:"
echo "  ./logs.sh"
echo ""