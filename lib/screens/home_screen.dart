import 'package:flutter/material.dart';
import '../models/match_prediction.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_chip.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSport = 'football';
  bool _isLoading = true;
  String? _error;
  List<MatchPrediction> _today = [];
  List<MatchPrediction> _week = [];

  // Filters
  String? _selectedLeague;
  String? _selectedConfidence;
  String? _selectedMarket;

  final List<Map<String, dynamic>> _sports = [
    {'id': 'football', 'name': 'Football', 'icon': '⚽'},
    {'id': 'basketball', 'name': 'Basketball', 'icon': '🏀'},
    {'id': 'tennis', 'name': 'Tennis', 'icon': '🎾'},
    {'id': 'hockey', 'name': 'Hockey', 'icon': '🏒'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedLeague = null;
      _selectedConfidence = null;
      _selectedMarket = null;
    });

    try {
      final result = await ApiService.getPredictions(sport: _selectedSport);
      setState(() {
        _today = result['today'] ?? [];
        _week = result['week'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MatchPrediction> _applyFilters(List<MatchPrediction> list) {
    var filtered = list;
    if (_selectedLeague != null) {
      filtered = filtered.where((m) => m.league == _selectedLeague).toList();
    }
    if (_selectedConfidence != null) {
      filtered = filtered.where((m) => m.confidence == _selectedConfidence).toList();
    }
    if (_selectedMarket != null) {
      filtered = filtered.where((m) => m.predictions.contains(_selectedMarket)).toList();
    }
    return filtered;
  }

  Set<String> get _availableLeagues {
    final all = [..._today, ..._week];
    return all.map((e) => e.league).toSet();
  }

  Set<String> get _availableMarkets {
    final all = [..._today, ..._week];
    final markets = <String>{};
    for (final m in all) {
      markets.addAll(m.predictions);
    }
    return markets;
  }

  @override
  Widget build(BuildContext context) {
    final filteredToday = _applyFilters(_today);
    final filteredWeek = _applyFilters(_week);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  const Text(
                    'Edge',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Smart picks',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    icon: const Icon(Icons.history_rounded),
                    tooltip: 'My Picks',
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    ),
                    icon: const Icon(Icons.analytics_outlined),
                    tooltip: 'Analytics',
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // Sport Categories
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _sports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final sport = _sports[index];
                  final isSelected = _selectedSport == sport['id'];
                  return SportChip(
                    label: '${sport['icon']} ${sport['name']}',
                    isSelected: isSelected,
                    onTap: () {
                      if (_selectedSport != sport['id']) {
                        setState(() => _selectedSport = sport['id']);
                        _loadData();
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Filters row
            if (!_isLoading && _error == null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _filterChip(
                      label: _selectedLeague ?? 'League',
                      selected: _selectedLeague != null,
                      onTap: () => _showFilterSheet(
                        title: 'Filter by League',
                        options: _availableLeagues.toList()..sort(),
                        current: _selectedLeague,
                        onSelected: (v) => setState(() => _selectedLeague = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: _selectedConfidence ?? 'Confidence',
                      selected: _selectedConfidence != null,
                      onTap: () => _showFilterSheet(
                        title: 'Filter by Confidence',
                        options: ['High', 'Medium', 'Low'],
                        current: _selectedConfidence,
                        onSelected: (v) => setState(() => _selectedConfidence = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: _selectedMarket ?? 'Market',
                      selected: _selectedMarket != null,
                      onTap: () => _showFilterSheet(
                        title: 'Filter by Market',
                        options: _availableMarkets.toList()..sort(),
                        current: _selectedMarket,
                        onSelected: (v) => setState(() => _selectedMarket = v),
                      ),
                    ),
                    if (_selectedLeague != null ||
                        _selectedConfidence != null ||
                        _selectedMarket != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedLeague = null;
                          _selectedConfidence = null;
                          _selectedMarket = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Today (${filteredToday.length})'),
                  Tab(text: 'This Week (${filteredWeek.length})'),
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
                                  onPressed: _loadData,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(filteredToday, 'No matches match your filters'),
                            _buildList(filteredWeek, 'No matches match your filters'),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C853).withOpacity(0.2)
              : const Color(0xFF1A1D23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF00C853) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF00C853) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet({
    required String title,
    required List<String> options,
    required String? current,
    required Function(String?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('All'),
                      trailing: current == null
                          ? const Icon(Icons.check, color: Color(0xFF00C853))
                          : null,
                      onTap: () {
                        onSelected(null);
                        Navigator.pop(context);
                      },
                    ),
                    ...options.map((o) => ListTile(
                          title: Text(o),
                          trailing: current == o
                              ? const Icon(Icons.check,
                                  color: Color(0xFF00C853))
                              : null,
                          onTap: () {
                            onSelected(o);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<MatchPrediction> matches, String emptyMessage) {
    if (matches.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 15)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return MatchCard(
          match: matches[index],
          onSave: () async {
            await StorageService.savePick(matches[index]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved to My Picks'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }
}
