# Деплой N8N на Heroku

Эта инструкция поможет вам задеплоить ваш форк N8N на Heroku используя Docker контейнеры.

## Предварительные требования

- Аккаунт на Heroku
- Heroku CLI установленный локально
- Git

## Способ 1: Автоматический деплой (Рекомендуемый)

### Шаг 1: Подготовка репозитория

1. Убедитесь что все файлы закоммичены:
```bash
git add .
git commit -m "Add Heroku deployment files"
git push origin master
```

### Шаг 2: Создание приложения на Heroku

1. Войдите в Heroku Dashboard
2. Нажмите "New" -> "Create new app"
3. Введите название приложения
4. Выберите регион
5. Нажмите "Create app"

### Шаг 3: Настройка стека контейнеров

В терминале выполните:
```bash
heroku stack:set container -a ВАШ_НОМ_ПРИЛОЖЕНИЯ
```

### Шаг 4: Подключение GitHub репозитория

1. В Heroku Dashboard перейдите в раздел "Deploy"
2. Выберите "GitHub" как deployment method
3. Найдите и подключите ваш форк репозитория
4. Включите "Automatic deploys" для автоматического деплоя при изменениях

### Шаг 5: Настройка переменных окружения

Перейдите в раздел "Settings" -> "Config Vars" и настройте:

**Обязательные переменные:**
- `N8N_ENCRYPTION_KEY`: Уникальный ключ шифрования (сгенерируйте случайную строку)
- `WEBHOOK_URL`: `https://ваше-приложение.herokuapp.com/`

**Рекомендуемые переменные:**
- `N8N_BASIC_AUTH_ACTIVE`: `true`
- `N8N_BASIC_AUTH_USER`: `admin` (или ваш логин)
- `N8N_BASIC_AUTH_PASSWORD`: ваш_пароль
- `GENERIC_TIMEZONE`: `Europe/Moscow`

### Шаг 6: Добавление PostgreSQL

PostgreSQL будет автоматически добавлен через `heroku.yml`. Если нужно добавить вручную:
```bash
heroku addons:create heroku-postgresql:essential-0 -a ВАШ_НОМ_ПРИЛОЖЕНИЯ
```

### Шаг 7: Деплой

1. Нажмите "Deploy Branch" в разделе "Manual deploy"
2. Дождитесь завершения сборки
3. Откройте приложение

## Способ 2: Через командную строку

### Шаг 1: Создание приложения
```bash
heroku create ваше-приложение
heroku stack:set container -a ваше-приложение
```

### Шаг 2: Настройка переменных
```bash
heroku config:set N8N_ENCRYPTION_KEY=$(openssl rand -hex 32) -a ваше-приложение
heroku config:set WEBHOOK_URL=https://ваше-приложение.herokuapp.com/ -a ваше-приложение
heroku config:set N8N_BASIC_AUTH_ACTIVE=true -a ваше-приложение
heroku config:set N8N_BASIC_AUTH_USER=admin -a ваше-приложение
heroku config:set N8N_BASIC_AUTH_PASSWORD=ваш_пароль -a ваше-приложение
heroku config:set GENERIC_TIMEZONE=Europe/Moscow -a ваше-приложение
```

### Шаг 3: Добавление базы данных
```bash
heroku addons:create heroku-postgresql:essential-0 -a ваше-приложение
```

### Шаг 4: Деплой
```bash
git push heroku master
```

## Проверка деплоя

1. Откройте ваше приложение: `https://ваше-приложение.herokuapp.com/`
2. Войдите используя базовую аутентификацию
3. Создайте первый рабочий процесс

## Логи и отладка

Для просмотра логов:
```bash
heroku logs --tail -a ваше-приложение
```

## Частые проблемы

### Ошибка сборки Docker
- Убедитесь что стек установлен в `container`
- Проверьте что файлы `Dockerfile`, `heroku.yml`, `entrypoint.sh` присутствуют

### Ошибка подключения к базе данных
- Убедитесь что PostgreSQL аддон добавлен
- Проверьте что переменная `DATABASE_URL` автоматически установлена Heroku

### Приложение не запускается
- Проверьте логи: `heroku logs --tail`
- Убедитесь что переменная `N8N_ENCRYPTION_KEY` установлена

## Обновление

Для обновления N8N до новой версии:
1. Обновите `FROM n8nio/n8n:latest` в Dockerfile на нужную версию
2. Закоммитьте изменения
3. Если включен автоматический деплой - он произойдет автоматически
4. Или нажмите "Deploy Branch" в Heroku Dashboard

## Масштабирование

Для увеличения производительности:
```bash
heroku ps:scale web=1:basic -a ваше-приложение
```

Для production использования рекомендуется:
- Использовать платные планы Heroku (Hobby или выше)
- Настроить SSL сертификаты
- Использовать внешнее хранилище файлов (AWS S3)
- Настроить мониторинг 