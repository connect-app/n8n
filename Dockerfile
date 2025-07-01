###############################################################################
# ⬣  Stage 1 — Build (Node 22 + pnpm 10)                                      #
###############################################################################
ARG NODE_VERSION=22
ARG PNPM_VERSION=10.2.1
FROM node:${NODE_VERSION}-alpine AS build

RUN apk add --no-cache \
      git openssh tzdata graphicsmagick \
      ca-certificates libc6-compat jq \
      cairo-dev pango-dev pixman-dev fribidi-dev harfbuzz-dev giflib-dev \
      libjpeg-turbo-dev libpng-dev \
      vips-dev linux-headers \
  && apk add --no-cache --virtual .build-deps \
      python3 make g++ pkgconf \
  && npm i -g full-icu@1.5.0 npm@11.4.2 pnpm@${PNPM_VERSION}

WORKDIR /usr/src/app
COPY . .

# Чтобы lefthook install не падал на prepare
RUN git init

ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN pnpm install --frozen-lockfile \
 && pnpm run build

###############################################################################
# ⬣  Stage 2 — Runtime (минимальный + tini для корректной обработки SIGTERM)  #
###############################################################################
FROM node:${NODE_VERSION}-alpine

# tini нужен для корректной передачи SIGTERM в приложение
RUN apk add --no-cache tini

# Копируем ICU и глобальные модули (pnpm, full-icu)
COPY --from=build /usr/local /usr/local
# Копируем приложение и зависимости
COPY --from=build /usr/src/app /home/node/app

# Копируем entrypoint в корень и делаем исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Создаём пользователя n8n и переключаемся на него
RUN addgroup -S n8n && adduser -S -G n8n n8n
USER n8n

WORKDIR /home/node/app

# Переменные окружения для продакшна
ENV NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678

EXPOSE 5678

# Запускаем entrypoint через tini, регистрируя его как subreaper (-s)
ENTRYPOINT ["tini", "-s", "--", "/entrypoint.sh"]