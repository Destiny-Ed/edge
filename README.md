# Edge

**Smart picks. Clear edge.**

## What's new in v1.2

- **Today only** predictions (This Week removed)
- **Bottom navigation**: Today • Live • My Picks • Stats • Settings
- **Saved picks are highlighted** so you don't save the same game twice
- **Tighter prediction logic** — no more forced 1X / Over 1.5 / GG on every match
- **Live scores** tab
- **Dropdown filters** (League, Confidence, Market)
- **Settings**: Dark/Light theme + Daily notification toggle
- Richer match details (probabilities, advice, under/over signal)

## Setup

1. Get API key → [dashboard.api-football.com](https://dashboard.api-football.com)
2. Put it in `lib/services/api_service.dart`
3. `flutter pub get && flutter run`

## Prediction philosophy

Tips are only shown when the underlying probabilities are reasonably strong.  
Weak matches are labelled "No strong tip" instead of inventing popular markets.

---

Built by Destiny Ed
