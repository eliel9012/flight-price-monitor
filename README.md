# Flight Price Monitor Multi-Country

## English

Open-source web application for comparing airfare across multiple countries by simulating different purchase markets and normalizing prices to BRL.

### Overview

The project is built to answer a practical question: if airlines and travel websites price differently by region, where is the cheapest market to buy the same trip?

It combines:

- country-based search simulation
- optional VPN switching
- multi-site scraping
- BRL normalization
- ranking and savings estimation

### Main Features

- multi-country comparison workflow
- support for major travel websites
- automated exchange-rate conversion
- savings calculation and best-market ranking
- responsive web interface
- background service mode with systemd support
- detailed logs and long-running operation on Linux or Raspberry Pi

### Quick Start

Requirements:

- Python 3.8+
- Linux or Raspberry Pi environment
- internet access

Basic setup:

```bash
git clone https://github.com/eliel9012/flight-price-monitor.git
cd flight-price-monitor
chmod +x install_raspberry.sh setup_service.sh
sudo ./install_raspberry.sh
sudo ./setup_service.sh
```

Then open:

```text
http://localhost:8776
```

### Typical Usage

1. enter origin and destination
2. choose departure and return dates
3. select a set of countries to compare
4. start the search
5. compare normalized results and estimated savings

### Service Management

```bash
sudo systemctl status flight-monitor
sudo systemctl restart flight-monitor
sudo journalctl -u flight-monitor -f
```

### Supported Countries

The app is set up to compare multiple markets including Brazil, United States, Portugal, Spain, United Kingdom, Germany, France, Canada, Argentina, Chile, Mexico, Italy, Netherlands, Ireland, Switzerland, Japan, Australia, and Turkey.

### Notes

- VPN integration is optional but useful when testing truly different market conditions
- some scrapers may require browser automation tooling such as Playwright
- this project is designed for continuous use on Linux-like hosts

## Português

Aplicação web open source para comparar preços de passagens aéreas entre múltiplos países, simulando diferentes mercados de compra e normalizando os valores para BRL.

### Visão Geral

O projeto foi feito para responder a uma pergunta prática: se companhias aéreas e sites de viagem mudam o preço por região, em qual mercado sai mais barato comprar a mesma viagem?

Ele combina:

- simulação de busca por país
- troca opcional de VPN
- scraping em múltiplos sites
- normalização para BRL
- ranking e estimativa de economia

### Funcionalidades Principais

- fluxo de comparação entre vários países
- suporte a grandes sites de viagem
- conversão automática por câmbio
- cálculo de economia e ranking do melhor mercado
- interface web responsiva
- modo de serviço em segundo plano com suporte a systemd
- logs detalhados e operação contínua em Linux ou Raspberry Pi

### Início Rápido

Requisitos:

- Python 3.8+
- ambiente Linux ou Raspberry Pi
- acesso à internet

Setup básico:

```bash
git clone https://github.com/eliel9012/flight-price-monitor.git
cd flight-price-monitor
chmod +x install_raspberry.sh setup_service.sh
sudo ./install_raspberry.sh
sudo ./setup_service.sh
```

Depois abra:

```text
http://localhost:8776
```

### Uso Típico

1. informe origem e destino
2. escolha datas de ida e volta
3. selecione os países a comparar
4. inicie a busca
5. compare os resultados normalizados e a economia estimada

### Gerenciamento do Serviço

```bash
sudo systemctl status flight-monitor
sudo systemctl restart flight-monitor
sudo journalctl -u flight-monitor -f
```

### Países Suportados

O app já vem preparado para comparar mercados como Brasil, Estados Unidos, Portugal, Espanha, Reino Unido, Alemanha, França, Canadá, Argentina, Chile, México, Itália, Holanda, Irlanda, Suíça, Japão, Austrália e Turquia.

### Observações

- a integração com VPN é opcional, mas ajuda quando você quer testar mercados realmente diferentes
- alguns scrapers podem exigir automação de navegador, como Playwright
- o projeto foi pensado para uso contínuo em hosts Linux-like
