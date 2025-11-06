#!/bin/bash

# Script de Gerenciamento do Serviço Flight Monitor
# Execute: ./manage_service.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICE_NAME="flight-monitor"

show_header() {
    clear
    echo "═══════════════════════════════════════════════════════════"
    echo -e "  ✈️  ${CYAN}GERENCIADOR DO SERVIÇO FLIGHT MONITOR${NC}"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

show_status() {
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}●${NC} Serviço está ${GREEN}RODANDO${NC}"
        
        # Mostrar há quanto tempo está rodando
        UPTIME=$(systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp --value)
        if [ ! -z "$UPTIME" ]; then
            echo -e "   Rodando desde: ${YELLOW}$UPTIME${NC}"
        fi
        
        # Testar se está respondendo
        if curl -s http://localhost:8776/health > /dev/null 2>&1; then
            echo -e "   Status HTTP: ${GREEN}✅ Respondendo${NC}"
        else
            echo -e "   Status HTTP: ${RED}⚠️  Não responde${NC}"
        fi
    else
        echo -e "${RED}●${NC} Serviço está ${RED}PARADO${NC}"
    fi
    
    if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "   Boot automático: ${GREEN}✅ Habilitado${NC}"
    else
        echo -e "   Boot automático: ${YELLOW}⚠️  Desabilitado${NC}"
    fi
    echo ""
}

show_menu() {
    show_header
    show_status
    
    echo "════════════════ MENU ════════════════"
    echo ""
    echo "  1) 🚀 Iniciar serviço"
    echo "  2) ⏹️  Parar serviço"
    echo "  3) 🔄 Reiniciar serviço"
    echo "  4) 📊 Ver status detalhado"
    echo "  5) 📝 Ver logs (tempo real)"
    echo "  6) 📋 Ver últimas 50 linhas de log"
    echo "  7) 🔧 Habilitar boot automático"
    echo "  8) ❌ Desabilitar boot automático"
    echo "  9) 🌐 Abrir navegador"
    echo " 10) 🔍 Testar conectividade"
    echo " 11) 📂 Ver arquivos de log"
    echo " 12) 🗑️  Limpar logs"
    echo "  0) 🚪 Sair"
    echo ""
    echo "═════════════════════════════════════"
    echo ""
}

start_service() {
    echo -e "${YELLOW}Iniciando serviço...${NC}"
    sudo systemctl start $SERVICE_NAME
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Serviço iniciado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar serviço${NC}"
        echo "Verifique os logs: sudo journalctl -u $SERVICE_NAME -n 50"
    fi
    read -p "Pressione Enter para continuar..."
}

stop_service() {
    echo -e "${YELLOW}Parando serviço...${NC}"
    sudo systemctl stop $SERVICE_NAME
    sleep 1
    echo -e "${GREEN}✅ Serviço parado${NC}"
    read -p "Pressione Enter para continuar..."
}

restart_service() {
    echo -e "${YELLOW}Reiniciando serviço...${NC}"
    sudo systemctl restart $SERVICE_NAME
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Serviço reiniciado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao reiniciar serviço${NC}"
    fi
    read -p "Pressione Enter para continuar..."
}

show_detailed_status() {
    echo -e "${BLUE}Status Detalhado:${NC}"
    echo ""
    sudo systemctl status $SERVICE_NAME --no-pager
    echo ""
    read -p "Pressione Enter para continuar..."
}

show_logs_realtime() {
    echo -e "${BLUE}Logs em Tempo Real (Ctrl+C para sair):${NC}"
    echo ""
    sudo journalctl -u $SERVICE_NAME -f
}

show_logs_last() {
    echo -e "${BLUE}Últimas 50 Linhas de Log:${NC}"
    echo ""
    sudo journalctl -u $SERVICE_NAME -n 50 --no-pager
    echo ""
    read -p "Pressione Enter para continuar..."
}

enable_autostart() {
    echo -e "${YELLOW}Habilitando boot automático...${NC}"
    sudo systemctl enable $SERVICE_NAME
    echo -e "${GREEN}✅ Boot automático habilitado!${NC}"
    echo "O serviço iniciará automaticamente ao ligar o Raspberry Pi"
    read -p "Pressione Enter para continuar..."
}

disable_autostart() {
    echo -e "${YELLOW}Desabilitando boot automático...${NC}"
    sudo systemctl disable $SERVICE_NAME
    echo -e "${GREEN}✅ Boot automático desabilitado${NC}"
    echo "O serviço NÃO iniciará automaticamente ao ligar o Raspberry Pi"
    read -p "Pressione Enter para continuar..."
}

open_browser() {
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}URLs disponíveis:${NC}"
    echo "  Local:  http://localhost:8776"
    echo "  Rede:   http://$IP:8776"
    echo ""
    
    # Tentar abrir navegador
    if command -v xdg-open &> /dev/null; then
        echo "Abrindo navegador..."
        xdg-open "http://localhost:8776" 2>/dev/null &
    else
        echo "Copie e cole uma das URLs acima no navegador"
    fi
    
    read -p "Pressione Enter para continuar..."
}

test_connectivity() {
    echo -e "${BLUE}Testando Conectividade:${NC}"
    echo ""
    
    # Testar porta
    echo -n "Porta 8776: "
    if lsof -Pi :8776 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Aberta${NC}"
    else
        echo -e "${RED}❌ Fechada${NC}"
    fi
    
    # Testar HTTP
    echo -n "HTTP Response: "
    if curl -s http://localhost:8776/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        echo ""
        echo "Resposta da API:"
        curl -s http://localhost:8776/health | python3 -m json.tool 2>/dev/null || echo "Erro ao formatar JSON"
    else
        echo -e "${RED}❌ Sem resposta${NC}"
    fi
    
    echo ""
    echo "IP Local: $(hostname -I | awk '{print $1}')"
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

show_log_files() {
    LOG_DIR="$HOME/flight_vpn_monitor/logs"
    echo -e "${BLUE}Arquivos de Log:${NC}"
    echo ""
    
    if [ -d "$LOG_DIR" ]; then
        ls -lh $LOG_DIR
        echo ""
        echo "Para ver um arquivo:"
        echo "  tail -f $LOG_DIR/service.log"
    else
        echo "Diretório de logs não encontrado: $LOG_DIR"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

clear_logs() {
    LOG_DIR="$HOME/flight_vpn_monitor/logs"
    echo -e "${YELLOW}Limpando logs...${NC}"
    
    read -p "Tem certeza? (s/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo journalctl --vacuum-time=1d
        
        if [ -d "$LOG_DIR" ]; then
            > "$LOG_DIR/service.log"
            > "$LOG_DIR/service_error.log"
        fi
        
        echo -e "${GREEN}✅ Logs limpos!${NC}"
    else
        echo "Operação cancelada"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Menu principal
while true; do
    show_menu
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) show_detailed_status ;;
        5) show_logs_realtime ;;
        6) show_logs_last ;;
        7) enable_autostart ;;
        8) disable_autostart ;;
        9) open_browser ;;
        10) test_connectivity ;;
        11) show_log_files ;;
        12) clear_logs ;;
        0) 
            echo ""
            echo "Até logo! ✈️"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 1
            ;;
    esac
done