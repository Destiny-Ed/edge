import 'package:flutter/material.dart';
import '../models/match_prediction.dart';
import '../services/api_service.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_chip.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  String _sport = 'football';
  bool _loading = true;
  List<MatchPrediction> _live = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getLiveScores(_sport);
      setState(() {
        _live = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                if (_live.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_live.length} live',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SportChip(
                  label: '⚽ Football',
                  isSelected: _sport == 'football',
                  onTap: () {
                    setState(() => _sport = 'football');
                    _load();
                  },
                ),
                const SizedBox(width: 10),
                SportChip(
                  label: '🏀 Basketball',
                  isSelected: _sport == 'basketball',
                  onTap: () {
                    setState(() => _sport = 'basketball');
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C853)))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _live.isEmpty
                        ? const Center(
                            child: Text(
                              'No live matches right now',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _live.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => MatchCard(
                              match: _live[i],
                              isLiveCard: true,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
