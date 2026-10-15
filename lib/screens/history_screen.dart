import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_prediction.dart';
import '../providers/picks_provider.dart';
import '../widgets/match_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final picksProvider = context.watch<PicksProvider>();
    final picks = [...picksProvider.picks]
      ..sort((a, b) => b.kickOff.compareTo(a.kickOff));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'My Picks',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: picks.isEmpty
                ? const Center(
                    child: Text(
                      'No saved picks yet.\nSave from the Today tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: picks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final pick = picks[i];
                      return MatchCard(
                        match: pick,
                        isSaved: true,
                        showResultActions: true,
                        onResultChanged: (result) {
                          picksProvider.updateResult(pick.id, result);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
