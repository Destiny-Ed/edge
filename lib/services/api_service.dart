import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/match_prediction.dart';

class ApiService {
  // ⚠️ Replace with your real API key from https://dashboard.api-football.com
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  static const String _footballBase = 'https://v3.football.api-sports.io';
  static const String _basketballBase = 'https://v1.basketball.api-sports.io';

  static Map<String, String> get _headers => {
        'x-apisports-key': _apiKey,
      };

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
    return [];
  }

  // -------------------- LOW-LEVEL FETCH --------------------

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

  // -------------------- PREDICTION MAPPING (min 3 tips) --------------------

  static MatchPrediction _mapFootball(
      dynamic fixture, Map<String, dynamic>? predData) {
    final teams = fixture['teams'];
    final league = fixture['league'];
    final fixtureInfo = fixture['fixture'];

    final tips = <String>[];
    String? advice;
    String confidence = 'Medium';
    Map<String, String>? percentages;
    String? underOver;
    bool? winOrDraw;

    int home = 0, draw = 0, away = 0;

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
        home = _pct(percentages['home']);
        draw = _pct(percentages['draw']);
        away = _pct(percentages['away']);

        final max = [home, draw, away].reduce((a, b) => a > b ? a : b);
        if (max >= 58) {
          confidence = 'High';
        } else if (max >= 48) {
          confidence = 'Medium';
        } else {
          confidence = 'Low';
        }
      }

      // ---------- 1) MATCH RESULT (never weak pure X on strong favorite) ----------
      final resultTip = _pickResultTip(
        home: home,
        draw: draw,
        away: away,
        winOrDraw: winOrDraw,
        winner: p['winner'],
        homeName: teams['home']['name']?.toString() ?? '',
        awayName: teams['away']['name']?.toString() ?? '',
        advice: advice,
      );
      if (resultTip != null) tips.add(resultTip);

      // ---------- 2) GOALS (Over / Under) ----------
      final goalsTip = _pickGoalsTip(underOver, home, away, draw);
      if (goalsTip != null) tips.add(goalsTip);

      // ---------- 3) BTTS / GG ----------
      final bttsTip = _pickBttsTip(home, away, draw, underOver);
      if (bttsTip != null) tips.add(bttsTip);

      // ---------- 4) Extra safety markets to always reach 3+ ----------
      _fillToAtLeastThree(
        tips: tips,
        home: home,
        away: away,
        draw: draw,
        underOver: underOver,
        resultTip: resultTip,
      );
    } else {
      // No API prediction — still give 3 useful markets
      tips.addAll(['1X', 'Over 1.5', 'GG']);
      confidence = 'Low';
    }

    // Guarantee minimum 3 unique tips
    final cleaned = tips.toSet().toList();
    while (cleaned.length < 3) {
      for (final fallback in ['Over 1.5', 'GG', '1X', 'Over 2.5', 'Home or Draw']) {
        if (!cleaned.contains(fallback)) {
          cleaned.add(fallback);
          if (cleaned.length >= 3) break;
        }
      }
      break;
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
      predictions: cleaned.take(5).toList(), // cap at 5
      advice: advice,
      confidence: confidence,
      percentages: percentages,
      underOver: underOver,
      winOrDraw: winOrDraw,
    );
  }

  /// Result market — avoid pure X when one side is clearly stronger
  static String? _pickResultTip({
    required int home,
    required int draw,
    required int away,
    required bool? winOrDraw,
    required dynamic winner,
    required String homeName,
    required String awayName,
    required String? advice,
  }) {
    // Strong home favorite → 1 or 1X (never pure X)
    if (home >= 55 && home >= away + 12) return '1';
    if (home >= 48 && home >= away + 8) return '1X';

    // Strong away favorite → 2 or X2
    if (away >= 55 && away >= home + 12) return '2';
    if (away >= 48 && away >= home + 8) return 'X2';

    // Genuine draw only if draw is clearly the top % and close game
    if (draw >= 38 && draw >= home && draw >= away && (home - away).abs() <= 8) {
      return 'X';
    }

    // win_or_draw flag from API
    if (winOrDraw == true) {
      if (home >= away) return '1X';
      return 'X2';
    }

    // Winner object
    if (winner != null) {
      final name = winner['name']?.toString() ?? '';
      final comment = (winner['comment'] ?? '').toString().toLowerCase();
      if (comment.contains('win or draw')) {
        if (name == homeName) return '1X';
        if (name == awayName) return 'X2';
      } else {
        if (name == homeName) return home >= 50 ? '1' : '1X';
        if (name == awayName) return away >= 50 ? '2' : 'X2';
      }
    }

    // Advice text
    if (advice != null && advice.isNotEmpty) {
      final a = advice.toLowerCase();
      if (a.contains(homeName.toLowerCase()) || a.contains('home')) {
        return a.contains('draw') ? '1X' : '1';
      }
      if (a.contains(awayName.toLowerCase()) || a.contains('away')) {
        return a.contains('draw') ? 'X2' : '2';
      }
      if (a.contains('draw')) return '1X'; // prefer double chance over pure X
    }

    // Default: lean to the higher side with double chance (safer)
    if (home >= away) return '1X';
    return 'X2';
  }

  static String? _pickGoalsTip(
      String? underOver, int home, int away, int draw) {
    if (underOver != null && underOver.isNotEmpty) {
      final raw = underOver.toLowerCase();
      if (raw.contains('over') || raw.startsWith('+')) {
        return _cleanOverUnder(underOver, isOver: true);
      }
      if (raw.contains('under') || raw.startsWith('-')) {
        return _cleanOverUnder(underOver, isOver: false);
      }
    }

    // Heuristic from probabilities: open games lean Over, tight games Under
    final totalAttackSignal = home + away;
    if (totalAttackSignal >= 100 || (home >= 50 && away >= 30)) {
      return 'Over 1.5';
    }
    if (draw >= 40 && home < 40 && away < 40) {
      return 'Under 3.5';
    }
    return 'Over 1.5';
  }

  static String? _pickBttsTip(
      int home, int away, int draw, String? underOver) {
    // Both sides with decent chance → GG
    if (home >= 30 && away >= 30) return 'GG';

    // Very one-sided → NG more likely
    if ((home >= 60 && away <= 20) || (away >= 60 && home <= 20)) {
      return 'NG';
    }

    // Over markets often correlate with GG
    if (underOver != null &&
        (underOver.toLowerCase().contains('over') ||
            underOver.startsWith('+'))) {
      return 'GG';
    }

    return 'GG';
  }

  static void _fillToAtLeastThree({
    required List<String> tips,
    required int home,
    required int away,
    required int draw,
    required String? underOver,
    required String? resultTip,
  }) {
    // Team to score
    if (!tips.any((t) => t == 'GG' || t == 'NG')) {
      tips.add(home >= 30 && away >= 30 ? 'GG' : 'Home score');
    }

    if (tips.length < 3) {
      if (!tips.any((t) => t.toLowerCase().contains('over') ||
          t.toLowerCase().contains('under'))) {
        tips.add('Over 1.5');
      }
    }

    if (tips.length < 3) {
      // Double chance opposite of pure result if needed
      if (resultTip == '1') {
        tips.add('1X');
      } else if (resultTip == '2') {
        tips.add('X2');
      } else if (resultTip == 'X') {
        // User complaint: pure X is often weak — add safer cover
        tips.add(home >= away ? '1X' : 'X2');
      } else {
        tips.add(home >= away ? '1X' : 'X2');
      }
    }

    if (tips.length < 3) {
      tips.add('Over 2.5');
    }
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
      predictions: const ['Home ML', 'Over 210.5', 'Home -3.5'],
      confidence: 'Low',
      advice: 'Basketball tips are limited on free plan',
    );
  }

  static String _cleanOverUnder(String raw, {required bool isOver}) {
    final number =
        RegExp(r'[0-9]+\.?[0-9]*').firstMatch(raw)?.group(0) ?? '2.5';
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
