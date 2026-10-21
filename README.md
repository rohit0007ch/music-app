# melora_music

Melora — Premium hybrid music player.

## Getting Started

```bash
flutter pub get
flutter run
```

Discover uses the Jamendo API with a built-in Client ID, so the catalog works on any device with a normal `flutter run` (no `--dart-define` required).

To use a different Client ID for a build:

```bash
flutter run --dart-define=JAMENDO_CLIENT_ID=other_id
```
