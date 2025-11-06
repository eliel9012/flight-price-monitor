#!/bin/bash
# Script para corrigir conflito de rede

echo "🔍 Verificando redes Docker existentes..."
echo ""

# Listar todas as redes
docker network ls

echo ""
echo "🔍 Verificando ranges de IP em uso..."
docker network inspect $(docker network ls -q) 2>/dev/null | grep -E "Subnet|Gateway" | head -20

echo ""
echo "=========================================="
echo "Vamos usar um range diferente: 172.20.0.0/16"
echo "=========================================="
echo ""

# Parar tudo
echo "Parando containers..."
docker stop flight_monitor nordvpn nginx_proxy 2>/dev/null
docker rm flight_monitor nordvpn nginx_proxy 2>/dev/null

# Remover rede antiga
echo "Removendo rede antiga..."
docker network rm flight_network 2>/dev/null

# Criar rede com novo range
echo "Criando rede com novo range..."
docker network create --subnet=172.20.0.0/16 --gateway=172.20.0.1 flight_network

if [ $? -eq 0 ]; then
    echo "✅ Rede criada com sucesso!"
    echo ""
    echo "Novo range: 172.20.0.0/16"
    echo "Gateway: 172.20.0.1"
    echo "NordVPN IP: 172.20.0.2"
    echo ""
else
    echo "❌ Erro ao criar rede"
    echo ""
    echo "Tentando outro range: 172.25.0.0/16"
    docker network create --subnet=172.25.0.0/16 --gateway=172.25.0.1 flight_network
    
    if [ $? -eq 0 ]; then
        echo "✅ Rede criada com sucesso!"
        echo ""
        echo "Novo range: 172.25.0.0/16"
        echo "Gateway: 172.25.0.1"
        echo "NordVPN IP: 172.25.0.2"
        echo ""
    else
        echo "❌ Erro ao criar rede"
        echo ""
        echo "Vamos listar ranges disponíveis..."
        echo ""
        echo "Redes em uso:"
        docker network inspect $(docker network ls -q) 2>/dev/null | grep "Subnet" | sort -u
    fi
fi
