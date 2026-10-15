import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/picks_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PicksProvider>().getAnalytics();
    final total = data['total'] as int;

    return SafeArea(
      child: total == 0
          ? const Center(
              child: Text(
                'No settled picks yet.\nMark picks as Won/Lost to see analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _card('Total', '${data['total']}', Colors.white70),
                    const SizedBox(width: 10),
                    _card('Won', '${data['won']}', const Color(0xFF00C853)),
                    const SizedBox(width: 10),
                    _card('Lost', '${data['lost']}', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _card(
                      'Accuracy',
                      '${(data['accuracy'] as double).toStringAsFixed(1)}%',
                      const Color(0xFF00C853),
                    ),
                    const SizedBox(width: 10),
                    _card(
                      'Best Streak',
                      '${data['bestStreak']}',
                      Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('By Market',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._breakdown(data['byMarket']),
                const SizedBox(height: 24),
                const Text('By Confidence',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._breakdown(data['byConfidence']),
                const SizedBox(height: 24),
                const Text('By League',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._breakdown(data['byLeague']),
              ],
            ),
    );
  }

  Widget _card(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D23),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _breakdown(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return [const Text('No data', style: TextStyle(color: Colors.white38))];
    }

    final entries = map.entries.toList()
      ..sort((a, b) {
        final at = (a.value['won'] ?? 0) + (a.value['lost'] ?? 0);
        final bt = (b.value['won'] ?? 0) + (b.value['lost'] ?? 0);
        return bt.compareTo(at);
      });

    return entries.map((e) {
      final won = e.value['won'] ?? 0;
      final lost = e.value['lost'] ?? 0;
      final total = won + lost;
      final acc = total == 0 ? 0.0 : won / total * 100;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D23),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(e.key,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('$won-$lost',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(width: 12),
            Text('${acc.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: acc >= 55
                      ? const Color(0xFF00C853)
                      : acc >= 45
                          ? Colors.orangeAccent
                          : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }).toList();
  }
}
