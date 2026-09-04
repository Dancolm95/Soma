# Soma

Aplicación personal de gestión de gastos asistida por IA.

> Estado actual: fundación técnica mínima. Sin funcionalidades de negocio,
> autenticación, Supabase, Gemini ni Frankfurter todavía.

## Stack

- Flutter / Dart (targets: Android y Web)
- Supabase (backend) y Gemini 2.5 Flash (IA) se integrarán en tareas posteriores.

## Requisitos

- Flutter SDK 3.47.2 o superior (canal estable).
- Para Android: Android SDK con licencias aceptadas.
- Para Web en navegador de Windows: Chrome/Edge instalado en Windows y
  `CHROME_EXECUTABLE` apuntando al ejecutable (ver sección "Ejecutar").

## Ejecutar

Hay tres maneras de levantar la app. Todas funcionan desde WSL; ninguna usa el
target de escritorio Linux (fuera del alcance del MVP).

### Web sin navegador (server)

Sirve la app en un puerto local, sin necesidad de Chrome instalado en WSL:

```bash
flutter run -d web-server --web-port 8080
```

Luego abrir `http://localhost:8080` en el navegador de Windows.

### Web en el navegador de Windows

Requiere apuntar Flutter al Chrome instalado en Windows, ya que WSL no tiene
Chrome. Ajusta la ruta si tu instalación difiere:

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

El entorno activo se selecciona en tiempo de compilación con `--dart-define`.
No se usan ni se comprometen secretos en el repositorio.

```bash
flutter run --dart-define=APP_ENV=development   # por defecto
flutter run --dart-define=APP_ENV=staging
flutter run --dart-define=APP_ENV=production
```

Si `APP_ENV` no se define, se usa `development`.

## Validación

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
  main.dart                         # punto de entrada
  application/
    app.dart                        # widget raíz (configuración de app)
    configuration/
      app_environment.dart          # entorno y configuración build-time
  features/
    launch/
      launch_screen.dart            # pantalla mínima de verificación
```

Convención prevista para tareas posteriores (aún sin crear, para no introducir
módulos vacíos especulativos):

- `lib/features/<feature>/` — funcionalidades de negocio.
- `lib/domain/` — dominio compartido.
- `lib/infrastructure/` — integraciones (Supabase, IA, FX, etc.).
