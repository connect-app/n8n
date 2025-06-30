# Настройка приватного доступа к образу

## 1. Создание Personal Access Token (PAT)

1. Идем в GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Создаем новый токен с правами:
   - `read:packages` - чтение образов
   - `write:packages` - публикация образов (для Actions)

## 2. Настройка Heroku для приватного образа

### Способ 1: Registry login в Dockerfile
```dockerfile
# В Dockerfile.build добавляем перед FROM
ARG GITHUB_TOKEN
RUN echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

FROM ghcr.io/connect-app/n8n/n8n-custom:latest
```

### Способ 2: Heroku Config Vars
```bash
# Добавляем в Heroku переменные
heroku config:set GITHUB_TOKEN=ghp_xxxxxxxxxxxx
heroku config:set GITHUB_USERNAME=connect-app
```

### Способ 3: heroku.yml с аутентификацией
```yaml
setup:
  addons:
    - heroku-postgresql
  config:
    NODE_ENV: production

build:
  config:
    GITHUB_TOKEN: $GITHUB_TOKEN
  docker:
    web: 
      dockerfile: Dockerfile
      target: runtime

run:
  web: /entrypoint.sh
```

## 3. Обновленный Dockerfile для приватного доступа
```dockerfile
ARG GITHUB_TOKEN
ARG GITHUB_USERNAME=connect-app

# Аутентификация в GitHub Container Registry
RUN echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

FROM ghcr.io/connect-app/n8n/n8n-custom:production

# Остальная настройка...

## 4. Выбор образа для окружения

### Production (Heroku)
```dockerfile
FROM ghcr.io/connect-app/n8n/n8n-custom:latest
```

### Staging/Testing
```dockerfile  
FROM ghcr.io/connect-app/n8n/n8n-custom:develop-latest
```

### Конкретная версия
```dockerfile
FROM ghcr.io/connect-app/n8n/n8n-custom:master-abc123def
```

## 5. Workflow процесс

1. **Разработка**: push в `develop` → создается образ `develop-latest`
2. **Готово к релизу**: merge `develop` → `master` → создается образ `latest`
3. **Heroku автодеплой**: использует стандартный образ `latest` из master ветки

Это обеспечивает четкое разделение между тестовой и производственной средой.