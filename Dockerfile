FROM node:22-alpine

# Установка pnpm
RUN npm install -g pnpm@10

# Установка системных зависимостей
RUN apk add --no-cache git python3 make g++

WORKDIR /app

# Копирование файлов конфигурации и зависимостей
COPY package*.json pnpm-*.yaml ./
COPY patches ./patches
COPY packages ./packages
COPY scripts ./scripts

# Установка зависимостей
RUN pnpm install --frozen-lockfile

# Сборка проекта
RUN pnpm build

# Порт для Heroku
EXPOSE $PORT

# Запуск
CMD ["npm", "start"]