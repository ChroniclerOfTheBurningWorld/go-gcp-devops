# --- Этап 1: Сборщик (Builder Stage) ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

# Компилируем приложение. CGO_ENABLED=0 критически важен для статического бинарника.
RUN CGO_ENABLED=0 go build -o app ./main.go


# --- Этап 2: Финальный образ (Final Stage) ---
# Используем минималистичный образ Alpine для безопасности и маленького размера
FROM alpine:latest

WORKDIR /root/

# Копируем скомпилированный бинарный файл из первого этапа
COPY --from=builder /app/app .

# Объявляем порт
EXPOSE 8080

# Команда запуска
CMD ["./app"]