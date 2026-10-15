import 'package:flutter/material.dart';
import '../models/match_prediction.dart';
import '../services/api_service.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_chip.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // Sport Categories
            SizedBox(
              height: 48,
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

            const SizedBox(height: 12),

            // Today / This Week Tabs
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
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
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
                            _buildList(_today, emptyMessage: 'No matches today'),
                            _buildList(_week, emptyMessage: 'No matches this week'),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<MatchPrediction> matches, {required String emptyMessage}) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return MatchCard(match: matches[index]);
      },
    );
  }
}
