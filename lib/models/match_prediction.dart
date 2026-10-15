enum PickResult { pending, won, lost, voided }

class MatchPrediction {
  final String id; // unique local id
  final int fixtureId;
  final String sport; // football, basketball, etc
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String league;
  final String country;
  final DateTime kickOff;
  final String status;
  final List<String> predictions; // clean tips only
  final String? advice;
  final String confidence; // High / Medium / Low / Unknown
  final Map<String, String>? percentages;
  final String? underOver;
  final bool? winOrDraw;
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
    this.result = PickResult.pending,
    this.settledAt,
  });

  MatchPrediction copyWith({
    PickResult? result,
    DateTime? settledAt,
    List<String>? predictions,
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
      status: status,
      predictions: predictions ?? this.predictions,
      advice: advice,
      confidence: confidence,
      percentages: percentages,
      underOver: underOver,
      winOrDraw: winOrDraw,
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
