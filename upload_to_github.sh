#!/bin/bash

# Script para Preparar e Fazer Upload para GitHub
# Execute: ./upload_to_github.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════"
echo -e "  ${CYAN}📦 PREPARANDO PROJETO PARA GITHUB${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git não está instalado!${NC}"
    echo "Instale com: sudo apt-get install git"
    exit 1
fi

# Verificar se estamos no diretório correto
if [ ! -f "app_v3_COMPLETO.py" ]; then
    echo -e "${RED}❌ Arquivo app_v3_COMPLETO.py não encontrado!${NC}"
    echo "Execute este script no diretório do projeto."
    exit 1
fi

echo -e "${YELLOW}[1/8]${NC} Preparando estrutura de arquivos..."

# Criar diretórios se não existirem
mkdir -p docs scripts

# Mover documentação para pasta docs
if [ ! -d "docs" ]; then
    mkdir -p docs
fi

# Verificar se README_GITHUB.md existe
if [ -f "README_GITHUB.md" ]; then
    echo -e "${GREEN}✅ README_GITHUB.md encontrado${NC}"
else
    echo -e "${RED}❌ README_GITHUB.md não encontrado!${NC}"
    echo "Certifique-se de ter baixado todos os arquivos."
    exit 1
fi

# Renomear README_GITHUB.md para README.md
if [ -f "README_GITHUB.md" ]; then
    cp README_GITHUB.md README.md
    echo -e "${GREEN}✅ README.md criado${NC}"
fi

# Verificar .gitignore
if [ ! -f ".gitignore" ]; then
    echo -e "${YELLOW}⚠️  .gitignore não encontrado${NC}"
    echo "Criando .gitignore básico..."
    cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
data/
logs/
*.log
.env
.venv
*.db
credentials.json
secrets.json
EOF
    echo -e "${GREEN}✅ .gitignore criado${NC}"
else
    echo -e "${GREEN}✅ .gitignore encontrado${NC}"
fi

# Verificar LICENSE
if [ ! -f "LICENSE" ]; then
    echo -e "${YELLOW}⚠️  LICENSE não encontrado${NC}"
    echo "Recomenda-se adicionar uma licença ao projeto."
else
    echo -e "${GREEN}✅ LICENSE encontrado${NC}"
fi

echo ""
echo -e "${YELLOW}[2/8]${NC} Inicializando repositório Git..."

# Verificar se já é um repositório git
if [ -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Repositório Git já existe${NC}"
    read -p "Deseja continuar? Isso pode sobrescrever configurações existentes. (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operação cancelada."
        exit 1
    fi
else
    git init
    echo -e "${GREEN}✅ Repositório Git inicializado${NC}"
fi

echo ""
echo -e "${YELLOW}[3/8]${NC} Configurando Git..."

# Verificar configuração do Git
if [ -z "$(git config user.name)" ]; then
    echo -e "${CYAN}Digite seu nome (para commits):${NC}"
    read git_name
    git config user.name "$git_name"
fi

if [ -z "$(git config user.email)" ]; then
    echo -e "${CYAN}Digite seu email (para commits):${NC}"
    read git_email
    git config user.email "$git_email"
fi

echo -e "${GREEN}✅ Git configurado${NC}"
echo "   Nome: $(git config user.name)"
echo "   Email: $(git config user.email)"

echo ""
echo -e "${YELLOW}[4/8]${NC} Criando branch main..."

# Criar/checkout branch main
git checkout -b main 2>/dev/null || git checkout main
echo -e "${GREEN}✅ Branch main ativa${NC}"

echo ""
echo -e "${YELLOW}[5/8]${NC} Adicionando arquivos ao Git..."

# Adicionar todos os arquivos (respeitando .gitignore)
git add -A

# Mostrar o que será commitado
echo -e "${CYAN}Arquivos que serão commitados:${NC}"
git status --short

echo ""
echo -e "${YELLOW}[6/8]${NC} Criando commit inicial..."

# Criar commit
git commit -m "🎉 Initial commit - Flight Price Monitor V3.0

Features:
- ✈️ Animated plane during search
- 🔒 VPN integration (18 countries)
- 🌐 5 travel sites (Google, Kayak, Skyscanner, Decolar, Momondo)
- 💰 Automatic BRL conversion with real-time rates
- 🔄 Systemd service for 24/7 operation
- 📱 Responsive web interface
- 📊 Smart price comparison and ranking

Ready for production! 🚀" || echo -e "${YELLOW}⚠️  Nenhuma mudança para commit${NC}"

echo -e "${GREEN}✅ Commit criado${NC}"

echo ""
echo -e "${YELLOW}[7/8]${NC} Configurando repositório remoto..."

# Perguntar URL do repositório GitHub
echo -e "${CYAN}Digite a URL do seu repositório GitHub:${NC}"
echo -e "${BLUE}Exemplo: https://github.com/seuusuario/flight-price-monitor.git${NC}"
read repo_url

if [ -z "$repo_url" ]; then
    echo -e "${YELLOW}⚠️  URL não fornecida${NC}"
    echo ""
    echo -e "${CYAN}Você pode adicionar depois com:${NC}"
    echo "   git remote add origin https://github.com/seuusuario/flight-price-monitor.git"
    echo "   git push -u origin main"
    echo ""
    echo -e "${GREEN}✅ Projeto preparado localmente!${NC}"
    exit 0
fi

# Adicionar remote
if git remote | grep -q "origin"; then
    echo -e "${YELLOW}⚠️  Remote 'origin' já existe${NC}"
    git remote set-url origin "$repo_url"
else
    git remote add origin "$repo_url"
fi

echo -e "${GREEN}✅ Remote configurado${NC}"
echo "   URL: $repo_url"

echo ""
echo -e "${YELLOW}[8/8]${NC} Fazendo push para GitHub..."

# Push para GitHub
echo -e "${CYAN}Fazendo push dos arquivos...${NC}"
if git push -u origin main; then
    echo -e "${GREEN}✅ Push realizado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao fazer push${NC}"
    echo ""
    echo -e "${YELLOW}Possíveis causas:${NC}"
    echo "  1. Repositório ainda não existe no GitHub"
    echo "  2. Você não tem permissão de escrita"
    echo "  3. Autenticação necessária"
    echo ""
    echo -e "${CYAN}Crie o repositório no GitHub primeiro:${NC}"
    echo "  1. Acesse https://github.com/new"
    echo "  2. Crie um novo repositório (sem README, .gitignore ou LICENSE)"
    echo "  3. Execute novamente este script"
    echo ""
    echo -e "${CYAN}Ou faça push manualmente:${NC}"
    echo "   git push -u origin main"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${GREEN}🎉 PROJETO ENVIADO PARA GITHUB!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${CYAN}📦 Seu repositório:${NC}"
echo "   $repo_url"
echo ""
echo -e "${CYAN}🌐 Acesse no navegador:${NC}"
# Extrair URL do navegador (remover .git do final)
browser_url="${repo_url%.git}"
echo "   $browser_url"
echo ""
echo -e "${CYAN}📝 Próximos passos:${NC}"
echo "   1. Acesse seu repositório no GitHub"
echo "   2. Adicione uma descrição ao projeto"
echo "   3. Adicione topics (tags) como: flight-monitor, python, raspberry-pi, flask"
echo "   4. Configure GitHub Pages (opcional)"
echo "   5. Compartilhe com o mundo! ⭐"
echo ""
echo "═══════════════════════════════════════════════════════════"
