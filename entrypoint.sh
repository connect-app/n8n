#!/bin/bash

# Переменная PORT от Heroku должна быть передана в N8N_PORT
if [ -n "$PORT" ]; then
    export N8N_PORT=$PORT
fi

# Запускаем n8n
exec n8n start 