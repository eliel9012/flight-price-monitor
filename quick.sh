#!/bin/bash

# Script de Uso Rápido - Monitor de Passagens com VPN

echo "🛫 Monitor de Passagens Aéreas Multi-País"
echo ""

case "$1" in
  start)
    echo "🚀 Iniciando sistema..."
    docker-compose up -d
    sleep 5
    echo "✅ Sistema rodando em http://localhost:8080"
    ;;
  
  stop)
    echo "⏸️  Parando sistema..."
    docker-compose down
    echo "✅ Sistema parado"
    ;;
  
  restart)
    echo "🔄 Reiniciando sistema..."
    docker-compose restart
    echo "✅ Sistema reiniciado"
    ;;
  
  logs)
    echo "📋 Mostrando logs (Ctrl+C para sair)..."
    docker-compose logs -f
    ;;
  
  status)
    echo "📊 Status dos containers:"
    docker-compose ps
    echo ""
    echo "🔒 Status da VPN:"
    docker exec nordvpn nordvpn status 2>/dev/null || echo "VPN não está rodando"
    ;;
  
  vpn)
    if [ -z "$2" ]; then
      echo "Países disponíveis:"
      echo "  Brazil, United_States, Portugal, Spain"
      echo "  United_Kingdom, Germany, France, Canada"
      echo ""
      echo "Uso: ./quick.sh vpn Brazil"
    else
      echo "🌍 Conectando VPN em $2..."
      docker exec nordvpn nordvpn c $2
    fi
    ;;
  
  ip)
    echo "🌐 IP atual:"
    docker exec flight_monitor curl -s https://api.ipify.org
    echo ""
    ;;
  
  update)
    echo "🔨 Reconstruindo containers..."
    docker-compose build
    docker-compose up -d
    echo "✅ Atualizado!"
    ;;
  
  clean)
    echo "🧹 Limpando dados antigos..."
    rm -rf data/* logs/*
    echo "✅ Dados limpos"
    ;;
  
  *)
    echo "Comandos disponíveis:"
    echo ""
    echo "  ./quick.sh start      - Iniciar sistema"
    echo "  ./quick.sh stop       - Parar sistema"
    echo "  ./quick.sh restart    - Reiniciar sistema"
    echo "  ./quick.sh logs       - Ver logs"
    echo "  ./quick.sh status     - Ver status"
    echo "  ./quick.sh vpn PAIS   - Conectar VPN manualmente"
    echo "  ./quick.sh ip         - Ver IP atual"
    echo "  ./quick.sh update     - Reconstruir containers"
    echo "  ./quick.sh clean      - Limpar dados antigos"
    echo ""
    echo "Acesse: http://localhost:8080"
    ;;
esac
