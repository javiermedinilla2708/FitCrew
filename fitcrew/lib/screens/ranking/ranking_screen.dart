import 'package:fitcrew/core/utils/app_constants.dart';
import 'package:fitcrew/services/api_service.dart';
import 'package:fitcrew/viewmodels/stats_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// RankingScreen
// Pantalla de ranking global y por deporte con estadísticas
// obtenidas desde la API REST de Python
// ============================================================

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  late TabController _tabController;
  String _selectedSport = 'Todos';

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Cargamos datos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        backgroundColor: _colorFondoFrio,
        surfaceTintColor: _colorFondoFrio,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Ranking",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -1,
          ),
        ),

        // --- Tabs: Global / Por Deporte ---
        bottom: TabBar(
          controller: _tabController,
          labelColor: _colorVerdeBosque,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _colorVerdeBosque,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Global"),
            Tab(text: "Por deporte"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Tab 1: Ranking Global ---
          _buildGlobalRankingTab(),

          // --- Tab 2: Ranking por Deporte ---
          _buildSportRankingTab(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: TAB RANKING GLOBAL
  // ----------------------------------------------------------
  Widget _buildGlobalRankingTab() {
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        // --- Mis estadísticas arriba ---
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Card de mis estadísticas ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMyStatsCard(vm),
              ),
            ),

            // --- Título del ranking ---
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "🏆 Top jugadores",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colorVerdeBosque,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // --- Lista del ranking ---
            if (vm.isLoadingRanking)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _colorVerdeBosque),
                ),
              )
            else if (vm.rankingError != null)
              SliverFillRemaining(child: _buildEmptyState(vm.rankingError!))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildRankingCard(vm.globalRanking[index]),
                    childCount: vm.globalRanking.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: TAB RANKING POR DEPORTE
  // ----------------------------------------------------------
  Widget _buildSportRankingTab() {
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // --- Selector de deporte ---
            _buildSportSelector(vm),

            // --- Lista del ranking ---
            Expanded(
              child: vm.isLoadingRanking
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _colorVerdeBosque,
                      ),
                    )
                  : vm.rankingError != null
                  ? _buildEmptyState(vm.rankingError!)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      itemCount: vm.globalRanking.length,
                      itemBuilder: (context, index) =>
                          _buildRankingCard(vm.globalRanking[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CARD DE MIS ESTADÍSTICAS
  // ----------------------------------------------------------
  Widget _buildMyStatsCard(StatsViewModel vm) {
    if (vm.isLoadingStats) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: _colorVerdeBosque,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final stats = vm.userStats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorVerdeBosque,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _colorVerdeBosque.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Título ---
          const Row(
            children: [
              Icon(Icons.person_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Mis estadísticas",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Datos en fila ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: "Posts",
                value: "${stats?.totalPosts ?? 0}",
                icon: Icons.photo_camera_outlined,
              ),
              _buildStatDivider(),
              _buildStatItem(
                label: "Actividades",
                value: "${stats?.totalActivitiesJoined ?? 0}",
                icon: Icons.sports_outlined,
              ),
              _buildStatDivider(),
              _buildStatItem(
                label: "Racha",
                value: "${stats?.currentStreakDays ?? 0}d",
                icon: Icons.local_fire_department_outlined,
              ),
              _buildStatDivider(),
              _buildStatItem(
                label: "Organizado",
                value: "${stats?.totalActivitiesOrganized ?? 0}",
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),

          // --- Deporte favorito ---
          if (stats?.favoriteSport != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppConstants.getSportIcon(stats!.favoriteSport!),
                    color: _colorVerdeMenta,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Deporte favorito: ${stats.favoriteSport}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: _colorVerdeMenta, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CARD DE RANKING
  // ----------------------------------------------------------
  Widget _buildRankingCard(RankingEntry entry) {
    // Medallas para el top 3
    final Map<int, Color> medalColors = {
      1: const Color(0xFFFFD700), // Oro
      2: const Color(0xFFC0C0C0), // Plata
      3: const Color(0xFFCD7F32), // Bronce
    };

    final bool isTopThree = entry.position <= 3;
    final Color medalColor = medalColors[entry.position] ?? _colorVerdeBosque;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isTopThree
            ? Border.all(color: medalColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: _colorVerdeBosque.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- Posición / Medalla ---
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree
                  ? medalColor.withOpacity(0.15)
                  : _colorVerdeMenta.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTopThree
                  ? Text(
                      ["🥇", "🥈", "🥉"][entry.position - 1],
                      style: const TextStyle(fontSize: 20),
                    )
                  : Text(
                      "${entry.position}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _colorVerdeBosque,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // --- Avatar con inicial ---
          CircleAvatar(
            radius: 22,
            backgroundColor: _colorVerdeMenta,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: _colorVerdeBosque,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // --- Nombre y deporte favorito ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _colorTextoTitulo,
                  ),
                ),
                if (entry.favoriteSport != null)
                  Row(
                    children: [
                      Icon(
                        AppConstants.getSportIcon(entry.favoriteSport!),
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.favoriteSport!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // --- Total actividades ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${entry.totalActivities}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _colorVerdeBosque,
                ),
              ),
              Text(
                "actividades",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: SELECTOR DE DEPORTE
  // ----------------------------------------------------------
  Widget _buildSportSelector(StatsViewModel vm) {
    final sports = ['Todos', ...AppConstants.availableSports];

    return Container(
      height: 50,
      color: _colorFondoFrio,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sports.length,
        itemBuilder: (context, index) {
          final sport = sports[index];
          final selected = _selectedSport == sport;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedSport = sport);
              if (sport == 'Todos') {
                vm.loadGlobalRanking();
              } else {
                vm.loadSportRanking(sport);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? _colorVerdeBosque : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _colorVerdeBosque : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  sport,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[600],
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: ESTADO VACÍO
  // ----------------------------------------------------------
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 60, color: _colorVerdeMenta),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
