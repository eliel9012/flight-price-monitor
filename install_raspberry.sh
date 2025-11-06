#!/bin/bash

# Script de Instalação para Raspberry Pi - Monitor Multi-País V3.0
# Execute: chmod +x install_raspberry.sh && sudo ./install_raspberry.sh

set -e  # Parar em caso de erro

echo "═══════════════════════════════════════════════════════════"
echo "  ✈️  MONITOR MULTI-PAÍS V3.0 - RASPBERRY PI"
echo "═══════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor, execute como root (sudo ./install_raspberry.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5]${NC} Verificando Python..."
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"

echo -e "${YELLOW}[2/5]${NC} Instalando dependências do sistema..."
apt-get update -qq
apt-get install -y -qq \
    libxml2-dev \
    libxslt-dev \
    python3-dev \
    build-essential \
    libssl-dev \
    libffi-dev 2>&1 | grep -v "already installed" || true

echo -e "${GREEN}✅ Dependências do sistema instaladas${NC}"

echo -e "${YELLOW}[3/5]${NC} Instalando pacotes Python..."
echo "Isto pode demorar no Raspberry Pi..."

# Instalar apenas os pacotes necessários, ignorando os que já estão instalados pelo sistema
pip3 install --break-system-packages --quiet --no-warn-script-location \
    Flask \
    requests \
    beautifulsoup4 \
    html5lib \
    python-dateutil \
    PySocks 2>&1 | grep -v "already satisfied" || true

echo -e "${GREEN}✅ Pacotes Python instalados${NC}"

echo -e "${YELLOW}[4/5]${NC} Criando diretórios..."
mkdir -p data logs
chown -R $SUDO_USER:$SUDO_USER data logs 2>/dev/null || true
echo -e "${GREEN}✅ Diretórios criados${NC}"

echo -e "${YELLOW}[5/5]${NC} Verificando porta 8776..."
if lsof -Pi :8776 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Porta 8776 em uso${NC}"
    read -p "Matar processo? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        PID=$(lsof -ti :8776)
        kill -9 $PID 2>/dev/null || true
        echo -e "${GREEN}✅ Porta liberada${NC}"
    fi
else
    echo -e "${GREEN}✅ Porta 8776 disponível${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${GREEN}🎉 INSTALAÇÃO CONCLUÍDA!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🚀 Para iniciar:"
echo "   ${YELLOW}python3 app_v3_COMPLETO.py${NC}"
echo ""
echo "🌐 Acesse:"
echo "   ${YELLOW}http://localhost:8776${NC}"
echo "   ${YELLOW}http://$(hostname -I | awk '{print $1}'):8776${NC}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

read -p "Iniciar aplicação agora? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${GREEN}🚀 Iniciando aplicação...${NC}"
    echo -e "${YELLOW}Pressione Ctrl+C para parar${NC}"
    echo ""
    if [ -f "app_v3_COMPLETO.py" ]; then
        sudo -u $SUDO_USER python3 app_v3_COMPLETO.py
    else
        echo -e "${RED}❌ app_v3_COMPLETO.py não encontrado!${NC}"
        exit 1
    fi
fi