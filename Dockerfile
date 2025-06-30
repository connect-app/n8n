FROM node:22-alpine

# Установка pnpm
RUN npm install -g pnpm@10

# Установка системных зависимостей
RUN apk add --no-cache git python3 make g++

WORKDIR /app

# Копирование и установка зависимостей
COPY package*.json pnpm-*.yaml ./
COPY packages ./packages
RUN pnpm install --frozen-lockfile

# Сборка проекта
RUN pnpm build

# Порт для Heroku
EXPOSE $PORT

# Запуск
CMD ["npm", "start"]