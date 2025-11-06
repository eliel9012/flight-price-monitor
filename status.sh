#!/bin/bash
# Script para verificar status do sistema

echo "📊 Status do Flight Monitor"
echo "=========================================="
echo ""

# Verificar containers
echo "🐳 Containers:"
docker ps -a --filter "name=nordvpn" --filter "name=flight_monitor" --filter "name=nginx_proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🌐 Rede:"
docker network inspect vpn_network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "Rede não criada"

echo ""
echo "🔒 VPN:"
VPN_STATUS=$(docker exec nordvpn nordvpn status 2>/dev/null | grep Status || echo "Container não está rodando")
echo "$VPN_STATUS"

VPN_IP=$(docker exec nordvpn curl -s https://api.ipify.org 2>/dev/null)
if [ -n "$VPN_IP" ]; then
	echo "IP Externo: $VPN_IP"
	
	# Verificar localização
	LOCATION=$(docker exec nordvpn curl -s https://ipapi.co/$VPN_IP/json 2>/dev/null | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
	if [ -n "$LOCATION" ]; then
		echo "Localização: $LOCATION"
	fi
fi

echo ""
echo "💾 Uso de Disco:"
du -sh data logs 2>/dev/null || echo "Diretórios não criados"

echo ""
echo "📝 Últimas linhas do log da aplicação:"
docker logs --tail 5 flight_monitor 2>/dev/null || echo "Container não está rodando"

echo ""
echo "=========================================="
echo ""
echo "🌐 Acesso: http://localhost:8080"
echo ""