import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_prediction.dart';

class StorageService {
  static const _keyPicks = 'edge_user_picks';

  static Future<List<MatchPrediction>> getSavedPicks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPicks) ?? [];
    return raw.map((e) => MatchPrediction.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> savePick(MatchPrediction pick) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSavedPicks();

    // Avoid duplicates by fixtureId + sport
    final filtered = existing
        .where((p) => !(p.fixtureId == pick.fixtureId && p.sport == pick.sport))
        .toList();
    filtered.add(pick);

    await prefs.setStringList(
      _keyPicks,
      filtered.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> updatePickResult(String id, PickResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSavedPicks();

    final updated = existing.map((p) {
      if (p.id == id) {
        return p.copyWith(
          result: result,
          settledAt: DateTime.now(),
        );
      }
      return p;
    }).toList();

    await prefs.setStringList(
      _keyPicks,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> removePick(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSavedPicks();
    final filtered = existing.where((p) => p.id != id).toList();
    await prefs.setStringList(
      _keyPicks,
      filtered.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final picks = await getSavedPicks();
    final settled = picks.where((p) => p.result != PickResult.pending).toList();

    if (settled.isEmpty) {
      return {
        'total': 0,
        'won': 0,
        'lost': 0,
        'accuracy': 0.0,
        'byMarket': <String, Map<String, int>>{},
        'byLeague': <String, Map<String, int>>{},
        'byConfidence': <String, Map<String, int>>{},
        'currentStreak': 0,
        'bestStreak': 0,
      };
    }

    final won = settled.where((p) => p.result == PickResult.won).length;
    final lost = settled.where((p) => p.result == PickResult.lost).length;
    final accuracy = won / settled.length * 100;

    // By market
    final byMarket = <String, Map<String, int>>{};
    for (final p in settled) {
      for (final tip in p.predictions) {
        byMarket.putIfAbsent(tip, () => {'won': 0, 'lost': 0});
        if (p.result == PickResult.won) {
          byMarket[tip]!['won'] = (byMarket[tip]!['won'] ?? 0) + 1;
        } else if (p.result == PickResult.lost) {
          byMarket[tip]!['lost'] = (byMarket[tip]!['lost'] ?? 0) + 1;
        }
      }
    }

    // By league
    final byLeague = <String, Map<String, int>>{};
    for (final p in settled) {
      byLeague.putIfAbsent(p.league, () => {'won': 0, 'lost': 0});
      if (p.result == PickResult.won) {
        byLeague[p.league]!['won'] = (byLeague[p.league]!['won'] ?? 0) + 1;
      } else {
        byLeague[p.league]!['lost'] = (byLeague[p.league]!['lost'] ?? 0) + 1;
      }
    }

    // By confidence
    final byConfidence = <String, Map<String, int>>{};
    for (final p in settled) {
      byConfidence.putIfAbsent(p.confidence, () => {'won': 0, 'lost': 0});
      if (p.result == PickResult.won) {
        byConfidence[p.confidence]!['won'] =
            (byConfidence[p.confidence]!['won'] ?? 0) + 1;
      } else {
        byConfidence[p.confidence]!['lost'] =
            (byConfidence[p.confidence]!['lost'] ?? 0) + 1;
      }
    }

    // Streak (most recent first)
    settled.sort((a, b) => (b.settledAt ?? b.kickOff).compareTo(a.settledAt ?? a.kickOff));
    int currentStreak = 0;
    int bestStreak = 0;
    int temp = 0;
    for (final p in settled) {
      if (p.result == PickResult.won) {
        temp++;
        bestStreak = temp > bestStreak ? temp : bestStreak;
        if (currentStreak >= 0) currentStreak = temp;
      } else {
        if (currentStreak > 0) currentStreak = 0;
        temp = 0;
        currentStreak = currentStreak <= 0 ? currentStreak - 1 : -1;
      }
    }

    return {
      'total': settled.length,
      'won': won,
      'lost': lost,
      'accuracy': accuracy,
      'byMarket': byMarket,
      'byLeague': byLeague,
      'byConfidence': byConfidence,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }
}
