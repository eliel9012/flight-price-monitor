#!/bin/bash
# Script para parar todos os containers

echo "🛑 Parando Flight Monitor..."

echo "Parando containers..."
docker stop nginx_proxy flight_monitor nordvpn 2>/dev/null

echo "Removendo containers..."
docker rm nginx_proxy flight_monitor nordvpn 2>/dev/null

echo ""
echo "✅ Sistema parado"
echo ""
echo "Para iniciar novamente:"
echo "  ./start.sh"
echo ""