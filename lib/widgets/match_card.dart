import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/match_prediction.dart';

class MatchCard extends StatelessWidget {
  final MatchPrediction match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEE, d MMM');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context),
          onLongPress: () {
            final text = '${match.homeTeam} vs ${match.awayTeam}\n'
                '${match.predictions.join(" • ")}\n'
                '${match.advice ?? ""}';
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied — ready for SportyBet'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // League + Time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${match.country} • ${match.league}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(match.kickOff)} • ${timeFormat.format(match.kickOff)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Teams
                Row(
                  children: [
                    _teamLogo(match.homeLogo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.homeTeam,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'vs',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match.awayTeam,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _teamLogo(match.awayLogo),
                  ],
                ),

                const SizedBox(height: 16),

                // Prediction chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: match.predictions.map((tip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00C853).withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (match.confidence != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Confidence: ${match.confidence}',
                    style: TextStyle(
                      color: match.confidence == 'High'
                          ? const Color(0xFF00C853)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamLogo(String? url) {
    if (url == null) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 28,
      height: 28,
      placeholder: (_, __) => const SizedBox(width: 28, height: 28),
      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 22),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                match.league,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              if (match.advice != null) ...[
                const Text('Advice', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(match.advice!),
                const SizedBox(height: 16),
              ],
              const Text('Tips for SportyBet',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: match.predictions
                    .map((t) => Chip(
                          label: Text(t),
                          backgroundColor:
                              const Color(0xFF00C853).withOpacity(0.2),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final text =
                        '${match.homeTeam} vs ${match.awayTeam} → ${match.predictions.join(", ")}';
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Copied! Paste into SportyBet')),
                    );
                  },
                  child: const Text('Copy for SportyBet'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
