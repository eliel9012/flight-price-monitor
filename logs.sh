#!/bin/bash
# Script para ver logs dos containers

echo "📝 Logs do Flight Monitor"
echo "=========================================="
echo ""
echo "Escolha uma opção:"
echo ""
echo "1) Ver todos os logs"
echo "2) Ver logs do NordVPN"
echo "3) Ver logs do Flight Monitor"
echo "4) Ver logs do Nginx"
echo "5) Ver logs em tempo real (todos)"
echo ""
read -p "Opção [1-5]: " opcao

case $opcao in
	1)
		echo ""
		echo "=== NORDVPN ==="
		docker logs --tail 50 nordvpn 2>/dev/null
		echo ""
		echo "=== FLIGHT MONITOR ==="
		docker logs --tail 50 flight_monitor 2>/dev/null
		echo ""
		echo "=== NGINX ==="
		docker logs --tail 50 nginx_proxy 2>/dev/null
		;;
	2)
		docker logs -f nordvpn
		;;
	3)
		docker logs -f flight_monitor
		;;
	4)
		docker logs -f nginx_proxy
		;;
	5)
		echo "Pressione Ctrl+C para sair"
		echo ""
		docker logs -f nordvpn 2>&1 | sed 's/^/[VPN] /' &
		docker logs -f flight_monitor 2>&1 | sed 's/^/[APP] /' &
		docker logs -f nginx_proxy 2>&1 | sed 's/^/[NGINX] /' &
		wait
		;;
	*)
		echo "Opção inválida"
		;;
esac