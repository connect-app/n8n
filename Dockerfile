# ==============================================================================
# STAGE 1: Build Application from Source
# ==============================================================================
FROM node:22-alpine AS builder

# Установка pnpm
RUN npm install -g pnpm@10

# Установка системных зависимостей
RUN apk add --no-cache git python3 make g++

WORKDIR /app

# Установка переменной окружения для пропуска lefthook в Docker
ENV DOCKER_BUILD=true

# Копирование конфигурационных файлов
COPY package*.json pnpm-*.yaml turbo.json tsconfig.json ./
COPY patches ./patches
COPY packages ./packages
COPY scripts ./scripts

# Установка зависимостей
RUN pnpm install --frozen-lockfile

# Сборка всех пакетов
RUN pnpm build

# Создание production deployment в папку compiled
RUN pnpm --filter=n8n --prod --legacy deploy --no-optional ./compiled

# ==============================================================================
# STAGE 2: Official N8N Runtime (адаптированный)
# ==============================================================================
FROM node:22-alpine AS runtime

ENV NODE_ENV=production
ENV SHELL=/bin/sh

WORKDIR /home/node

# Копируем собранное приложение из первого этапа
COPY --from=builder /app/compiled /usr/local/lib/node_modules/n8n

# Перестраиваем нативные модули
RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n

# Установка npm@11.4.2 (как в официальном Dockerfile)
RUN npm install -g npm@11.4.2

# Установка canvas для PDF (как в официальном Dockerfile)
RUN cd /usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist && npm install @napi-rs/canvas

# Создание пользователя node (если не существует)
RUN addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node || true
RUN chown -R node:node /home/node

# Копирование entrypoint.sh скрипта для обработки переменной PORT от Heroku
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE $PORT

USER node

ENTRYPOINT ["/entrypoint.sh"]