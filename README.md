Выполнил Зинченко А.С. в рамках домашней работы

# Домашнее задание: Развертывание Go-приложения с Docker Compose

## Структура проекта
```
.
├── Dockerfile            # Multi-stage сборка приложения
├── docker-compose.yml    # Оркестрация сервисов
├── nginx/
│   └── templates/        # Шаблоны Nginx
│       └── default.conf.template
└── api/                  # Исходный код приложения
    ├── cmd/              # Точка входа
    ├── internal/         # Внутренние модули
    ├── docs/             # Swagger документация
    ├── go.mod            # Зависимости Go
    └── go.sum
```

## Запуск приложения
1. Скопируйте пример окружения:
   ```bash
   cp .env.example .env
   ```
2. Соберите и запустите сервисы:
   ```bash
   docker-compose build && docker-compose up -d
   ```

**Доступные endpoints:**
- Swagger UI: http://localhost:8088/swagger/index.html
- POST /roll - имитация броска кости
- GET /stats - статистика бросков

## Как работает Docker Compose

### 1. Сервис `backend`
- **Сборка:** Использует multi-stage Dockerfile
  - Этап builder: компиляция Go-приложения
  - Этап runtime: минимальный образ с бинарником
- **Безопасность:** Запуск от пользователя 1000:1000
- **Артефакт:** `/app/go-app` (статически слинкованный бинарник)
- **Переменные:**
  ```yaml
  environment:
    API_PORT: 8887          # Порт приложения
    DB_URL: postgres://...  # Строка подключения к БД
  ```

### 2. Сервис `postgres`
- **Образ:** postgres:16-alpine
- **Инициализация:**
  ```yaml
  environment:
    POSTGRES_DB: db
    POSTGRES_USER: user_db
    POSTGRES_PASSWORD: pwd_db
  ```
- **Healthcheck:** Проверка готовности БД каждые 5 секунд

### 3. Сервис `nginx`
- **Проксирование:** 
  ```nginx
  server {
    listen 80;
    location / {
      proxy_pass http://backend:${API_PORT};
    }
  }
  ```
- **Автогенерация конфига:** Шаблон `default.conf.template`
- **Зависимости:** Запускается только после готовности backend

## Особенности реализации
1. **Безопасность:**
   - Нет привилегированных пользователей
   - Все секреты в `.env` (не коммитится в Git)
   ```bash
   # .env.example
   API_PORT=8887
   POSTGRES_DB=db
   POSTGRES_USER=user_db
   POSTGRES_PASSWORD=pwd_db
   NGINX_PORT=8088
   ```

2. **Производительность:**
   - Multi-stage сборка
   - Keepalive-соединения в Nginx
   ```nginx
   upstream backend {
     server backend:${API_PORT};
     keepalive 32;
   }
   ```

3. **Надежность:**
   - Healthcheck для PostgreSQL
   - Автоматические перезапуски при сбоях
   - Логирование в stdout

[Доступ к Swagger UI](http://localhost:8088/swagger/index.html) после успешного запуска.

