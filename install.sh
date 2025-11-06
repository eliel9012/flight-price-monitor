#!/bin/bash
# Script de instalação otimizado para Raspberry Pi

echo "=========================================="
echo "🛫 Flight Monitor - Instalação"
echo "=========================================="

# Verificar se está rodando em ARM
ARCH=$(uname -m)
echo "Arquitetura detectada: $ARCH"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "⚠️  Atenção: Este script foi otimizado para ARM64/Raspberry Pi"
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker instalado"
else
    echo "✅ Docker já instalado"
fi

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não encontrado. Instalando..."
    sudo apt-get update
    sudo apt-get install -y docker-compose
    echo "✅ Docker Compose instalado"
else
    echo "✅ Docker Compose já instalado"
fi

# Criar diretórios necessários
echo "Criando diretórios..."
mkdir -p data logs
chmod -R 755 data logs

# Configurar .env
if [ ! -f .env ]; then
    echo "Criando arquivo .env..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANTE: Edite o arquivo .env e adicione seu token NordVPN"
    echo "   Obtenha em: https://my.nordaccount.com/dashboard/nordvpn/"
    echo ""
    read -p "Pressione ENTER para continuar ou Ctrl+C para sair..."
else
    echo "✅ Arquivo .env já existe"
fi

# Build da imagem
echo ""
echo "Construindo imagem Docker (pode demorar no ARM64)..."
docker-compose build --no-cache

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Instalação concluída!"
    echo "=========================================="
    echo ""
    echo "Para iniciar o sistema:"
    echo "  docker-compose up -d"
    echo ""
    echo "Para ver logs:"
    echo "  docker-compose logs -f"
    echo ""
    echo "Para parar:"
    echo "  docker-compose down"
    echo ""
    echo "Acesse: http://localhost:8080"
    echo "=========================================="
else
    echo ""
    echo "❌ Erro na instalação"
    echo "Verifique os logs acima para mais detalhes"
fi
