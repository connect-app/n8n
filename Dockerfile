# ==============================================================================
# Heroku Dockerfile - использует готовый образ N8N
# ==============================================================================
FROM ghcr.io/connect-app/n8n/n8n-custom:latest

# Переключение на root для настройки Heroku
USER root

# Копирование entrypoint для Heroku (обработка переменной PORT)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Возврат к пользователю node
USER node

# Используем наш entrypoint для Heroku
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]