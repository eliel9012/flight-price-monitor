#!/bin/bash

# Script de Instalação Automática - Monitor Multi-País V3.0 (CORRIGIDO)
# Execute: chmod +x install_fixed.sh && sudo ./install_fixed.sh

set -e  # Parar em caso de erro

echo "═══════════════════════════════════════════════════════════"
echo "  ✈️  MONITOR MULTI-PAÍS V3.0 - INSTALAÇÃO AUTOMÁTICA"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor, execute como root (sudo ./install_fixed.sh)${NC}"
    exit 1
fi

# Verificar Python
echo -e "${YELLOW}[1/7]${NC} Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 não encontrado!${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"

# Verificar pip
echo -e "${YELLOW}[2/7]${NC} Verificando pip..."
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip3 não encontrado!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ pip3 instalado${NC}"

# Instalar dependências do sistema (IMPORTANTE!)
echo -e "${YELLOW}[3/7]${NC} Instalando dependências do sistema..."
echo "Isso pode levar alguns minutos..."

# Detectar sistema operacional
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu/Raspberry Pi OS
    apt-get update -qq
    apt-get install -y -qq \
        libxml2-dev \
        libxslt-dev \
        python3-dev \
        build-essential \
        libssl-dev \
        libffi-dev \
        zlib1g-dev \
        libjpeg-dev \
        chromium-browser \
        chromium-chromedriver 2>&1 | grep -v "already installed" || true
    echo -e "${GREEN}✅ Dependências do sistema instaladas${NC}"
    
elif [ -f /etc/redhat-release ]; then
    # RedHat/CentOS/Fedora
    yum install -y \
        libxml2-devel \
        libxslt-devel \
        python3-devel \
        gcc \
        openssl-devel \
        libffi-devel \
        zlib-devel \
        libjpeg-devel 2>&1 | grep -v "already installed" || true
    echo -e "${GREEN}✅ Dependências do sistema instaladas${NC}"
    
else
    echo -e "${YELLOW}⚠️  Sistema não reconhecido, tentando continuar...${NC}"
fi

# Instalar dependências Python (versão simplificada sem lxml primeiro)
echo -e "${YELLOW}[4/7]${NC} Instalando dependências Python básicas..."
pip3 install --break-system-packages --quiet \
    Flask==3.0.0 \
    Werkzeug==3.0.1 \
    requests==2.31.0 \
    beautifulsoup4==4.12.2 \
    python-dateutil==2.8.2

echo -e "${GREEN}✅ Dependências básicas instaladas${NC}"

# Tentar instalar lxml (pode falhar, mas não é crítico)
echo -e "${YELLOW}[5/7]${NC} Instalando lxml..."
if pip3 install --break-system-packages --quiet lxml==5.0.0; then
    echo -e "${GREEN}✅ lxml instalado${NC}"
else
    echo -e "${YELLOW}⚠️  lxml falhou, usando html.parser como alternativa${NC}"
    echo "Isso não afetará o funcionamento básico do sistema."
fi

# Tentar instalar Playwright (opcional)
echo -e "${YELLOW}[6/7]${NC} Configurando Playwright (opcional)..."
if pip3 install --break-system-packages --quiet playwright==1.40.0; then
    echo "Instalando navegadores do Playwright..."
    if playwright install chromium 2>&1 | grep -q "Success"; then
        echo -e "${GREEN}✅ Playwright configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  Navegadores Playwright não instalados, usando scrapers básicos${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Playwright não instalado, scrapers reais limitados${NC}"
fi

# Verificar porta
echo -e "${YELLOW}[7/7]${NC} Verificando porta 8776..."
if lsof -Pi :8776 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${RED}⚠️  Porta 8776 em uso!${NC}"
    echo -e "Execute: ${YELLOW}lsof -i :8776${NC} para ver o processo"
    echo -e "E depois: ${YELLOW}kill -9 <PID>${NC} para liberar"
    read -p "Deseja que eu mate o processo automaticamente? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        PID=$(lsof -ti :8776)
        kill -9 $PID 2>/dev/null || true
        echo -e "${GREEN}✅ Porta 8776 liberada${NC}"
    fi
else
    echo -e "${GREEN}✅ Porta 8776 disponível${NC}"
fi

# Criar diretório de dados
mkdir -p data logs
chown -R $SUDO_USER:$SUDO_USER data logs 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${GREEN}🎉 INSTALAÇÃO CONCLUÍDA!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1️⃣  Iniciar aplicação:"
echo "   ${YELLOW}python3 app_v3_COMPLETO.py${NC}"
echo ""
echo "2️⃣  Acessar no navegador:"
echo "   ${YELLOW}http://localhost:8776${NC}"
echo ""
echo "3️⃣  (Opcional) Configurar VPN real:"
echo "   Edite app_v3_COMPLETO.py e descomente o bloco VPN"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Perguntar se quer iniciar automaticamente
read -p "Deseja iniciar a aplicação agora? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${GREEN}🚀 Iniciando aplicação...${NC}"
    echo ""
    if [ -f "app_v3_COMPLETO.py" ]; then
        # Rodar como usuário normal (não root)
        sudo -u $SUDO_USER python3 app_v3_COMPLETO.py
    else
        echo -e "${RED}❌ Arquivo app_v3_COMPLETO.py não encontrado!${NC}"
        echo "Certifique-se de estar no diretório correto."
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Para iniciar depois, execute:${NC}"
    echo "   python3 app_v3_COMPLETO.py"
    echo ""
fi