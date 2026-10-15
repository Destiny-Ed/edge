import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_prediction.dart';

class ApiService {
  // ⚠️ Replace with your real API key from https://dashboard.api-football.com
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  static const String _footballBase = 'https://v3.football.api-sports.io';

  static Map<String, String> get _headers => {
        'x-apisports-key': _apiKey,
      };

  /// Get fixtures for a specific date (Football)
  static Future<List<dynamic>> getFootballFixturesByDate(String date) async {
    final url = Uri.parse('$_footballBase/fixtures?date=$date');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load fixtures: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    return data['response'] ?? [];
  }

  /// Get prediction for a single fixture
  static Future<Map<String, dynamic>?> getFootballPrediction(int fixtureId) async {
    final url = Uri.parse('$_footballBase/predictions?fixture=$fixtureId');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    final list = data['response'] as List?;
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  /// Main method: Get today's + this week's predictions
  static Future<Map<String, List<MatchPrediction>>> getPredictions({
    required String sport, // 'football' or 'basketball'
  }) async {
    if (sport != 'football') {
      // Football is fully supported. Other sports can be expanded later.
      return {'today': [], 'week': []};
    }

    final now = DateTime.now().toUtc();
    final weekFixtures = <dynamic>[];

    // Fetch today + next 6 days (careful with free tier limits)
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = _formatDate(date);
      try {
        final fixtures = await getFootballFixturesByDate(dateStr);
        weekFixtures.addAll(fixtures);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final todayPredictions = <MatchPrediction>[];
    final weekPredictions = <MatchPrediction>[];

    // Only process upcoming matches (NS = Not Started)
    final upcoming = weekFixtures.where((f) {
      final status = f['fixture']['status']['short'];
      return status == 'NS' || status == 'TBD';
    }).toList();

    // Limit to top ~25 matches to stay within free plan
    final limited = upcoming.take(25).toList();

    for (final fixture in limited) {
      final fixtureId = fixture['fixture']['id'] as int;
      final predData = await getFootballPrediction(fixtureId);

      final match = _mapToMatchPrediction(fixture, predData);

      final kickOff = DateTime.parse(fixture['fixture']['date']).toLocal();
      final isToday = kickOff.year == now.year &&
          kickOff.month == now.month &&
          kickOff.day == now.day;

      if (isToday) {
        todayPredictions.add(match);
      }
      weekPredictions.add(match);

      await Future.delayed(const Duration(milliseconds: 250));
    }

    // Sort by kick-off time
    todayPredictions.sort((a, b) => a.kickOff.compareTo(b.kickOff));
    weekPredictions.sort((a, b) => a.kickOff.compareTo(b.kickOff));

    return {
      'today': todayPredictions,
      'week': weekPredictions,
    };
  }

  static MatchPrediction _mapToMatchPrediction(
      dynamic fixture, Map<String, dynamic>? predData) {
    final teams = fixture['teams'];
    final league = fixture['league'];
    final fixtureInfo = fixture['fixture'];

    final List<String> tips = [];
    String? advice;
    String? confidence;
    Map<String, String>? percentages;

    if (predData != null) {
      final predictions = predData['predictions'];
      advice = predictions['advice'];

      // Winner / Double chance
      if (predictions['winner'] != null) {
        final winnerName = predictions['winner']['name'];
        final comment = predictions['winner']['comment'] ?? '';
        if (comment.toLowerCase().contains('win or draw')) {
          if (winnerName == teams['home']['name']) {
            tips.add('1X');
          } else {
            tips.add('X2');
          }
        } else {
          if (winnerName == teams['home']['name']) {
            tips.add('1');
          } else if (winnerName == teams['away']['name']) {
            tips.add('2');
          }
        }
      }

      // Under / Over
      final underOver = predictions['under_over'];
      if (underOver != null) {
        if (underOver.toString().startsWith('+') ||
            underOver.toString().toLowerCase().contains('over')) {
          tips.add(underOver.toString().replaceAll('+', 'Over '));
        } else if (underOver.toString().startsWith('-')) {
          tips.add('Under ${underOver.toString().substring(1)}');
        } else {
          tips.add(underOver.toString());
        }
      }

      // Percentages + simple confidence
      if (predictions['percent'] != null) {
        percentages = {
          'home': predictions['percent']['home'] ?? '',
          'draw': predictions['percent']['draw'] ?? '',
          'away': predictions['percent']['away'] ?? '',
        };

        final homePct = int.tryParse(
                (predictions['percent']['home'] as String).replaceAll('%', '')) ??
            0;
        final awayPct = int.tryParse(
                (predictions['percent']['away'] as String).replaceAll('%', '')) ??
            0;
        final maxPct = homePct > awayPct ? homePct : awayPct;
        if (maxPct >= 55) {
          confidence = 'High';
        } else if (maxPct >= 45) {
          confidence = 'Medium';
        } else {
          confidence = 'Low';
        }
      }
    }

    // Fallback simple tips if API prediction is missing
    if (tips.isEmpty) {
      tips.addAll(['1X', 'Over 1.5']);
    }

    // Add GG as a common useful market
    if (!tips.contains('GG') && !tips.contains('BTTS')) {
      tips.add('GG');
    }

    return MatchPrediction(
      fixtureId: fixtureInfo['id'],
      homeTeam: teams['home']['name'],
      awayTeam: teams['away']['name'],
      homeLogo: teams['home']['logo'],
      awayLogo: teams['away']['logo'],
      league: league['name'],
      country: league['country'] ?? '',
      kickOff: DateTime.parse(fixtureInfo['date']).toLocal(),
      status: fixtureInfo['status']['short'],
      predictions: tips.toSet().toList(),
      advice: advice,
      confidence: confidence,
      percentages: percentages,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
