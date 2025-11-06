#!/bin/bash

# Script para Configurar Serviço Systemd - Flight Monitor
# Execute: sudo ./setup_service.sh

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  🔧 CONFIGURANDO SERVIÇO SYSTEMD"
echo "═══════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Execute como root: sudo ./setup_service.sh${NC}"
    exit 1
fi

# Detectar usuário real (não root)
REAL_USER=${SUDO_USER:-pi}
REAL_HOME=$(eval echo ~$REAL_USER)
INSTALL_DIR="${REAL_HOME}/flight_vpn_monitor"

echo -e "${BLUE}Usuário:${NC} $REAL_USER"
echo -e "${BLUE}Diretório:${NC} $INSTALL_DIR"
echo ""

# Verificar se app existe
if [ ! -f "$INSTALL_DIR/app_v3_COMPLETO.py" ]; then
    echo -e "${RED}❌ Arquivo não encontrado: $INSTALL_DIR/app_v3_COMPLETO.py${NC}"
    echo "Certifique-se de estar no diretório correto!"
    exit 1
fi

# Criar diretório de logs se não existir
mkdir -p "$INSTALL_DIR/logs"
chown -R $REAL_USER:$REAL_USER "$INSTALL_DIR/logs"

echo -e "${YELLOW}[1/5]${NC} Criando arquivo de serviço..."

# Criar arquivo de serviço
cat > /etc/systemd/system/flight-monitor.service << EOF
[Unit]
Description=Monitor Multi-País de Passagens Aéreas V3.0
Documentation=https://github.com/seu-repo/flight-monitor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$REAL_USER
Group=$REAL_USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=/usr/bin/python3 $INSTALL_DIR/app_v3_COMPLETO.py
Restart=always
RestartSec=10
StandardOutput=append:$INSTALL_DIR/logs/service.log
StandardError=append:$INSTALL_DIR/logs/service_error.log

# Limites de recursos
MemoryLimit=512M
CPUQuota=80%

# Segurança
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✅ Arquivo de serviço criado${NC}"

echo -e "${YELLOW}[2/5]${NC} Recarregando systemd..."
systemctl daemon-reload
echo -e "${GREEN}✅ Systemd recarregado${NC}"

echo -e "${YELLOW}[3/5]${NC} Habilitando serviço (iniciar no boot)..."
systemctl enable flight-monitor.service
echo -e "${GREEN}✅ Serviço habilitado${NC}"

echo -e "${YELLOW}[4/5]${NC} Parando serviços existentes na porta 8776..."
if lsof -Pi :8776 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -ti :8776)
    kill -9 $PID 2>/dev/null || true
    sleep 2
    echo -e "${GREEN}✅ Porta 8776 liberada${NC}"
else
    echo -e "${GREEN}✅ Porta 8776 já está livre${NC}"
fi

echo -e "${YELLOW}[5/5]${NC} Iniciando serviço..."
systemctl start flight-monitor.service
sleep 3

# Verificar status
if systemctl is-active --quiet flight-monitor.service; then
    echo -e "${GREEN}✅ Serviço iniciado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar serviço${NC}"
    echo "Verifique os logs: sudo journalctl -u flight-monitor -n 50"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${GREEN}🎉 SERVIÇO CONFIGURADO COM SUCESSO!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}📊 Status do Serviço:${NC}"
systemctl status flight-monitor.service --no-pager | head -n 10
echo ""
echo -e "${BLUE}🌐 Acessar Aplicação:${NC}"
echo "   Local:    ${YELLOW}http://localhost:8776${NC}"
echo "   Rede:     ${YELLOW}http://$(hostname -I | awk '{print $1}'):8776${NC}"
echo ""
echo -e "${BLUE}📝 Comandos Úteis:${NC}"
echo "   Ver status:     ${YELLOW}sudo systemctl status flight-monitor${NC}"
echo "   Ver logs:       ${YELLOW}sudo journalctl -u flight-monitor -f${NC}"
echo "   Parar:          ${YELLOW}sudo systemctl stop flight-monitor${NC}"
echo "   Reiniciar:      ${YELLOW}sudo systemctl restart flight-monitor${NC}"
echo "   Desabilitar:    ${YELLOW}sudo systemctl disable flight-monitor${NC}"
echo ""
echo -e "${BLUE}📂 Logs Salvos em:${NC}"
echo "   Normal:  ${YELLOW}$INSTALL_DIR/logs/service.log${NC}"
echo "   Erros:   ${YELLOW}$INSTALL_DIR/logs/service_error.log${NC}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ O serviço agora inicia automaticamente no boot!${NC}"
echo ""

# Testar acesso
echo -e "${YELLOW}Testando acesso...${NC}"
sleep 2
if curl -s http://localhost:8776/health > /dev/null; then
    echo -e "${GREEN}✅ Aplicação respondendo corretamente!${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação pode estar iniciando... aguarde alguns segundos${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Pronto para usar! Acesse:${NC} ${YELLOW}http://localhost:8776${NC}"
echo ""