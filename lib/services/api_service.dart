import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/match_prediction.dart';

class ApiService {
  // ⚠️ Replace with your real API key from https://dashboard.api-football.com
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  static const String _footballBase = 'https://v3.football.api-sports.io';
  static const String _basketballBase = 'https://v1.basketball.api-sports.io';

  static Map<String, String> get _headers => {'x-apisports-key': _apiKey};
  static final _uuid = Uuid();

  // -------------------- TODAY PREDICTIONS --------------------

  static Future<List<MatchPrediction>> getTodayPredictions(String sport) async {
    if (sport == 'football') return _getFootballToday();
    if (sport == 'basketball') return _getBasketballToday();
    return [];
  }

  static Future<List<MatchPrediction>> _getFootballToday() async {
    final today = _formatDate(DateTime.now().toUtc());
    final fixtures = await _getFootballFixtures(today);

    final upcoming = fixtures.where((f) {
      final status = f['fixture']['status']['short'];
      return status == 'NS' || status == 'TBD';
    }).toList();

    // Keep request count reasonable for free tier
    final limited = upcoming.take(18).toList();
    final results = <MatchPrediction>[];

    for (final fixture in limited) {
      final fixtureId = fixture['fixture']['id'] as int;
      final predData = await _getFootballPrediction(fixtureId);
      results.add(_mapFootball(fixture, predData));
      await Future.delayed(const Duration(milliseconds: 280));
    }

    results.sort((a, b) => a.kickOff.compareTo(b.kickOff));
    return results;
  }

  static Future<List<MatchPrediction>> _getBasketballToday() async {
    final today = _formatDate(DateTime.now().toUtc());
    final games = await _getBasketballGames(today);

    final upcoming = games.where((g) {
      final status = (g['status']?['short'] ?? '').toString().toUpperCase();
      return status.contains('NS') ||
          status.contains('NOT') ||
          status.contains('SCHED');
    }).take(12).toList();

    return upcoming.map(_mapBasketball).toList()
      ..sort((a, b) => a.kickOff.compareTo(b.kickOff));
  }

  // -------------------- LIVE SCORES --------------------

  static Future<List<MatchPrediction>> getLiveScores(String sport) async {
    if (sport == 'football') return _getFootballLive();
    if (sport == 'basketball') return _getBasketballLive();
    return [];
  }

  static Future<List<MatchPrediction>> _getFootballLive() async {
    final url = Uri.parse('$_footballBase/fixtures?live=all');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final list = data['response'] as List? ?? [];

    return list.take(40).map((f) {
      final teams = f['teams'];
      final goals = f['goals'];
      final fixture = f['fixture'];
      final league = f['league'];
      final status = fixture['status'];

      return MatchPrediction(
        id: _uuid.v4(),
        fixtureId: fixture['id'],
        sport: 'football',
        homeTeam: teams['home']['name'],
        awayTeam: teams['away']['name'],
        homeLogo: teams['home']['logo'],
        awayLogo: teams['away']['logo'],
        league: league['name'] ?? '',
        country: league['country'] ?? '',
        kickOff: DateTime.parse(fixture['date']).toLocal(),
        status: status['short'] ?? 'LIVE',
        predictions: const [],
        homeGoals: goals['home'],
        awayGoals: goals['away'],
        elapsed: status['elapsed']?.toString(),
        confidence: 'Live',
      );
    }).toList();
  }

  static Future<List<MatchPrediction>> _getBasketballLive() async {
    // Basketball live is limited on free tier — return empty for now
    return [];
  }

  // -------------------- HELPERS --------------------

  static Future<List<dynamic>> _getFootballFixtures(String date) async {
    final url = Uri.parse('$_footballBase/fixtures?date=$date');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load fixtures (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    return data['response'] ?? [];
  }

  static Future<Map<String, dynamic>?> _getFootballPrediction(int id) async {
    final url = Uri.parse('$_footballBase/predictions?fixture=$id');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final list = data['response'] as List?;
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  static Future<List<dynamic>> _getBasketballGames(String date) async {
    final url = Uri.parse('$_basketballBase/games?date=$date');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return data['response'] ?? [];
  }

  // -------------------- TIGHT PREDICTION MAPPING --------------------

  static MatchPrediction _mapFootball(
      dynamic fixture, Map<String, dynamic>? predData) {
    final teams = fixture['teams'];
    final league = fixture['league'];
    final fixtureInfo = fixture['fixture'];

    final tips = <String>[];
    String? advice;
    String confidence = 'Low';
    Map<String, String>? percentages;
    String? underOver;
    bool? winOrDraw;

    if (predData != null) {
      final p = predData['predictions'];
      advice = p['advice']?.toString();
      winOrDraw = p['win_or_draw'];
      underOver = p['under_over']?.toString();

      if (p['percent'] != null) {
        percentages = {
          'home': p['percent']['home']?.toString() ?? '0%',
          'draw': p['percent']['draw']?.toString() ?? '0%',
          'away': p['percent']['away']?.toString() ?? '0%',
        };

        final home = _pct(percentages['home']);
        final draw = _pct(percentages['draw']);
        final away = _pct(percentages['away']);
        final max = [home, draw, away].reduce((a, b) => a > b ? a : b);

        // Confidence thresholds (tighter)
        if (max >= 58) {
          confidence = 'High';
        } else if (max >= 48) {
          confidence = 'Medium';
        } else {
          confidence = 'Low';
        }

        // Only emit strong directional tips
        if (home >= 55 && home >= away + 10) {
          tips.add('1');
        } else if (away >= 55 && away >= home + 10) {
          tips.add('2');
        } else if (winOrDraw == true) {
          if (home >= away && home >= 42) {
            tips.add('1X');
          } else if (away > home && away >= 42) {
            tips.add('X2');
          }
        } else if (draw >= 40 && draw >= home && draw >= away) {
          tips.add('X');
        }
      }

      // Under/Over only when clearly stated
      if (underOver != null && underOver.isNotEmpty) {
        final raw = underOver.toLowerCase();
        if (raw.contains('over') || raw.startsWith('+')) {
          tips.add(_cleanOverUnder(underOver, isOver: true));
        } else if (raw.contains('under') || raw.startsWith('-')) {
          tips.add(_cleanOverUnder(underOver, isOver: false));
        }
      }

      // Fallback from winner comment only if still empty and strong
      if (tips.isEmpty && p['winner'] != null) {
        final comment = (p['winner']['comment'] ?? '').toString().toLowerCase();
        final name = p['winner']['name'];
        if (comment.contains('win or draw')) {
          if (name == teams['home']['name']) tips.add('1X');
          else if (name == teams['away']['name']) tips.add('X2');
        }
      }
    }

    // Final clean — no forced markets
    final cleaned = tips.toSet().toList();
    if (cleaned.isEmpty) {
      cleaned.add('No strong tip');
      confidence = 'Low';
    }

    return MatchPrediction(
      id: _uuid.v4(),
      fixtureId: fixtureInfo['id'],
      sport: 'football',
      homeTeam: teams['home']['name'],
      awayTeam: teams['away']['name'],
      homeLogo: teams['home']['logo'],
      awayLogo: teams['away']['logo'],
      league: league['name'] ?? '',
      country: league['country'] ?? '',
      kickOff: DateTime.parse(fixtureInfo['date']).toLocal(),
      status: fixtureInfo['status']['short'] ?? 'NS',
      predictions: cleaned,
      advice: advice,
      confidence: confidence,
      percentages: percentages,
      underOver: underOver,
      winOrDraw: winOrDraw,
    );
  }

  static MatchPrediction _mapBasketball(dynamic g) {
    final teams = g['teams'] ?? {};
    final home = teams['home'] ?? {};
    final away = teams['away'] ?? {};
    final league = g['league'] ?? {};
    final date = g['date'] ?? DateTime.now().toIso8601String();

    return MatchPrediction(
      id: _uuid.v4(),
      fixtureId: g['id'] ?? 0,
      sport: 'basketball',
      homeTeam: home['name'] ?? 'Home',
      awayTeam: away['name'] ?? 'Away',
      homeLogo: home['logo'],
      awayLogo: away['logo'],
      league: league['name'] ?? 'Basketball',
      country: '',
      kickOff: DateTime.tryParse(date.toString())?.toLocal() ?? DateTime.now(),
      status: g['status']?['short'] ?? 'NS',
      predictions: const ['Limited data'],
      confidence: 'Low',
      advice: 'Basketball tips are limited on free plan',
    );
  }

  static String _cleanOverUnder(String raw, {required bool isOver}) {
    final number = RegExp(r'[0-9]+\.?[0-9]*').firstMatch(raw)?.group(0) ?? '2.5';
    return isOver ? 'Over $number' : 'Under $number';
  }

  static int _pct(String? v) {
    if (v == null) return 0;
    return int.tryParse(v.replaceAll('%', '').trim()) ?? 0;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
