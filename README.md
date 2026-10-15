# Edge

**Smart picks. Clear edge.**

A clean Flutter app that shows today's and this week's sports predictions so you can quickly create booking tickets on SportyBet.

## Features

- **Today** and **This Week** prediction tabs
- Sport categories (Football primary, Basketball & others ready)
- Clean dark UI optimized for quick ticket creation
- Long-press any match to copy predictions for SportyBet
- Uses [API-Sports](https://api-sports.io/) predictions endpoint
- Pure Flutter (no backend required)

## Getting Started

1. Get a free API key from [dashboard.api-football.com](https://dashboard.api-football.com)
2. Open `lib/services/api_service.dart` and replace `YOUR_API_KEY_HERE`
3. Run:

```bash
flutter pub get
flutter run
```

## Notes

- Free plan of API-Sports is limited to 100 requests/day. The app is written to stay within reasonable limits.
- Football has full prediction support. Other sports are scaffolded for future expansion.

---

Built by Destiny Ed
