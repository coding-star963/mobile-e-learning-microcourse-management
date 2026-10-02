# Mobile — Student App (Flutter)

Student-facing app: course discovery, enrollment, lessons (video/audio, resources), progress, learning history, announcements/notifications and the student dashboard.

See the [project README](../README.md) for full setup and demo accounts, and [AGENT.md](AGENT.md) for the module list and architecture rules.

```bash
flutter pub get
flutter run                                                   # then long-press the login logo to set the server
flutter run --dart-define=API_BASE_URL=http://<laptop-ip>:8000/api   # or set it at build time
flutter analyze
flutter test
```

- `lib/main.dart` wires the REST repositories (`lib/data/api/`). Widget tests use the in-memory mock repositories (`lib/data/mock/`).
- Only student accounts can sign in. The login session is remembered until logout.
