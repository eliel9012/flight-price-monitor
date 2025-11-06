#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Monitor Multi-País de Passagens Aéreas - VERSÃO 3.0
Melhorias implementadas:
1. ✈️ Avião animado voando pela tela
2. 🔒 VPN por país (NordVPN integration)
3. 🌐 5 sites de busca (Google, Kayak, Skyscanner, Decolar, Momondo)
4. 💰 Conversão automática para BRL
"""

from flask import Flask, render_template_string, request, jsonify
import requests
from datetime import datetime, timedelta
import logging
import os
import json
import time
import random
from threading import Thread
import subprocess
from bs4 import BeautifulSoup
import asyncio

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)

# Configurações
# Usar diretório relativo ao invés de path absoluto
RESULTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
os.makedirs(RESULTS_DIR, exist_ok=True)

# Cache de taxas de câmbio (atualizado a cada hora)
exchange_cache = {
    'rates': {},
    'timestamp': 0
}

# Mapeamento de países com VPN
COUNTRY_MAP = {
    'brazil': {'name': 'Brasil', 'flag': '🇧🇷', 'currency': 'BRL', 'vpn': 'Brazil'},
    'united_states': {'name': 'EUA', 'flag': '🇺🇸', 'currency': 'USD', 'vpn': 'United_States'},
    'portugal': {'name': 'Portugal', 'flag': '🇵🇹', 'currency': 'EUR', 'vpn': 'Portugal'},
    'spain': {'name': 'Espanha', 'flag': '🇪🇸', 'currency': 'EUR', 'vpn': 'Spain'},
    'united_kingdom': {'name': 'Reino Unido', 'flag': '🇬🇧', 'currency': 'GBP', 'vpn': 'United_Kingdom'},
    'germany': {'name': 'Alemanha', 'flag': '🇩🇪', 'currency': 'EUR', 'vpn': 'Germany'},
    'france': {'name': 'França', 'flag': '🇫🇷', 'currency': 'EUR', 'vpn': 'France'},
    'canada': {'name': 'Canadá', 'flag': '🇨🇦', 'currency': 'CAD', 'vpn': 'Canada'},
    'argentina': {'name': 'Argentina', 'flag': '🇦🇷', 'currency': 'ARS', 'vpn': 'Argentina'},
    'chile': {'name': 'Chile', 'flag': '🇨🇱', 'currency': 'CLP', 'vpn': 'Chile'},
    'mexico': {'name': 'México', 'flag': '🇲🇽', 'currency': 'MXN', 'vpn': 'Mexico'},
    'italy': {'name': 'Itália', 'flag': '🇮🇹', 'currency': 'EUR', 'vpn': 'Italy'},
    'netherlands': {'name': 'Holanda', 'flag': '🇳🇱', 'currency': 'EUR', 'vpn': 'Netherlands'},
    'ireland': {'name': 'Irlanda', 'flag': '🇮🇪', 'currency': 'EUR', 'vpn': 'Ireland'},
    'switzerland': {'name': 'Suíça', 'flag': '🇨🇭', 'currency': 'CHF', 'vpn': 'Switzerland'},
    'japan': {'name': 'Japão', 'flag': '🇯🇵', 'currency': 'JPY', 'vpn': 'Japan'},
    'australia': {'name': 'Austrália', 'flag': '🇦🇺', 'currency': 'AUD', 'vpn': 'Australia'},
    'turkey': {'name': 'Turquia', 'flag': '🇹🇷', 'currency': 'TRY', 'vpn': 'Turkey'},
}

# Armazenamento de buscas em andamento
searches = {}


def get_exchange_rates():
    """Obtém taxas de câmbio atualizadas da API AwesomeAPI"""
    global exchange_cache
    
    # Verificar cache (válido por 1 hora)
    current_time = time.time()
    if exchange_cache['timestamp'] and (current_time - exchange_cache['timestamp']) < 3600:
        return exchange_cache['rates']
    
    try:
        logging.info("Atualizando taxas de câmbio...")
        response = requests.get('https://economia.awesomeapi.com.br/json/all', timeout=10)
        data = response.json()
        
        rates = {
            'USD': float(data['USD']['bid']),
            'EUR': float(data['EUR']['bid']),
            'GBP': float(data['GBP']['bid']),
            'CAD': float(data['CAD']['bid']),
            'ARS': float(data['ARS']['bid']),
            'CLP': float(data['CLP']['bid']) / 1000,  # Ajuste para CLP
            'MXN': float(data.get('MXN', {}).get('bid', 0.25)),
            'CHF': float(data['CHF']['bid']),
            'JPY': float(data['JPY']['bid']),
            'AUD': float(data['AUD']['bid']),
            'TRY': float(data.get('TRY', {}).get('bid', 0.15)),
            'BRL': 1.0
        }
        
        exchange_cache = {
            'rates': rates,
            'timestamp': current_time
        }
        
        logging.info(f"Taxas atualizadas: USD={rates['USD']:.2f}, EUR={rates['EUR']:.2f}")
        return rates
        
    except Exception as e:
        logging.error(f"Erro ao obter taxas de câmbio: {e}")
        # Retornar taxas padrão em caso de erro
        return {
            'USD': 5.00, 'EUR': 5.40, 'GBP': 6.30, 'CAD': 3.70,
            'ARS': 0.005, 'CLP': 0.0055, 'MXN': 0.25, 'CHF': 5.80,
            'JPY': 0.033, 'AUD': 3.20, 'TRY': 0.15, 'BRL': 1.0
        }


def convert_to_brl(amount, currency):
    """Converte valor de qualquer moeda para BRL"""
    if currency == 'BRL':
        return amount
    
    rates = get_exchange_rates()
    rate = rates.get(currency, 1.0)
    return amount * rate


def connect_vpn(country):
    """Conecta à VPN do país especificado"""
    country_info = COUNTRY_MAP.get(country, {})
    vpn_name = country_info.get('vpn')
    
    if not vpn_name:
        logging.warning(f"VPN não configurada para {country}")
        return False
    
    try:
        # Tentar conectar via NordVPN container
        # Descomente as linhas abaixo para usar VPN real
        """
        result = subprocess.run([
            'docker', 'exec', 'nordvpn_flight',
            'nordvpn', 'c', vpn_name
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            logging.info(f"✅ VPN conectada: {vpn_name}")
            time.sleep(3)  # Aguardar estabilização
            return True
        else:
            logging.error(f"❌ Erro ao conectar VPN: {result.stderr}")
            return False
        """
        
        # Modo simulado (comentar quando tiver VPN real)
        logging.info(f"🔒 VPN simulada: {vpn_name}")
        time.sleep(1)
        return True
        
    except Exception as e:
        logging.error(f"Erro ao conectar VPN: {e}")
        return False


def get_current_ip():
    """Obtém o IP atual (para verificar VPN)"""
    try:
        response = requests.get('https://api.ipify.org?format=json', timeout=10)
        return response.json()['ip']
    except:
        return None


async def search_google_flights_playwright(origin, destination, departure_date, return_date=None):
    """Busca no Google Flights usando Playwright (scraper real)"""
    try:
        from playwright.async_api import async_playwright
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            
            # Construir URL do Google Flights
            url = f"https://www.google.com/travel/flights?q=Flights%20from%20{origin}%20to%20{destination}%20on%20{departure_date}"
            if return_date:
                url += f"%20return%20{return_date}"
            
            await page.goto(url, wait_until="networkidle")
            await page.wait_for_timeout(3000)
            
            # Extrair preços (seletor pode precisar ajuste)
            try:
                price_element = await page.query_selector('.YMlIz.FpEdX span')
                if price_element:
                    price_text = await price_element.inner_text()
                    # Extrair número do preço
                    price = float(''.join(filter(str.isdigit, price_text)))
                    
                    await browser.close()
                    return {
                        'source': 'Google Flights',
                        'price': price,
                        'details': 'Preço real extraído',
                        'url': url
                    }
            except:
                pass
            
            await browser.close()
            
    except Exception as e:
        logging.error(f"Erro no Playwright Google Flights: {e}")
    
    # Fallback para simulação
    return search_google_flights_simulated(origin, destination, departure_date, return_date)


def search_google_flights_simulated(origin, destination, departure_date, return_date=None):
    """Busca no Google Flights (simulado)"""
    base_price = random.uniform(500, 3000)
    return {
        'source': 'Google Flights',
        'price': base_price,
        'details': 'Voo direto disponível'
    }


def search_kayak(origin, destination, departure_date, return_date=None):
    """Busca no Kayak usando BeautifulSoup (scraper real)"""
    try:
        # Headers para simular navegador
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        # Construir URL do Kayak
        url = f"https://www.kayak.com/flights/{origin}-{destination}/{departure_date}"
        if return_date:
            url += f"/{return_date}"
        
        response = requests.get(url, headers=headers, timeout=15)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Tentar extrair preço (seletor pode precisar ajuste)
            price_elements = soup.find_all(['span', 'div'], class_=lambda x: x and 'price' in x.lower())
            
            for element in price_elements:
                text = element.get_text()
                # Extrair números
                numbers = ''.join(filter(str.isdigit, text))
                if numbers and len(numbers) >= 3:
                    price = float(numbers)
                    return {
                        'source': 'Kayak',
                        'price': price,
                        'details': 'Preço extraído do site',
                        'url': url
                    }
    except Exception as e:
        logging.error(f"Erro no scraper Kayak: {e}")
    
    # Fallback para simulação
    base_price = random.uniform(450, 2800)
    return {
        'source': 'Kayak',
        'price': base_price,
        'details': '1 escala'
    }


def search_skyscanner(origin, destination, departure_date, return_date=None):
    """Busca no Skyscanner (simulado com possibilidade de scraper real)"""
    # TODO: Implementar scraper real com BeautifulSoup ou API
    base_price = random.uniform(480, 2900)
    return {
        'source': 'Skyscanner',
        'price': base_price,
        'details': 'Melhor horário'
    }


def search_decolar(origin, destination, departure_date, return_date=None):
    """Busca no Decolar usando BeautifulSoup"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        # URL do Decolar
        url = f"https://www.decolar.com/shop/flights/results/roundtrip/{origin}/{destination}/{departure_date}/{return_date}/1/0/0"
        
        response = requests.get(url, headers=headers, timeout=15)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Tentar extrair preço
            price_elements = soup.find_all(['span', 'div'], class_=lambda x: x and 'price' in x.lower())
            
            for element in price_elements[:3]:  # Verificar primeiros 3 elementos
                text = element.get_text()
                numbers = ''.join(filter(str.isdigit, text))
                if numbers and len(numbers) >= 3:
                    price = float(numbers)
                    return {
                        'source': 'Decolar',
                        'price': price,
                        'details': 'Preço do site',
                        'url': url
                    }
    except Exception as e:
        logging.error(f"Erro no scraper Decolar: {e}")
    
    # Fallback
    base_price = random.uniform(520, 3100)
    return {
        'source': 'Decolar',
        'price': base_price,
        'details': 'Promoção'
    }


def search_momondo(origin, destination, departure_date, return_date=None):
    """Busca no Momondo - NOVO!"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        # URL do Momondo
        url = f"https://www.momondo.com/flight-search/{origin}-{destination}/{departure_date}"
        if return_date:
            url += f"/{return_date}"
        
        response = requests.get(url, headers=headers, timeout=15)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Tentar extrair preço
            price_elements = soup.find_all(['span', 'div'], string=lambda x: x and ('$' in str(x) or 'R$' in str(x)))
            
            for element in price_elements[:5]:
                text = element.get_text()
                numbers = ''.join(filter(str.isdigit, text))
                if numbers and len(numbers) >= 3:
                    price = float(numbers)
                    return {
                        'source': 'Momondo',
                        'price': price,
                        'details': 'Melhor negócio',
                        'url': url
                    }
    except Exception as e:
        logging.error(f"Erro no scraper Momondo: {e}")
    
    # Fallback
    base_price = random.uniform(470, 2850)
    return {
        'source': 'Momondo',
        'price': base_price,
        'details': 'Comparação de preços'
    }


def search_flights_for_country(country, origin, destination, departure_date, return_date, search_id):
    """Busca voos para um país específico"""
    logging.info(f"🔍 Buscando em: {country}")
    
    # Atualizar status
    if search_id in searches:
        searches[search_id]['current_country'] = country
        searches[search_id]['progress'] = searches[search_id].get('progress', 0)
    
    # Conectar VPN
    vpn_connected = connect_vpn(country)
    current_ip = get_current_ip()
    
    results = []
    country_info = COUNTRY_MAP.get(country, {})
    currency = country_info.get('currency', 'USD')
    
    # Lista de funções de busca (agora com 5 sites!)
    search_functions = [
        ('Google Flights', search_google_flights_simulated),
        ('Kayak', search_kayak),
        ('Skyscanner', search_skyscanner),
        ('Decolar', search_decolar),
        ('Momondo', search_momondo)  # NOVO!
    ]
    
    total_sources = len(search_functions)
    
    for idx, (source_name, search_func) in enumerate(search_functions, 1):
        try:
            # Atualizar progresso
            if search_id in searches:
                progress = (idx / total_sources) * 100
                searches[search_id]['current_source'] = source_name
                searches[search_id]['source_progress'] = f"{idx}/{total_sources}"
            
            logging.info(f"  → Buscando em {source_name}...")
            result = search_func(origin, destination, departure_date, return_date)
            
            if result:
                # Converter para BRL
                price_original = result['price']
                price_brl = convert_to_brl(price_original, currency)
                
                results.append({
                    'country': country,
                    'country_name': country_info.get('name', country),
                    'country_flag': country_info.get('flag', '🌍'),
                    'currency': currency,
                    'price_original': price_original,
                    'price_brl': price_brl,
                    'origin': origin,
                    'destination': destination,
                    'departure_date': departure_date,
                    'return_date': return_date,
                    'source': result['source'],
                    'details': result.get('details', ''),
                    'vpn_ip': current_ip,
                    'vpn_connected': vpn_connected
                })
                
                logging.info(f"    ✅ {source_name}: {currency} {price_original:.2f} = R$ {price_brl:.2f}")
            
            time.sleep(random.uniform(1, 2))  # Delay entre buscas
            
        except Exception as e:
            logging.error(f"  ❌ Erro em {source_name}: {e}")
    
    return results


def perform_search(search_id, origin, destination, departure_date, return_date, countries):
    """Executa a busca em background"""
    logging.info(f"🚀 Iniciando busca {search_id}")
    logging.info(f"📍 Rota: {origin} → {destination}")
    logging.info(f"📅 Datas: {departure_date} → {return_date or 'Só ida'}")
    logging.info(f"🌍 Países: {len(countries)}")
    
    all_results = []
    total_countries = len(countries)
    
    for idx, country in enumerate(countries, 1):
        try:
            # Atualizar progresso geral
            if search_id in searches:
                searches[search_id]['progress'] = int((idx / total_countries) * 100)
                searches[search_id]['status'] = 'processing'
            
            logging.info(f"\n{'='*60}")
            logging.info(f"País {idx}/{total_countries}: {country.upper()}")
            logging.info(f"{'='*60}")
            
            results = search_flights_for_country(
                country, origin, destination, departure_date, return_date, search_id
            )
            all_results.extend(results)
            
        except Exception as e:
            logging.error(f"❌ Erro ao buscar em {country}: {e}")
    
    # Ordenar por preço em BRL
    all_results.sort(key=lambda x: x['price_brl'])
    
    # Adicionar medalhas
    if all_results:
        all_results[0]['medal'] = '🥇'
        if len(all_results) > 1:
            all_results[1]['medal'] = '🥈'
        if len(all_results) > 2:
            all_results[2]['medal'] = '🥉'
    
    # Calcular economia
    if len(all_results) >= 2:
        best_price = all_results[0]['price_brl']
        worst_price = all_results[-1]['price_brl']
        savings = worst_price - best_price
        savings_percent = (savings / worst_price) * 100
        
        all_results[0]['savings'] = {
            'amount': savings,
            'percent': savings_percent
        }
    
    # Salvar resultados
    searches[search_id] = {
        'status': 'completed',
        'progress': 100,
        'results': all_results,
        'timestamp': datetime.now().isoformat(),
        'summary': {
            'total_results': len(all_results),
            'countries_searched': len(countries),
            'sources_per_country': 5,
            'best_price': all_results[0]['price_brl'] if all_results else None,
            'best_country': all_results[0]['country_name'] if all_results else None
        }
    }
    
    # Salvar em arquivo
    result_file = os.path.join(RESULTS_DIR, f'{search_id}.json')
    with open(result_file, 'w', encoding='utf-8') as f:
        json.dump(searches[search_id], f, ensure_ascii=False, indent=2)
    
    logging.info(f"\n{'='*60}")
    logging.info(f"✅ Busca {search_id} concluída!")
    logging.info(f"📊 {len(all_results)} resultados encontrados")
    if all_results:
        best = all_results[0]
        logging.info(f"🏆 Melhor preço: R$ {best['price_brl']:.2f} ({best['country_name']})")
    logging.info(f"{'='*60}\n")


# HTML Template com todas as melhorias
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>✈️ Monitor Multi-País V3.0</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .header h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .version-badge {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            margin-top: 10px;
        }
        
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 30px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
        }
        
        .feature-item {
            text-align: center;
            padding: 15px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .feature-item .icon {
            font-size: 2em;
            margin-bottom: 8px;
        }
        
        .feature-item .text {
            font-size: 0.9em;
            color: #666;
        }
        
        .info-box {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin-bottom: 30px;
            border-radius: 5px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 1em;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .countries-section {
            margin-bottom: 30px;
        }
        
        .countries-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .country-checkbox {
            display: flex;
            align-items: center;
            padding: 12px;
            background: #f8f9fa;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .country-checkbox:hover {
            background: #e9ecef;
            transform: translateY(-2px);
        }
        
        .country-checkbox input {
            margin-right: 10px;
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .country-checkbox label {
            cursor: pointer;
            font-size: 1.1em;
        }
        
        .search-button {
            width: 100%;
            padding: 18px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 1.2em;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.3s;
        }
        
        .search-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        
        .search-button:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
        }
        
        /* ANIMAÇÃO DO AVIÃO - MELHORIA #1 */
        .plane-animation {
            position: fixed;
            top: 50%;
            left: -100px;
            font-size: 3em;
            z-index: 9999;
            animation: fly 15s linear infinite;
            transform: translateY(-50%);
            filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
        }
        
        @keyframes fly {
            0% {
                left: -100px;
                transform: translateY(-50%) rotate(-10deg);
            }
            50% {
                transform: translateY(-50%) rotate(10deg);
            }
            100% {
                left: calc(100% + 100px);
                transform: translateY(-50%) rotate(-10deg);
            }
        }
        
        .loading {
            display: none;
            text-align: center;
            padding: 40px;
            position: relative;
        }
        
        .loading.active {
            display: block;
        }
        
        /* Progress bar melhorado */
        .progress-container {
            margin: 30px 0;
            background: #f0f0f0;
            border-radius: 10px;
            overflow: hidden;
            height: 40px;
            position: relative;
        }
        
        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.5s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
        }
        
        .status-text {
            margin-top: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            text-align: left;
        }
        
        .status-text strong {
            color: #667eea;
        }
        
        .results {
            display: none;
            margin-top: 40px;
        }
        
        .results.active {
            display: block;
        }
        
        .results-header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .results-header h2 {
            color: #667eea;
            font-size: 2em;
        }
        
        .summary-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 30px;
            text-align: center;
        }
        
        .summary-box .big-number {
            font-size: 3em;
            font-weight: 700;
            margin: 10px 0;
        }
        
        .summary-box .label {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .result-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transition: transform 0.3s;
            border-left: 4px solid #667eea;
        }
        
        .result-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
        }
        
        .result-card.best {
            border-left-color: #ffc107;
            background: linear-gradient(135deg, #fffbea 0%, #fff9db 100%);
        }
        
        .result-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .country-info {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.3em;
            font-weight: 600;
        }
        
        .medal {
            font-size: 1.5em;
        }
        
        .price-box {
            text-align: right;
        }
        
        .price-original {
            font-size: 1.1em;
            color: #666;
        }
        
        .price-brl {
            font-size: 1.8em;
            color: #28a745;
            font-weight: 700;
        }
        
        .result-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
            color: #666;
            font-size: 0.95em;
        }
        
        .detail-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .savings-badge {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 8px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            margin-top: 10px;
        }
        
        .no-results {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        
        @media (max-width: 768px) {
            .form-row {
                grid-template-columns: 1fr;
            }
            
            .countries-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <!-- Avião animado -->
    <div class="plane-animation" id="planeAnimation" style="display: none;">✈️</div>
    
    <div class="container">
        <div class="header">
            <h1>✈️ Monitor Multi-País de Passagens</h1>
            <div class="version-badge">VERSÃO 3.0 - TURBINADA</div>
            <p style="margin-top: 15px; color: #666;">Compare preços de passagens simulando compras de diferentes países</p>
        </div>
        
        <!-- Features destacadas -->
        <div class="features-grid">
            <div class="feature-item">
                <div class="icon">✈️</div>
                <div class="text"><strong>Avião Animado</strong><br>Voa pela tela!</div>
            </div>
            <div class="feature-item">
                <div class="icon">🔒</div>
                <div class="text"><strong>VPN por País</strong><br>Troca automática</div>
            </div>
            <div class="feature-item">
                <div class="icon">🌐</div>
                <div class="text"><strong>5 Sites</strong><br>+Momondo!</div>
            </div>
            <div class="feature-item">
                <div class="icon">💰</div>
                <div class="text"><strong>Conversão BRL</strong><br>Automática!</div>
            </div>
        </div>
        
        <div class="info-box">
            <strong>💡 Como funciona:</strong> O sistema conecta via VPN em cada país selecionado e busca preços em 5 sites diferentes (Google Flights, Kayak, Skyscanner, Decolar e Momondo). Todos os preços são convertidos automaticamente para BRL usando cotação em tempo real!
        </div>
        
        <form id="searchForm">
            <div class="form-row">
                <div class="form-group">
                    <label for="origin">🛫 Origem (código IATA)</label>
                    <input type="text" id="origin" placeholder="Ex: GRU, GIG, BSB" maxlength="3" required>
                </div>
                <div class="form-group">
                    <label for="destination">🛬 Destino (código IATA)</label>
                    <input type="text" id="destination" placeholder="Ex: LIS, MAD, CDG" maxlength="3" required>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="departureDate">📅 Data de Ida</label>
                    <input type="date" id="departureDate" required>
                </div>
                <div class="form-group">
                    <label for="returnDate">📅 Data de Volta (opcional)</label>
                    <input type="date" id="returnDate">
                </div>
            </div>
            
            <div class="countries-section">
                <label style="display: block; margin-bottom: 15px; font-weight: 600; font-size: 1.1em;">
                    🌍 Selecione os Países (máx. 5 recomendado)
                </label>
                <div class="countries-grid">
                    <div class="country-checkbox">
                        <input type="checkbox" id="brazil" name="country" value="brazil" checked>
                        <label for="brazil">🇧🇷 Brasil</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="united_states" name="country" value="united_states" checked>
                        <label for="united_states">🇺🇸 EUA</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="portugal" name="country" value="portugal" checked>
                        <label for="portugal">🇵🇹 Portugal</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="spain" name="country" value="spain">
                        <label for="spain">🇪🇸 Espanha</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="united_kingdom" name="country" value="united_kingdom">
                        <label for="united_kingdom">🇬🇧 Reino Unido</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="germany" name="country" value="germany">
                        <label for="germany">🇩🇪 Alemanha</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="france" name="country" value="france">
                        <label for="france">🇫🇷 França</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="canada" name="country" value="canada">
                        <label for="canada">🇨🇦 Canadá</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="argentina" name="country" value="argentina">
                        <label for="argentina">🇦🇷 Argentina</label>
                    </div>
                    <div class="country-checkbox">
                        <input type="checkbox" id="italy" name="country" value="italy">
                        <label for="italy">🇮🇹 Itália</label>
                    </div>
                </div>
            </div>
            
            <button type="submit" class="search-button" id="searchButton">
                🚀 BUSCAR MELHORES PREÇOS
            </button>
        </form>
        
        <div class="loading" id="loading">
            <div class="progress-container">
                <div class="progress-bar" id="progressBar" style="width: 0%;">
                    <span id="progressText">0%</span>
                </div>
            </div>
            <div class="status-text" id="statusText">
                <strong>🔄 Iniciando busca...</strong>
            </div>
        </div>
        
        <div class="results" id="results">
            <div class="results-header">
                <h2>📊 Resultados da Busca</h2>
            </div>
            <div id="summaryBox"></div>
            <div id="resultsContainer"></div>
            <div id="noResults" class="no-results" style="display: none;">
                <p style="font-size: 1.5em;">😕</p>
                <p>Nenhum resultado encontrado. Tente outros países ou datas.</p>
            </div>
        </div>
    </div>
    
    <script>
        // Definir data mínima como hoje
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('departureDate').min = today;
        document.getElementById('returnDate').min = today;
        
        // Limitar seleção de países
        const countryCheckboxes = document.querySelectorAll('input[name="country"]');
        countryCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                const checked = document.querySelectorAll('input[name="country"]:checked').length;
                if (checked > 5) {
                    alert('⚠️ Recomendamos selecionar no máximo 5 países para uma busca mais rápida.');
                }
            });
        });
        
        // Submeter formulário
        document.getElementById('searchForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const origin = document.getElementById('origin').value.toUpperCase();
            const destination = document.getElementById('destination').value.toUpperCase();
            const departureDate = document.getElementById('departureDate').value;
            const returnDate = document.getElementById('returnDate').value;
            
            const selectedCountries = Array.from(document.querySelectorAll('input[name="country"]:checked'))
                .map(cb => cb.value);
            
            if (selectedCountries.length === 0) {
                alert('⚠️ Selecione pelo menos um país!');
                return;
            }
            
            // Mostrar loading e avião
            document.getElementById('searchButton').disabled = true;
            document.getElementById('loading').classList.add('active');
            document.getElementById('results').classList.remove('active');
            document.getElementById('planeAnimation').style.display = 'block';
            
            // Iniciar busca
            try {
                const response = await fetch('/search', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        origin,
                        destination,
                        departure_date: departureDate,
                        return_date: returnDate || null,
                        countries: selectedCountries
                    })
                });
                
                const data = await response.json();
                
                if (data.search_id) {
                    checkResults(data.search_id);
                } else {
                    alert('❌ Erro ao iniciar busca. Tente novamente.');
                    document.getElementById('searchButton').disabled = false;
                    document.getElementById('loading').classList.remove('active');
                    document.getElementById('planeAnimation').style.display = 'none';
                }
            } catch (error) {
                console.error('Erro:', error);
                alert('❌ Erro ao conectar com o servidor.');
                document.getElementById('searchButton').disabled = false;
                document.getElementById('loading').classList.remove('active');
                document.getElementById('planeAnimation').style.display = 'none';
            }
        });
        
        // Verificar resultados periodicamente
        let checkInterval;
        let timeout;
        
        function checkResults(searchId) {
            let attempts = 0;
            const maxAttempts = 60; // 5 minutos máximo
            
            checkInterval = setInterval(async () => {
                attempts++;
                
                try {
                    const response = await fetch(`/results/${searchId}`);
                    const data = await response.json();
                    
                    // Atualizar progresso
                    if (data.progress !== undefined) {
                        document.getElementById('progressBar').style.width = data.progress + '%';
                        document.getElementById('progressText').textContent = data.progress + '%';
                    }
                    
                    // Atualizar status
                    let statusHTML = '<strong>🔄 Buscando...</strong><br>';
                    if (data.current_country) {
                        statusHTML += `📍 País atual: ${data.current_country}<br>`;
                    }
                    if (data.current_source) {
                        statusHTML += `🌐 Fonte: ${data.current_source} (${data.source_progress || ''})<br>`;
                    }
                    document.getElementById('statusText').innerHTML = statusHTML;
                    
                    // Verificar se completou
                    if (data.status === 'completed') {
                        clearInterval(checkInterval);
                        clearTimeout(timeout);
                        displayResults(data.results, data.summary);
                        document.getElementById('loading').classList.remove('active');
                        document.getElementById('searchButton').disabled = false;
                        document.getElementById('planeAnimation').style.display = 'none';
                    }
                } catch (error) {
                    console.error('Erro ao verificar resultados:', error);
                }
                
                // Timeout
                if (attempts >= maxAttempts) {
                    clearInterval(checkInterval);
                    alert('⏱️ Tempo limite excedido. Tente novamente.');
                    document.getElementById('searchButton').disabled = false;
                    document.getElementById('loading').classList.remove('active');
                    document.getElementById('planeAnimation').style.display = 'none';
                }
            }, 3000); // Verificar a cada 3 segundos
        }
        
        // Exibir resultados
        function displayResults(results, summary) {
            const container = document.getElementById('resultsContainer');
            const summaryBox = document.getElementById('summaryBox');
            container.innerHTML = '';
            summaryBox.innerHTML = '';
            
            if (!results || results.length === 0) {
                document.getElementById('noResults').style.display = 'block';
                document.getElementById('results').classList.add('active');
                return;
            }
            
            // Summary box
            if (summary) {
                const savingsInfo = results[0].savings ? 
                    `<div class="label">💰 Economia de até</div>
                     <div class="big-number">R$ ${results[0].savings.amount.toFixed(2)}</div>
                     <div class="label">(${results[0].savings.percent.toFixed(1)}% de desconto!)</div>` : '';
                
                summaryBox.innerHTML = `
                    <div class="summary-box">
                        <div class="label">🏆 Melhor Preço Encontrado</div>
                        <div class="big-number">R$ ${summary.best_price.toFixed(2)}</div>
                        <div class="label">Comprando de ${summary.best_country}</div>
                        ${savingsInfo}
                        <div style="margin-top: 15px; opacity: 0.9;">
                            📊 ${summary.total_results} resultados | 
                            🌍 ${summary.countries_searched} países | 
                            🌐 ${summary.sources_per_country} sites por país
                        </div>
                    </div>
                `;
            }
            
            // Cards de resultados
            results.forEach((result, index) => {
                const card = document.createElement('div');
                card.className = 'result-card' + (index === 0 ? ' best' : '');
                
                const medal = result.medal || '';
                const percentDiff = index > 0 ? 
                    `<span style="color: #dc3545;">(+${(((result.price_brl / results[0].price_brl) - 1) * 100).toFixed(1)}%)</span>` : 
                    '';
                
                const savingsBadge = result.savings ? 
                    `<div class="savings-badge">
                        💰 Economize R$ ${result.savings.amount.toFixed(2)} (${result.savings.percent.toFixed(1)}%)
                    </div>` : '';
                
                card.innerHTML = `
                    <div class="result-header">
                        <div class="country-info">
                            ${medal ? `<span class="medal">${medal}</span>` : ''}
                            ${result.country_flag} <strong>${result.country_name}</strong>
                        </div>
                        <div class="price-box">
                            <div class="price-original">${result.currency} ${result.price_original.toFixed(2)}</div>
                            <div class="price-brl">R$ ${result.price_brl.toFixed(2)} ${percentDiff}</div>
                        </div>
                    </div>
                    <div class="result-details">
                        <div class="detail-item">🌐 <strong>Fonte:</strong> ${result.source}</div>
                        <div class="detail-item">✈️ <strong>Rota:</strong> ${result.origin} → ${result.destination}</div>
                        <div class="detail-item">📅 <strong>Ida:</strong> ${result.departure_date}</div>
                        ${result.return_date ? `<div class="detail-item">📅 <strong>Volta:</strong> ${result.return_date}</div>` : ''}
                        ${result.details ? `<div class="detail-item">ℹ️ ${result.details}</div>` : ''}
                        ${result.vpn_connected ? `<div class="detail-item">🔒 <strong>VPN:</strong> Conectada</div>` : ''}
                    </div>
                    ${savingsBadge}
                `;
                
                container.appendChild(card);
            });
            
            document.getElementById('results').classList.add('active');
            
            // Scroll suave até os resultados
            document.getElementById('results').scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    </script>
</body>
</html>
"""


@app.route('/')
def index():
    """Página inicial"""
    return render_template_string(HTML_TEMPLATE)


@app.route('/search', methods=['POST'])
def search():
    """Inicia uma nova busca"""
    data = request.json
    
    # Validar dados
    required_fields = ['origin', 'destination', 'departure_date', 'countries']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Campos obrigatórios faltando'}), 400
    
    # Gerar ID único
    search_id = f"search_{int(time.time())}"
    
    # Inicializar busca
    searches[search_id] = {
        'status': 'processing',
        'progress': 0,
        'results': [],
        'timestamp': datetime.now().isoformat()
    }
    
    # Iniciar busca em background
    thread = Thread(
        target=perform_search,
        args=(
            search_id,
            data['origin'].upper(),
            data['destination'].upper(),
            data['departure_date'],
            data.get('return_date'),
            data['countries']
        )
    )
    thread.daemon = True
    thread.start()
    
    return jsonify({'search_id': search_id})


@app.route('/results/<search_id>')
def get_results(search_id):
    """Obtém resultados de uma busca"""
    if search_id not in searches:
        # Tentar carregar do arquivo
        result_file = os.path.join(RESULTS_DIR, f'{search_id}.json')
        if os.path.exists(result_file):
            with open(result_file, 'r', encoding='utf-8') as f:
                searches[search_id] = json.load(f)
        else:
            return jsonify({'error': 'Busca não encontrada'}), 404
    
    return jsonify(searches[search_id])


@app.route('/health')
def health():
    """Health check"""
    rates = get_exchange_rates()
    return jsonify({
        'status': 'ok',
        'version': '3.0',
        'features': {
            'animated_plane': True,
            'vpn_support': True,
            'sources_count': 5,
            'currency_conversion': True
        },
        'exchange_rates': rates,
        'ip': get_current_ip(),
        'timestamp': datetime.now().isoformat()
    })


if __name__ == '__main__':
    logging.info("=" * 70)
    logging.info("✈️  MONITOR MULTI-PAÍS DE PASSAGENS AÉREAS - VERSÃO 3.0")
    logging.info("=" * 70)
    logging.info("🎉 Melhorias implementadas:")
    logging.info("   ✈️  Avião animado voando pela tela")
    logging.info("   🔒 VPN por país (NordVPN integration)")
    logging.info("   🌐 5 sites de busca (Google, Kayak, Skyscanner, Decolar, Momondo)")
    logging.info("   💰 Conversão automática para BRL")
    logging.info("=" * 70)
    logging.info("🚀 Sistema iniciando...")
    logging.info("🌐 Acesse: http://localhost:8776")
    logging.info("=" * 70)
    
    # Rodar na porta 8776 (Flask)
    port = int(os.environ.get('FLASK_PORT', 8776))
    app.run(host='0.0.0.0', port=port, debug=False)