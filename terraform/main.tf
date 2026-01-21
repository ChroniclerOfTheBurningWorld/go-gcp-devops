# Блок Terraform: Определяет необходимые провайдеры
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Блок Provider: Настраивает подключение к Google Cloud
# Terraform будет автоматически использовать учетные данные из gcloud auth login, 
# которые были настроены ранее в Ubuntu.
provider "google" {
  project = "devops-go-app"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

# --- Ресурсы Инфраструктуры ---

# 1. Создание Виртуальной Машины (VM Instance)
resource "google_compute_instance" "app_server" {
  name         = "go-app-vm"
  machine_type = "e2-micro"
  allow_stopping_for_update = true

  service_account {
    email  = "github-actions-deployer@devops-go-app.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform", # Полный доступ
    ]
  }

  # Образ диска (операционная система)
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Сетевой интерфейс
  network_interface {
    network = "default"
    access_config {
      # Для получения публичного IP-адреса
    }
  }
  
  # Добавляем SSH-ключ для возможности подключения
  # Terraform автоматически загрузит публичный SSH-ключ из Ubuntu 
  # и добавит его в метаданные VM.
 metadata = {
    # Ключевое изменение: явно указываем имя пользователя (ubuntu) перед публичным ключом
    ssh-keys = "${var.gcp_ssh_user}:${local.ssh_key}"
  }

  # Установка тегов
  tags = ["http-server", "ansible-target"]
}

# 2. Правило Брандмауэра (Firewall Rule)
# Разрешаем входящий трафик на порт 8080 (где будет Go-приложение)
resource "google_compute_firewall" "http_8080" {
  name    = "allow-go-app-8080"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  
  # Применяем правило только к тем VM, у которых есть тег "http-server"
  target_tags = ["http-server"] 
  source_ranges = ["0.0.0.0/0"] # Разрешить трафик отовсюду (для доступа к приложению)
}


# --- Локальные переменные и Выводы (Outputs) ---

# Локальная переменная: считываем содержимое публичного SSH-ключа
locals {
  # Считываем ключ из стандартного места (~/.ssh/id_rsa.pub)
  # trimspace удаляет лишние пробелы/переводы строки
  ssh_key = fileexists("~/.ssh/id_rsa.pub") ? trimspace(file("~/.ssh/id_rsa.pub")) : ""
}

# Вывод публичного IP-адреса для доступа к приложению
output "public_ip" {
  value = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
  description = "Публичный IP-адрес VM Go-приложения"

}
