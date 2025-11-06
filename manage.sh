#!/bin/bash

# Script de Gerenciamento - Monitor de Passagens com VPN
# Uso via docker run

case "$1" in
  start)
    echo "🚀 Iniciando containers..."
    
    # Verificar se rede existe
    docker network inspect flight_vpn_network >/dev/null 2>&1 || \
        docker network create flight_vpn_network
    
    # Iniciar VPN
    echo "📡 Iniciando VPN..."
    docker start nordvpn_flight 2>/dev/null || \
        echo "❌ Container nordvpn_flight não existe. Execute ./install_docker_run.sh primeiro"
    
    # Iniciar App
    echo "🐍 Iniciando App..."
    docker start flight_monitor_app 2>/dev/null || \
        echo "❌ Container flight_monitor_app não existe. Execute ./install_docker_run.sh primeiro"
    
    # Iniciar Nginx
    echo "🌐 Iniciando Nginx..."
    docker start nginx_flight_proxy 2>/dev/null || \
        echo "❌ Container nginx_flight_proxy não existe. Execute ./install_docker_run.sh primeiro"
    
    echo ""
    echo "✅ Containers iniciados!"
    echo "🌐 Acesse: http://localhost:1007"
    ;;
  
  stop)
    echo "⏸️  Parando containers..."
    docker stop nginx_flight_proxy flight_monitor_app nordvpn_flight 2>/dev/null
    echo "✅ Containers parados"
    ;;
  
  restart)
    echo "🔄 Reiniciando..."
    docker restart nordvpn_flight
    sleep 5
    docker restart flight_monitor_app
    docker restart nginx_flight_proxy
    echo "✅ Reiniciado!"
    ;;
  
  logs)
    echo "📋 Logs do App (Ctrl+C para sair)..."
    docker logs -f flight_monitor_app
    ;;
  
  logs-vpn)
    echo "📋 Logs da VPN (Ctrl+C para sair)..."
    docker logs -f nordvpn_flight
    ;;
  
  status)
    echo "📊 Status dos Containers:"
    echo ""
    docker ps --filter "name=nordvpn_flight" --filter "name=flight_monitor_app" --filter "name=nginx_flight_proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "🔒 Status da VPN:"
    docker exec nordvpn_flight nordvpn status 2>/dev/null || echo "VPN não está rodando"
    echo ""
    echo "🌐 IP Atual (via VPN):"
    docker exec flight_monitor_app curl -s https://api.ipify.org 2>/dev/null || echo "App não está rodando"
    ;;
  
  vpn)
    if [ -z "$2" ]; then
      echo "Conectar VPN em país específico:"
      echo ""
      echo "Exemplos:"
      echo "  ./manage.sh vpn Brazil"
      echo "  ./manage.sh vpn United_States"
      echo "  ./manage.sh vpn Portugal"
      echo "  ./manage.sh vpn Spain"
      echo "  ./manage.sh vpn United_Kingdom"
      echo "  ./manage.sh vpn Germany"
      echo "  ./manage.sh vpn France"
      echo "  ./manage.sh vpn Canada"
      echo ""
      echo "Status atual:"
      docker exec nordvpn_flight nordvpn status 2>/dev/null
    else
      echo "🌍 Conectando VPN em $2..."
      docker exec nordvpn_flight nordvpn c "$2"
      sleep 3
      echo ""
      echo "Status:"
      docker exec nordvpn_flight nordvpn status
    fi
    ;;
  
  ip)
    echo "🌐 Verificando IP atual..."
    echo ""
    echo "IP do container (via VPN):"
    docker exec flight_monitor_app curl -s https://api.ipify.org 2>/dev/null
    echo ""
    echo ""
    echo "IP do seu sistema (sem VPN):"
    curl -s https://api.ipify.org
    echo ""
    ;;
  
  clean)
    echo "🧹 Limpando dados..."
    docker exec flight_monitor_app rm -rf /app/data/* /app/logs/* 2>/dev/null
    echo "✅ Dados limpos"
    ;;
  
  remove)
    read -p "⚠️  Isso vai REMOVER todos os containers, rede e volumes. Confirma? (s/N): " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
      echo "🗑️  Removendo tudo..."
      docker stop nordvpn_flight flight_monitor_app nginx_flight_proxy 2>/dev/null
      docker rm nordvpn_flight flight_monitor_app nginx_flight_proxy 2>/dev/null
      docker network rm flight_vpn_network 2>/dev/null
      docker volume rm flight_data flight_logs 2>/dev/null
      docker rmi flight-monitor:latest 2>/dev/null
      echo "✅ Removido!"
    else
      echo "Cancelado"
    fi
    ;;
  
  update)
    echo "🔨 Atualizando app..."
    
    # Rebuild da imagem
    docker build -t flight-monitor:latest .
    
    # Restart do app
    docker stop flight_monitor_app
    docker rm flight_monitor_app
    
    docker run -d \
        --name flight_monitor_app \
        --network container:nordvpn_flight \
        -v flight_data:/app/data \
        -v flight_logs:/app/logs \
        -v "$(pwd)/app.py:/app/app.py:ro" \
        --restart unless-stopped \
        flight-monitor:latest
    
    echo "✅ App atualizado!"
    ;;
  
  shell)
    echo "🐚 Acessando shell do app..."
    docker exec -it flight_monitor_app /bin/bash
    ;;
  
  shell-vpn)
    echo "🐚 Acessando shell da VPN..."
    docker exec -it nordvpn_flight /bin/bash
    ;;
  
  *)
    echo "🛫 Monitor de Passagens Multi-País - Gerenciamento"
    echo ""
    echo "Comandos disponíveis:"
    echo ""
    echo "  Básico:"
    echo "    start          - Iniciar containers"
    echo "    stop           - Parar containers"
    echo "    restart        - Reiniciar containers"
    echo "    status         - Ver status e IP"
    echo ""
    echo "  Logs:"
    echo "    logs           - Ver logs do app"
    echo "    logs-vpn       - Ver logs da VPN"
    echo ""
    echo "  VPN:"
    echo "    vpn [PAÍS]     - Conectar VPN em país"
    echo "    ip             - Ver IP atual"
    echo ""
    echo "  Manutenção:"
    echo "    clean          - Limpar dados"
    echo "    update         - Atualizar app"
    echo "    remove         - Remover tudo"
    echo ""
    echo "  Avançado:"
    echo "    shell          - Shell do app"
    echo "    shell-vpn      - Shell da VPN"
    echo ""
    echo "🌐 Acesse: http://localhost:1007"
    echo ""
    ;;
esac
