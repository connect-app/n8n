# Docker образы и теги N8N

## Стратегия тегирования

### 🚀 **master ветка** (Production)
При push в `master` создаются образы с тегами:
- `latest` - стандартный Docker тег для production
- `master-{sha}` - версия с хешем коммита для точной идентификации

**Использование:**
```dockerfile
# Heroku Dockerfile
FROM ghcr.io/connect-app/n8n/n8n-custom:latest
```

### 🧪 **develop ветка** (Staging/Testing)
При push в `develop` создаются образы с тегами:
- `develop-latest` - последняя версия для тестирования
- `develop` - алиас ветки
- `develop-{sha}` - версия с хешем коммита

**Использование:**
```dockerfile
# Для тестового окружения
FROM ghcr.io/connect-app/n8n/n8n-custom:develop-latest
```

## Workflow процесс

1. **Разработка** → push в `develop` → собирается тестовый образ `develop-latest`
2. **Готово к релизу** → merge `develop` → `master` → собирается production образ `latest`
3. **Автодеплой** → Heroku подтягивает `latest` образ и деплоит

## Registry
Все образы публикуются в: `ghcr.io/connect-app/n8n/n8n-custom` 