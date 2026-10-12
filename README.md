# P2P Reminder

![App Logo](assets/app_icon.png)

Track personal loans you **lent** and **borrowed** with simple reminders and repayment history.

## MVP Features

- 📊 Lent / Borrowed summary dashboard
- 🔔 Interest and principal due reminders
- ➕ Add/Edit P2P loan entries
- ✅ Mark payments and track repayment history
- 📤 Share simple report snapshot
- 📱 Offline-first local storage with repository abstraction

## Architecture Notes

- `P2PRepository` interface is added for backend-ready migration.
- `P2PRepositoryLocal` is used in MVP.
- `P2PRepositoryRemote` is scaffolded for Phase 2 login/server sync.

## Getting Started

```bash
flutter pub get
flutter run
```

For release builds, update signing and store metadata as needed before publishing.
