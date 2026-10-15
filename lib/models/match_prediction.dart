class MatchPrediction {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String league;
  final String country;
  final DateTime kickOff;
  final String status;
  final List<String> predictions; // e.g. ["GG", "Over 1.5", "1X"]
  final String? advice;
  final String? confidence; // High / Medium / Low
  final Map<String, String>? percentages; // home, draw, away

  MatchPrediction({
    required this.fixtureId,
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
    this.confidence,
    this.percentages,
  });
}
