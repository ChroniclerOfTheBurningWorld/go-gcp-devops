package main

import (
    "fmt"
    "log"
    "net/http"
    "github.com/go-chi/chi/v5" // <--- ЭТО ЗАВИСИМОСТЬ
)

// Обработчик HTTP-запросов
func handler(w http.ResponseWriter, r *http.Request) {
    // В ответ добавим уникальный идентификатор для простоты отслеживания изменений
    message := "Привет от Go-приложения (версия 1.0)! Я успешно развернут на GCP! 🚀"
    fmt.Fprintf(w, message)
    log.Printf("Запрос обработан.")
}

func main() {
	r := chi.NewRouter()
	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Hello, World from Go and Chi!")
	})
	http.ListenAndServe(":8080", r)
}