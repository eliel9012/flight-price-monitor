#!/bin/bash

# Script de Instalação Automática - Monitor Multi-País V3.0
# Execute: chmod +x install.sh && ./install.sh

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

# Verificar Python
echo -e "${YELLOW}[1/6]${NC} Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 não encontrado!${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"

# Verificar pip
echo -e "${YELLOW}[2/6]${NC} Verificando pip..."
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip3 não encontrado!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ pip3 instalado${NC}"

# Instalar dependências Python
echo -e "${YELLOW}[3/6]${NC} Instalando dependências Python..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --break-system-packages --quiet
    echo -e "${GREEN}✅ Dependências instaladas${NC}"
else
    echo -e "${YELLOW}⚠️  requirements.txt não encontrado, pulando...${NC}"
fi

# Instalar Playwright
echo -e "${YELLOW}[4/6]${NC} Configurando Playwright..."
if command -v playwright &> /dev/null; then
    playwright install chromium --quiet
    echo -e "${GREEN}✅ Playwright configurado${NC}"
else
    echo -e "${YELLOW}⚠️  Playwright não instalado, scrapers reais não funcionarão${NC}"
fi

# Verificar porta
echo -e "${YELLOW}[5/6]${NC} Verificando porta 8776..."
if lsof -Pi :8776 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${RED}⚠️  Porta 8776 em uso!${NC}"
    echo -e "Execute: ${YELLOW}lsof -i :8776${NC} para ver o processo"
    echo -e "E depois: ${YELLOW}kill -9 <PID>${NC} para liberar"
else
    echo -e "${GREEN}✅ Porta 8776 disponível${NC}"
fi

# Criar diretório de dados
echo -e "${YELLOW}[6/6]${NC} Criando estrutura de diretórios..."
mkdir -p data logs
echo -e "${GREEN}✅ Diretórios criados${NC}"

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
        python3 app_v3_COMPLETO.py
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