enum PickResult { pending, won, lost, voided }

class MatchPrediction {
  final String id;
  final int fixtureId;
  final String sport;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String league;
  final String country;
  final DateTime kickOff;
  final String status;
  final List<String> predictions;
  final String? advice;
  final String confidence;
  final Map<String, String>? percentages;
  final String? underOver;
  final bool? winOrDraw;
  final int? homeGoals;
  final int? awayGoals;
  final String? elapsed;
  PickResult result;
  DateTime? settledAt;

  MatchPrediction({
    required this.id,
    required this.fixtureId,
    required this.sport,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    required this.league,
    required this.country,
    required this.kickOff,
    required this.status,
    required this.predictions,
    this.advice,
    this.confidence = 'Unknown',
    this.percentages,
    this.underOver,
    this.winOrDraw,
    this.homeGoals,
    this.awayGoals,
    this.elapsed,
    this.result = PickResult.pending,
    this.settledAt,
  });

  bool get isLive =>
      status == '1H' ||
      status == '2H' ||
      status == 'HT' ||
      status == 'ET' ||
      status == 'BT' ||
      status == 'P' ||
      status == 'LIVE';

  bool get isFinished =>
      status == 'FT' || status == 'AET' || status == 'PEN';

  MatchPrediction copyWith({
    PickResult? result,
    DateTime? settledAt,
    List<String>? predictions,
    int? homeGoals,
    int? awayGoals,
    String? status,
    String? elapsed,
  }) {
    return MatchPrediction(
      id: id,
      fixtureId: fixtureId,
      sport: sport,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      league: league,
      country: country,
      kickOff: kickOff,
      status: status ?? this.status,
      predictions: predictions ?? this.predictions,
      advice: advice,
      confidence: confidence,
      percentages: percentages,
      underOver: underOver,
      winOrDraw: winOrDraw,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
      elapsed: elapsed ?? this.elapsed,
      result: result ?? this.result,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fixtureId': fixtureId,
        'sport': sport,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeLogo': homeLogo,
        'awayLogo': awayLogo,
        'league': league,
        'country': country,
        'kickOff': kickOff.toIso8601String(),
        'status': status,
        'predictions': predictions,
        'advice': advice,
        'confidence': confidence,
        'percentages': percentages,
        'underOver': underOver,
        'winOrDraw': winOrDraw,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'elapsed': elapsed,
        'result': result.name,
        'settledAt': settledAt?.toIso8601String(),
      };

  factory MatchPrediction.fromJson(Map<String, dynamic> json) {
    return MatchPrediction(
      id: json['id'],
      fixtureId: json['fixtureId'],
      sport: json['sport'] ?? 'football',
      homeTeam: json['homeTeam'],
      awayTeam: json['awayTeam'],
      homeLogo: json['homeLogo'],
      awayLogo: json['awayLogo'],
      league: json['league'],
      country: json['country'] ?? '',
      kickOff: DateTime.parse(json['kickOff']),
      status: json['status'],
      predictions: List<String>.from(json['predictions'] ?? []),
      advice: json['advice'],
      confidence: json['confidence'] ?? 'Unknown',
      percentages: json['percentages'] != null
          ? Map<String, String>.from(json['percentages'])
          : null,
      underOver: json['underOver'],
      winOrDraw: json['winOrDraw'],
      homeGoals: json['homeGoals'],
      awayGoals: json['awayGoals'],
      elapsed: json['elapsed'],
      result: PickResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => PickResult.pending,
      ),
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'])
          : null,
    );
  }
}
