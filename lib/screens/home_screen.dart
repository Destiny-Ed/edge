import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_prediction.dart';
import '../providers/picks_provider.dart';
import '../services/api_service.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSport = 'football';
  bool _isLoading = true;
  String? _error;
  List<MatchPrediction> _matches = [];

  String? _leagueFilter;
  String? _confidenceFilter;
  String? _marketFilter;

  final _sports = [
    {'id': 'football', 'name': 'Football', 'icon': '⚽'},
    {'id': 'basketball', 'name': 'Basketball', 'icon': '🏀'},
    {'id': 'tennis', 'name': 'Tennis', 'icon': '🎾'},
    {'id': 'hockey', 'name': 'Hockey', 'icon': '🏒'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _leagueFilter = null;
      _confidenceFilter = null;
      _marketFilter = null;
    });

    try {
      final data = await ApiService.getTodayPredictions(_selectedSport);
      setState(() {
        _matches = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MatchPrediction> get _filtered {
    var list = _matches;
    if (_leagueFilter != null) {
      list = list.where((m) => m.league == _leagueFilter).toList();
    }
    if (_confidenceFilter != null) {
      list = list.where((m) => m.confidence == _confidenceFilter).toList();
    }
    if (_marketFilter != null) {
      list = list.where((m) => m.predictions.contains(_marketFilter)).toList();
    }
    return list;
  }

  Set<String> get _leagues => _matches.map((e) => e.league).toSet();
  Set<String> get _markets {
    final s = <String>{};
    for (final m in _matches) {
      s.addAll(m.predictions);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final picks = context.watch<PicksProvider>();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Edge',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Sports
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _sports.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = _sports[i];
                return SportChip(
                  label: '${s['icon']} ${s['name']}',
                  isSelected: _selectedSport == s['id'],
                  onTap: () {
                    if (_selectedSport != s['id']) {
                      setState(() => _selectedSport = s['id'] as String);
                      _load();
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Filters as dropdown buttons
          if (!_isLoading && _error == null && _matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _DropdownFilter(
                      label: 'League',
                      value: _leagueFilter,
                      options: _leagues.toList()..sort(),
                      onChanged: (v) => setState(() => _leagueFilter = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DropdownFilter(
                      label: 'Confidence',
                      value: _confidenceFilter,
                      options: const ['High', 'Medium', 'Low'],
                      onChanged: (v) => setState(() => _confidenceFilter = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DropdownFilter(
                      label: 'Market',
                      value: _marketFilter,
                      options: _markets.toList()..sort(),
                      onChanged: (v) => setState(() => _marketFilter = v),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C853)))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matches for today',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final m = _filtered[i];
                              final saved =
                                  picks.isSaved(m.sport, m.fixtureId);
                              return MatchCard(
                                match: m,
                                isSaved: saved,
                                onSave: saved
                                    ? null
                                    : () async {
                                        await picks.savePick(m);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Saved to My Picks'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
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

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D23) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? const Color(0xFF00C853)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              )),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All $label',
                  style: const TextStyle(fontSize: 13)),
            ),
            ...options.map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
