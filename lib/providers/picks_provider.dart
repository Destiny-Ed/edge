import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_prediction.dart';

class PicksProvider extends ChangeNotifier {
  List<MatchPrediction> _picks = [];
  Set<String> _savedKeys = {}; // sport_fixtureId

  List<MatchPrediction> get picks => List.unmodifiable(_picks);
  Set<String> get savedKeys => _savedKeys;

  bool isSaved(String sport, int fixtureId) =>
      _savedKeys.contains('${sport}_$fixtureId');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('edge_user_picks') ?? [];
    _picks = raw.map((e) => MatchPrediction.fromJson(jsonDecode(e))).toList();
    _savedKeys = _picks.map((p) => '${p.sport}_${p.fixtureId}').toSet();
    notifyListeners();
  }

  Future<void> savePick(MatchPrediction pick) async {
    if (isSaved(pick.sport, pick.fixtureId)) return;

    _picks.add(pick);
    _savedKeys.add('${pick.sport}_${pick.fixtureId}');
    await _persist();
    notifyListeners();
  }

  Future<void> updateResult(String id, PickResult result) async {
    final index = _picks.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _picks[index] = _picks[index].copyWith(
      result: result,
      settledAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removePick(String id) async {
    final pick = _picks.firstWhere((p) => p.id == id, orElse: () => _picks.first);
    _picks.removeWhere((p) => p.id == id);
    _savedKeys.remove('${pick.sport}_${pick.fixtureId}');
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'edge_user_picks',
      _picks.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Map<String, dynamic> getAnalytics() {
    final settled = _picks.where((p) => p.result != PickResult.pending).toList();

    if (settled.isEmpty) {
      return {
        'total': 0,
        'won': 0,
        'lost': 0,
        'accuracy': 0.0,
        'byMarket': <String, Map<String, int>>{},
        'byLeague': <String, Map<String, int>>{},
        'byConfidence': <String, Map<String, int>>{},
        'bestStreak': 0,
      };
    }

    final won = settled.where((p) => p.result == PickResult.won).length;
    final lost = settled.where((p) => p.result == PickResult.lost).length;
    final accuracy = won / settled.length * 100;

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

    final byLeague = <String, Map<String, int>>{};
    for (final p in settled) {
      byLeague.putIfAbsent(p.league, () => {'won': 0, 'lost': 0});
      if (p.result == PickResult.won) {
        byLeague[p.league]!['won'] = (byLeague[p.league]!['won'] ?? 0) + 1;
      } else {
        byLeague[p.league]!['lost'] = (byLeague[p.league]!['lost'] ?? 0) + 1;
      }
    }

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

    settled.sort((a, b) => (b.settledAt ?? b.kickOff).compareTo(a.settledAt ?? a.kickOff));
    int bestStreak = 0;
    int temp = 0;
    for (final p in settled) {
      if (p.result == PickResult.won) {
        temp++;
        if (temp > bestStreak) bestStreak = temp;
      } else {
        temp = 0;
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
      'bestStreak': bestStreak,
    };
  }
}
