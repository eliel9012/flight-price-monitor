# Dockerfile otimizado para ARM64 (Raspberry Pi)
FROM python:3.11-slim-bookworm

WORKDIR /app

# Instalar dependências básicas do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primeiro (cache layer)
COPY requirements.txt .

# Instalar dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Instalar Playwright e Chromium com todas as dependências
RUN playwright install --with-deps chromium || \
    (apt-get update && \
     apt-get install -y --no-install-recommends \
        fonts-liberation \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libwayland-client0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        xvfb \
        fonts-noto-color-emoji \
        libenchant-2-2 \
     && rm -rf /var/lib/apt/lists/* && \
     playwright install chromium)

# Copiar arquivos do projeto
COPY . .

# Criar diretórios necessários
RUN mkdir -p /app/data /app/logs && \
    chmod -R 755 /app/data /app/logs

# Variáveis de ambiente
ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production

EXPOSE 8778

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8778/ || exit 1

CMD ["python", "-u", "app.py"]
