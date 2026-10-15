import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/match_prediction.dart';

class MatchCard extends StatelessWidget {
  final MatchPrediction match;
  final bool isSaved;
  final bool isLiveCard;
  final VoidCallback? onSave;
  final bool showResultActions;
  final Function(PickResult)? onResultChanged;

  const MatchCard({
    super.key,
    required this.match,
    this.isSaved = false,
    this.isLiveCard = false,
    this.onSave,
    this.showResultActions = false,
    this.onResultChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEE, d MMM');

    Color confColor;
    switch (match.confidence) {
      case 'High':
        confColor = const Color(0xFF00C853);
        break;
      case 'Medium':
        confColor = Colors.orangeAccent;
        break;
      case 'Live':
        confColor = Colors.redAccent;
        break;
      default:
        confColor = isDark ? Colors.white54 : Colors.black45;
    }

    final borderColor = isSaved
        ? const Color(0xFF00C853).withOpacity(0.6)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black12);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSaved ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context),
          onLongPress: () {
            final text =
                '${match.homeTeam} vs ${match.awayTeam}\n${match.predictions.join(" • ")}\n${match.advice ?? ""}';
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${match.country.isNotEmpty ? "${match.country} • " : ""}${match.league}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLiveCard && match.elapsed != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${match.elapsed}'",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${dateFormat.format(match.kickOff)} • ${timeFormat.format(match.kickOff)}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _logo(match.homeLogo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.homeTeam,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLiveCard || match.isFinished)
                      Text(
                        '${match.homeGoals ?? 0} - ${match.awayGoals ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        match.awayTeam,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _logo(match.awayLogo),
                  ],
                ),
                if (!isLiveCard) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: match.predictions.map((tip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: confColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          match.confidence,
                          style: TextStyle(
                            color: confColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSaved) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Saved',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (onSave != null)
                        TextButton.icon(
                          onPressed: onSave,
                          icon: const Icon(Icons.bookmark_add_outlined,
                              size: 18),
                          label: const Text('Save'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white70 : Colors.black54,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
                if (showResultActions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _resultBtn('Won', PickResult.won, Colors.green),
                      const SizedBox(width: 8),
                      _resultBtn('Lost', PickResult.lost, Colors.redAccent),
                      const SizedBox(width: 8),
                      _resultBtn('Void', PickResult.voided, Colors.grey),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultBtn(String label, PickResult result, Color color) {
    final selected = match.result == result;
    return Expanded(
      child: GestureDetector(
        onTap: () => onResultChanged?.call(result),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(String? url) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? Colors.white54 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${match.league} • ${match.country}',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMM • HH:mm').format(match.kickOff),
                style: TextStyle(color: muted, fontSize: 13),
              ),
              if (match.percentages != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Win Probabilities',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _pct(context, 'Home', match.percentages!['home'] ?? '-'),
                    const SizedBox(width: 8),
                    _pct(context, 'Draw', match.percentages!['draw'] ?? '-'),
                    const SizedBox(width: 8),
                    _pct(context, 'Away', match.percentages!['away'] ?? '-'),
                  ],
                ),
              ],
              if (match.advice != null && match.advice!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'API Advice',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(match.advice!, style: TextStyle(color: onSurface)),
              ],
              if (match.underOver != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Under/Over signal: ${match.underOver}',
                  style: TextStyle(color: muted),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Tips',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: match.predictions
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        backgroundColor:
                            const Color(0xFF00C853).withOpacity(0.2),
                        labelStyle: const TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
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
                        content: Text('Copied! Paste into SportyBet'),
                      ),
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

  Widget _pct(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
