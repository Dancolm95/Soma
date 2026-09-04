# Soma

Aplicación personal de gestión de gastos asistida por IA.

> Estado actual: Fase 2 en curso. Autenticación email/password y ciclo de sesión
> implementados (Tarea 2.4). Pendientes las funcionalidades financieras y de negocio.

## Stack

- Flutter / Dart (targets: Android y Web)
- Supabase (backend) y Gemini 2.5 Flash (IA) se integrarán en tareas posteriores.

## Requisitos

- Flutter SDK 3.47.2 o superior (canal estable). Se gestiona con FVM.
- Para Android: Android SDK con licencias aceptadas.
- Para Web en navegador de Windows: Chrome/Edge instalado en Windows y
  `CHROME_EXECUTABLE` apuntando al ejecutable (ver sección "Ejecutar").

## Setup de macOS

### Flutter (FVM)

```bash
brew install fvm
fvm install stable      # instala Flutter 3.47.2
fvm use stable          # dentro del repositorio, usa la versión del proyecto
```

Desde la raíz del repositorio, reemplazar `flutter` por `fvm flutter`
(o `fvm dart` para format/analyze).

### Android SDK

```bash
brew install --cask android-commandlinetools
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=$ANDROID_HOME
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

Añadir `ANDROID_HOME` y `ANDROID_SDK_ROOT` a `~/.zshrc` para que persistan.

### Supabase local

```bash
brew install supabase/tap/supabase   # o: npm install -g supabase
```

Requisito: Docker Desktop corriendo. Después, en la raíz del repositorio:

```bash
supabase start
supabase stop
```

## Ejecutar

La app se ejecuta en WSL y en macOS. Ninguno usa el target de escritorio
Linux (fuera del alcance del MVP). Con FVM, reemplazar `flutter` por
`fvm flutter`.

### Web sin navegador (server)

Sirve la app en un puerto local, sin necesidad de Chrome instalado:

```bash
flutter run -d web-server --web-port 8080
```

Luego abrir `http://localhost:8080` en el navegador.

### Web en el navegador

- **macOS**: Chrome es nativo, no hace falta configuración extra.

  ```bash
  flutter run -d chrome
  ```

- **WSL**: hay que apuntar Flutter al Chrome instalado en Windows, ya que WSL
  no tiene Chrome. Ajusta la ruta si tu instalación difiere:

  ```bash
  export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  flutter run -d chrome
  ```

  Para hacerlo permanente, añade esa línea `export CHROME_EXECUTABLE=...` a tu
  `~/.bashrc`.

### Android

Requiere un emulador o dispositivo conectado y visible vía `adb`:

```bash
flutter run -d <device-id>
```

Para listar dispositivos disponibles: `flutter devices`.

## Configuración por entorno

El entorno y las credenciales Supabase se pasan en tiempo de compilación
con `--dart-define`. Ningún secreto se almacena en el repositorio.

```bash
flutter run -d web-server --web-port 8080 \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon-key>
```

Si `APP_ENV` no se define, se usa `development`. Si `SUPABASE_URL` o
`SUPABASE_PUBLISHABLE_KEY` no se proporcionan, la aplicación falla en
el arranque con un mensaje claro (sin exponer los valores).

Ver `docs/operations.md` para instrucciones completas de WSL y macOS.

## Validación

Con FVM, anteponer `fvm` a cada comando (`fvm flutter analyze`,
`fvm dart format`, etc.).

```bash
flutter analyze                    # análisis estático
dart format --set-exit-if-changed .  # verifica formato
flutter test                       # tests
flutter build web                  # compila web
flutter build apk --debug          # compila Android
```

## Estructura

```
lib/
  main.dart                         # punto de entrada (inicializa Supabase)
  application/
    app.dart                        # widget raíz
    auth/
      auth_service.dart             # contrato AuthService + tipos de resultado
      auth_controller.dart          # estado de autenticación (ChangeNotifier)
    configuration/
      app_environment.dart          # entorno y configuración build-time
  features/
    auth/
      auth_gate.dart                # selección de pantalla según sesión
      auth_screen.dart              # formulario email/password
      signed_in_screen.dart         # pantalla autenticada mínima
  infrastructure/
    auth/
      supabase_auth_service.dart    # implementación Supabase de AuthService
      auth_error_messages.dart      # mapeo de errores a mensajes seguros
    supabase/
      supabase_initializer.dart     # bootstrap del cliente Supabase
supabase/
  config.toml                       # configuración local Supabase CLI
  migrations/                       # migraciones SQL
  tests/                            # tests RLS (pgTAP)
```

Convención prevista para tareas posteriores (aún sin crear):

- `lib/features/<feature>/` — funcionalidades de negocio.
- `lib/domain/` — dominio compartido.
