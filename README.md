# Edge

**Smart picks. Clear edge.**

A comprehensive Flutter sports prediction app focused on helping you find value and track your performance.

## Features

- **Today & This Week** predictions
- **Improved prediction logic** (no more forced 1X + Over 1.5 + GG on every match)
- **Save picks** and mark them as **Won / Lost / Void**
- **Analytics dashboard** — accuracy by market, by league, by confidence, streaks
- **Filters** — League, Confidence level, Market type
- Multi-sport support (Football fully supported, Basketball basic)
- Long-press or button to copy tips for SportyBet
- Clean dark UI

## Prediction Quality Note

Predictions now come primarily from API-Sports' own statistical model (`/predictions` endpoint).  
We only surface tips when the data is reasonably strong.  
Low-confidence or unclear matches are marked accordingly instead of forcing popular markets.

## Getting Started

1. Get a free API key → [dashboard.api-football.com](https://dashboard.api-football.com)
2. Open `lib/services/api_service.dart` and replace `YOUR_API_KEY_HERE`
3. Run:

```bash
flutter pub get
flutter run
```

## Free Tier Warning

API-Sports free plan = 100 requests/day.  
The app limits the number of fixtures + prediction calls to stay within reasonable usage.

---

Built by Destiny Ed
