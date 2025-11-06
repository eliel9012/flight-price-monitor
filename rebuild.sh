#!/bin/bash
# Script para rebuild completo (quando atualizar código)

echo "🔄 Rebuild do Flight Monitor"
echo "=========================================="
echo ""

read -p "Isso vai parar e reconstruir tudo. Continuar? [s/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
	echo "Cancelado"
	exit 0
fi

# Parar tudo
echo "1️⃣ Parando containers..."
./stop.sh

# Remover imagem antiga
echo ""
echo "2️⃣ Removendo imagem antiga..."
docker rmi flight_monitor:latest 2>/dev/null || echo "Imagem não existe"

# Limpar cache do Docker (opcional)
read -p "Limpar cache do Docker? (recomendado se houver erros) [s/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
	echo "Limpando cache..."
	docker builder prune -f
	docker system prune -f
fi

# Rebuild
echo ""
echo "3️⃣ Reconstruindo imagem..."
docker build --no-cache -t flight_monitor:latest .

if [ $? -eq 0 ]; then
	echo ""
	echo "✅ Rebuild concluído!"
	echo ""
	read -p "Iniciar sistema agora? [S/n] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		./start.sh
	fi
else
	echo ""
	echo "❌ Erro no rebuild"
	exit 1
fi