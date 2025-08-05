# 🔐 FlutterPass – локальный менеджер паролей на Flutter

Менеджер паролей, совместимый с [pass](https://www.passwordstore.org/), с поддержкой GPG-шифрования и хранения паролей в локальной файловой системе.  

---

## 📦 MVP: цели и структура

### 🎯 Цель MVP

- Работа с локальной папкой `pass`-репозитория
- Загрузка GPG-ключей (публичного и приватного)
- Чтение списка зашифрованных `.gpg` файлов
- Расшифровка и отображение содержимого
- Шифрование и сохранение новых паролей
- Удаление файлов
- Минимальная архитектура сервисов без UI

---

## ✅ Чеклист по разработке

### 1. GPG Key Management
- [x] Загрузка приватного ключа
- [x] Загрузка публичного ключа
- [x] Хранение passphrase
- [x] Проверка и инициализация

### 2. Расшифровка / Шифрование
- [x] `PasswordDecryptService` — расшифровка `.gpg`
- [x] `PasswordEncryptService` — шифрование с `publicKey`

### 3. Работа с локальной папкой
- [x] `PasswordStoreService` — загрузка списка файлов
- [x] Чтение `.gpg` файлов
- [x] Сохранение новых файлов
- [x] Удаление паролей
- [x] Поддержка подкаталогов

### 4. Password Manager
- [x] Сервис-обертка для всех операций
- [x] Чтение, шифрование, удаление
- [x] Логика по относительным путям

### 5. Базовая структура проекта
- [x] Разделение по `services/`, `models/`, `utils/`
- [ ] Конфигурация через `.gpg-id` (в будущем)

### 6. Тестирование
- [ ] Unit-тесты для `GPGKeyService`
- [ ] Unit-тесты для `PasswordStoreService`
- [ ] Unit-тесты для `PasswordManager`

---

## 📁 Структура проекта

```bash
lib/
├── app.dart
├── main.dart
├── models/
│   └── password_entry.dart
├── services/
│   ├── gpg_key_service.dart
│   ├── password_decrypt_service.dart
│   ├── password_encrypt_service.dart
│   ├── password_store_service.dart
│   └── password_manager.dart
├── utils/
│   └── file_utils.dart
└── config/
    └── constants.dart
