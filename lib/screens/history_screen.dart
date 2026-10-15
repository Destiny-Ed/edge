import 'package:flutter/material.dart';
import '../models/match_prediction.dart';
import '../services/storage_service.dart';
import '../widgets/match_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MatchPrediction> _picks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final picks = await StorageService.getSavedPicks();
    picks.sort((a, b) => b.kickOff.compareTo(a.kickOff));
    setState(() {
      _picks = picks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Picks'),
        actions: [
          if (_picks.isNotEmpty)
            TextButton(
              onPressed: () async {
                // optional: clear all
              },
              child: const Text(''),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _picks.isEmpty
              ? const Center(
                  child: Text(
                    'No saved picks yet.\nSave predictions from the home screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _picks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pick = _picks[index];
                    return MatchCard(
                      match: pick,
                      showResultActions: true,
                      onResultChanged: (result) async {
                        await StorageService.updatePickResult(pick.id, result);
                        _load();
                      },
                    );
                  },
                ),
    );
  }
}
