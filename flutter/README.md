# Aventoria — Flutter-версия

Перенос Godot-проекта Aventoria на Flutter. Начальный этап: авторизация Firebase + главный экран.

## Что уже перенесено
- **Вход/регистрация**: email + пароль и «Войти через Google» (Firebase Authentication).
- **Данные игрока** в Firestore (`users/{uid}`): золото, руны, уровень, статы, инвентарь — структура повторяет протокол `LOGIN_OK` из `scripts/network.gd`.
- **Главный экран**: TopBar (золото/руны/имя/уровень), бургер-меню, нижняя навигация, список модулей.
- **Музыка меню** из `assets/audio`.
- Локальный режим `1111` из Godot-версии **не переносится** по решению автора.

## Как получить APK (без компьютера)
1. GitHub → вкладка **Actions** → workflow **Build APK**.
2. Дождаться зелёной галочки.
3. Внизу страницы прогона — артефакт **aventoria-apk** → скачать → распаковать zip → установить APK на телефон (разрешить установку из неизвестных источников).

## Настройка Firebase (выполняется автором, один раз)
1. [Консоль Firebase](https://console.firebase.google.com) → проект **mad-rabbits** → **Authentication** → «Начало работы» → включить провайдеры **Email/Password** и **Google**.
2. Для входа через Googleга добавить SHA-1 сборки: Settings → ваши приложения → com.aventoria.game → отпечаток. Для CI-сборок используется debug-ключ по умолчанию; SHA-1 можно получить позже.
3. Firestore: создать базу (Native mode), на первом шаге можно оставить доступ только авторизованным (правила — отдельным этапом).

## Структура
- `lib/main.dart` — точка входа, тема, AuthGate.
- `lib/screens/auth_screen.dart` — вход/регистрация.
- `lib/screens/main_screen.dart` — главный экран.
- `lib/services/player_repository.dart` — Firestore-репозиторий игрока.
- `lib/services/audio_manager.dart` — музыка меню.
- `android/app/google-services.json` — конфиг Firebase (не редактировать руками).

## Дальше (по плану)
Профиль и статы → таверна → гильдия → квесты → инвентарь на Firestore → бой (переписывается с нуля, старый «корявый» не копируем) → чат и онлайн на Firestore.
