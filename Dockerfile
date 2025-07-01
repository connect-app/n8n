###############################################################################
# Stage 1 – Build (Node 22 + pnpm 10.2.1)                                     #
###############################################################################
ARG NODE_VERSION=22
ARG PNPM_VERSION=10.2.1
FROM node:${NODE_VERSION}-alpine AS build

# Устанавливаем системные пакеты и dev-заголовки
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

# Чтобы скрипт lefthook install отработал без ошибок
RUN git init

ENV NODE_OPTIONS="--max-old-space-size=4096"
# Устанавливаем зависимости и собираем UI, core, nodes
RUN pnpm install --frozen-lockfile \
 && pnpm run build

###############################################################################
# Stage 2 – Runtime (минимальный образ)                                       #
###############################################################################
FROM node:${NODE_VERSION}-alpine

# Добавляем tini для корректного проксирования SIGTERM
RUN apk add --no-cache tini

# Копируем ICU, global-модули, собранное приложение и зависимости
COPY --from=build /usr/local /usr/local
COPY --from=build /usr/src/app /home/node/app

# Копируем entrypoint и делаем его исполняемым под root
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Создаём непривилегированного пользователя
RUN addgroup -S n8n && adduser -S -G n8n n8n

# Передаем права на entrypoint пользователю n8n
RUN chown n8n:n8n /entrypoint.sh

USER n8n
WORKDIR /home/node/app

# Переменные окружения для работы n8n
ENV NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678

EXPOSE 5678

# Запускаем entrypoint.sh как PID 1 (Heroku руками не оборачивает в /bin/sh)
ENTRYPOINT []

CMD ["/entrypoint.sh"]