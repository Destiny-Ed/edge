import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/match_prediction.dart';

class ApiService {
  // ⚠️ Replace with your real API key from https://dashboard.api-football.com
  static const String _apiKey = 'f1fc3fa8501ef766e46d187815d2a57d';

  static const String _footballBase = 'https://v3.football.api-sports.io';
  static const String _basketballBase = 'https://v1.basketball.api-sports.io';

  static Map<String, String> get _headers => {
        'x-apisports-key': _apiKey,
      };

  static final _uuid = Uuid();

  // -------------------- FOOTBALL --------------------

  static Future<List<dynamic>> getFootballFixturesByDate(String date) async {
    final url = Uri.parse('$_footballBase/fixtures?date=$date');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Football fixtures error: ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    return data['response'] ?? [];
  }

  static Future<Map<String, dynamic>?> getFootballPrediction(int fixtureId) async {
    final url = Uri.parse('$_footballBase/predictions?fixture=$fixtureId');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final list = data['response'] as List?;
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  // -------------------- BASKETBALL (basic) --------------------

  static Future<List<dynamic>> getBasketballGamesByDate(String date) async {
    final url = Uri.parse('$_basketballBase/games?date=$date');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return data['response'] ?? [];
  }

  // -------------------- MAIN --------------------

  static Future<Map<String, List<MatchPrediction>>> getPredictions({
    required String sport,
  }) async {
    if (sport == 'football') {
      return _getFootballPredictions();
    } else if (sport == 'basketball') {
      return _getBasketballPredictions();
    }
    return {'today': [], 'week': []};
  }

  static Future<Map<String, List<MatchPrediction>>> _getFootballPredictions() async {
    final now = DateTime.now().toUtc();
    final weekFixtures = <dynamic>[];

    // Fetch 5 days only to protect free tier
    for (int i = 0; i < 5; i++) {
      final date = now.add(Duration(days: i));
      try {
        final fixtures = await getFootballFixturesByDate(_formatDate(date));
        weekFixtures.addAll(fixtures);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 350));
    }

    final upcoming = weekFixtures.where((f) {
      final status = f['fixture']['status']['short'];
      return status == 'NS' || status == 'TBD';
    }).toList();

    // Limit calls
    final limited = upcoming.take(20).toList();

    final todayPredictions = <MatchPrediction>[];
    final weekPredictions = <MatchPrediction>[];

    for (final fixture in limited) {
      final fixtureId = fixture['fixture']['id'] as int;
      final predData = await getFootballPrediction(fixtureId);
      final match = _mapFootballPrediction(fixture, predData);

      final kickOff = match.kickOff;
      final isToday = kickOff.year == now.year &&
          kickOff.month == now.month &&
          kickOff.day == now.day;

      if (isToday) todayPredictions.add(match);
      weekPredictions.add(match);

      await Future.delayed(const Duration(milliseconds: 280));
    }

    todayPredictions.sort((a, b) => a.kickOff.compareTo(b.kickOff));
    weekPredictions.sort((a, b) => a.kickOff.compareTo(b.kickOff));

    return {'today': todayPredictions, 'week': weekPredictions};
  }

  static Future<Map<String, List<MatchPrediction>>> _getBasketballPredictions() async {
    final now = DateTime.now().toUtc();
    final games = <dynamic>[];

    for (int i = 0; i < 3; i++) {
      final date = now.add(Duration(days: i));
      try {
        final list = await getBasketballGamesByDate(_formatDate(date));
        games.addAll(list);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final upcoming = games.where((g) {
      final status = g['status']?['short'] ?? g['status']?['long'] ?? '';
      return status.toString().toUpperCase().contains('NS') ||
          status.toString().toUpperCase().contains('NOT') ||
          status.toString().toUpperCase().contains('SCHEDULED');
    }).take(15).toList();

    final today = <MatchPrediction>[];
    final week = <MatchPrediction>[];

    for (final g in upcoming) {
      final match = _mapBasketballGame(g);
      final isToday = match.kickOff.year == now.year &&
          match.kickOff.month == now.month &&
          match.kickOff.day == now.day;
      if (isToday) today.add(match);
      week.add(match);
    }

    return {'today': today, 'week': week};
  }

  // -------------------- MAPPERS --------------------

  static MatchPrediction _mapFootballPrediction(
      dynamic fixture, Map<String, dynamic>? predData) {
    final teams = fixture['teams'];
    final league = fixture['league'];
    final fixtureInfo = fixture['fixture'];

    final List<String> tips = [];
    String? advice;
    String confidence = 'Unknown';
    Map<String, String>? percentages;
    String? underOver;
    bool? winOrDraw;

    if (predData != null) {
      final p = predData['predictions'];
      advice = p['advice'];
      winOrDraw = p['win_or_draw'];
      underOver = p['under_over']?.toString();

      // Percentages
      if (p['percent'] != null) {
        percentages = {
          'home': p['percent']['home']?.toString() ?? '',
          'draw': p['percent']['draw']?.toString() ?? '',
          'away': p['percent']['away']?.toString() ?? '',
        };

        final homePct = _parsePct(percentages['home']);
        final drawPct = _parsePct(percentages['draw']);
        final awayPct = _parsePct(percentages['away']);

        final maxPct = [homePct, drawPct, awayPct].reduce((a, b) => a > b ? a : b);

        if (maxPct >= 55) {
          confidence = 'High';
        } else if (maxPct >= 45) {
          confidence = 'Medium';
        } else {
          confidence = 'Low';
        }

        // Only add strong 1X2 style tips
        if (homePct >= 50 && homePct > awayPct + 8) {
          tips.add('1');
        } else if (awayPct >= 50 && awayPct > homePct + 8) {
          tips.add('2');
        } else if (winOrDraw == true) {
          if (homePct >= drawPct && homePct >= awayPct) {
            tips.add('1X');
          } else if (awayPct >= drawPct) {
            tips.add('X2');
          }
        } else if (drawPct >= 38) {
          tips.add('X');
        }
      }

      // Under / Over — only if clear
      if (underOver != null && underOver.isNotEmpty) {
        final uo = underOver.toLowerCase();
        if (uo.contains('over') || uo.startsWith('+')) {
          final clean = underOver.replaceAll('+', 'Over ').replaceAll('over', 'Over');
          tips.add(clean);
        } else if (uo.contains('under') || uo.startsWith('-')) {
          final clean = underOver.replaceAll('-', 'Under ').replaceAll('under', 'Under');
          tips.add(clean);
        }
      }

      // Winner comment fallback
      if (tips.isEmpty && p['winner'] != null) {
        final comment = (p['winner']['comment'] ?? '').toString().toLowerCase();
        final name = p['winner']['name'];
        if (comment.contains('win or draw')) {
          if (name == teams['home']['name']) tips.add('1X');
          else tips.add('X2');
        } else {
          if (name == teams['home']['name']) tips.add('1');
          else if (name == teams['away']['name']) tips.add('2');
        }
      }
    }

    // Clean: only keep useful, non-duplicate tips
    final cleaned = tips.toSet().toList();

    // If still empty, give a very soft fallback (better than nothing)
    if (cleaned.isEmpty) {
      cleaned.add('Review');
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
      league: league['name'],
      country: league['country'] ?? '',
      kickOff: DateTime.parse(fixtureInfo['date']).toLocal(),
      status: fixtureInfo['status']['short'],
      predictions: cleaned,
      advice: advice,
      confidence: confidence,
      percentages: percentages,
      underOver: underOver,
      winOrDraw: winOrDraw,
    );
  }

  static MatchPrediction _mapBasketballGame(dynamic g) {
    final teams = g['teams'] ?? {};
    final home = teams['home'] ?? {};
    final away = teams['away'] ?? {};
    final league = g['league'] ?? {};
    final date = g['date'] ?? g['datetime'] ?? DateTime.now().toIso8601String();

    // Basketball has weaker free prediction data → keep simple
    final tips = <String>['Home or Away', 'Over 200.5']; // placeholder style

    return MatchPrediction(
      id: _uuid.v4(),
      fixtureId: g['id'] ?? 0,
      sport: 'basketball',
      homeTeam: home['name'] ?? 'Home',
      awayTeam: away['name'] ?? 'Away',
      homeLogo: home['logo'],
      awayLogo: away['logo'],
      league: league['name'] ?? 'Basketball',
      country: league['country']?['name'] ?? '',
      kickOff: DateTime.tryParse(date.toString())?.toLocal() ?? DateTime.now(),
      status: g['status']?['short'] ?? 'NS',
      predictions: tips,
      confidence: 'Low',
      advice: 'Basketball predictions are limited on free tier',
    );
  }

  static int _parsePct(String? value) {
    if (value == null) return 0;
    return int.tryParse(value.replaceAll('%', '').trim()) ?? 0;
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
