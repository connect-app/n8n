###############################################################################
# ⬣  Stage 1 — Build (Node 22 + pnpm 10)                                      #
###############################################################################
ARG NODE_VERSION=22
ARG PNPM_VERSION=10.2.1
FROM node:${NODE_VERSION}-alpine AS build

# Устанавливаем системные библиотеки, ICU, dev-заголовки
RUN apk add --no-cache \
      git openssh tzdata graphicsmagick \
      ca-certificates libc6-compat jq \
      cairo-dev pango-dev pixman-dev fribidi-dev harfbuzz-dev giflib-dev libjpeg-turbo-dev libpng-dev \
      vips-dev linux-headers \
 && apk add --no-cache --virtual build-deps python3 make g++ pkgconf \
 && npm i -g full-icu@1.5.0 npm@11.4.2 pnpm@${PNPM_VERSION}

WORKDIR /usr/src/app
COPY . .

# Инициализируем git, чтобы lefthook install не падал
RUN git init

# Устанавливаем зависимости и собираем n8n
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN pnpm install --frozen-lockfile \
 && pnpm run build

###############################################################################
# ⬣  Stage 2 — Runtime (минимальный образ)                                     #
###############################################################################
FROM node:${NODE_VERSION}-alpine

# Копируем ICU, шрифты и собранное приложение
COPY --from=build /usr/local    /usr/local
COPY --from=build /usr/src/app  /home/node/app

# Копируем entrypoint и даём ему права (от root)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Создаём и переключаемся на пользователя n8n
RUN addgroup -S n8n && adduser -S -G n8n n8n

# Создаём директорию для данных N8N и даём права пользователю n8n
RUN mkdir -p /home/n8n/.n8n && chown -R n8n:n8n /home/n8n

USER n8n
WORKDIR /home/node/app

# Переменные окружения для продакшна
ENV NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678 \
    N8N_USER_FOLDER=/home/n8n/.n8n

EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]