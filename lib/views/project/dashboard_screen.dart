import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import 'add_project_screen.dart';
import 'project_detail_screen.dart';
import '../ar/ar_measurement_screen.dart';
import '../moodboard/moodboard_screen.dart';
import '../client/client_list_screen.dart';
import '../budget/budget_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _currentNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const MoodboardScreen(),
      const ClientListScreen(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentNavIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentNavIndex == 0
          ? _buildFAB()
          : null,
    );
  }

  // ─── Ana Sayfa ──────────────────────────────────────────
  Widget _buildHomePage() {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Kullanıcı';
    final firstName = userName.split(' ').first;

    return CustomScrollView(
      slivers: [
        // ─── Hero Header ──────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                // Dekoratif elementler
                Positioned(
                  top: -20,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: -40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst bar
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'K',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merhaba, $firstName',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Projelerin seni bekliyor',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // AR Butonu
                          _GlassButton(
                            icon: LucideIcons.maximize,
                            label: 'AR',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ArMeasurementScreen()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ─── İstatistik kartları ────────
                      projectsAsync.when(
                        data: (projects) {
                          final active = projects.where((p) => p['status'] == 'active' || p['status'] == null).length;
                          final completed = projects.where((p) => p['status'] == 'completed').length;
                          return Row(
                            children: [
                              _GlassStatCard(
                                icon: LucideIcons.layers,
                                value: '${projects.length}',
                                label: 'Toplam',
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 12),
                              _GlassStatCard(
                                icon: LucideIcons.zap,
                                value: '$active',
                                label: 'Aktif',
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 12),
                              _GlassStatCard(
                                icon: LucideIcons.checkCircle,
                                value: '$completed',
                                label: 'Biten',
                                color: AppColors.purple,
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
                        },
                        loading: () => const SizedBox(height: 80),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // ─── Hızlı erişim butonları ───────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                _QuickAction(
                  icon: LucideIcons.ruler,
                  label: 'Ölçüm',
                  color: AppColors.teal,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ArMeasurementScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: LucideIcons.palette,
                  label: 'Moodboard',
                  color: AppColors.purple,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: LucideIcons.users,
                  label: 'Müşteriler',
                  color: AppColors.gold,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: LucideIcons.wallet,
                  label: 'Bütçe',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.05),
          ),
        ),

        // ─── Arama + Filtre ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                // Arama
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Proje, konum veya müşteri ara...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 12),
                        child: Icon(LucideIcons.search, size: 20, color: AppColors.textTertiary),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtreler
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Tümü', value: 'all', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Aktif', value: 'active', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v), dotColor: AppColors.statusActive),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Tamamlanan', value: 'completed', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v), dotColor: AppColors.statusCompleted),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Beklemede', value: 'paused', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v), dotColor: AppColors.statusPaused),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ),

        // ─── Başlık ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Text(
                  'Projelerim',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                projectsAsync.when(
                  data: (p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${p.length} proje',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // ─── Proje Grid ───────────────────────────
        projectsAsync.when(
          data: (projects) {
            var filtered = projects;
            if (_selectedFilter != 'all') {
              filtered = filtered.where((p) => p['status'] == _selectedFilter).toList();
            }
            if (_searchQuery.isNotEmpty) {
              filtered = filtered.where((p) =>
                (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                (p['location'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                (p['client_name'] ?? '').toString().toLowerCase().contains(_searchQuery)
              ).toList();
            }

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                child: _EmptyState(
                  hasFilter: _searchQuery.isNotEmpty || _selectedFilter != 'all',
                  onAddProject: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddProjectScreen()),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final project = filtered[index];
                    return _ProjectCard(
                      project: project,
                      index: index,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.error.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text('Bağlantı hatası', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$e', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Profil Sayfası ─────────────────────────────────────
  Widget _buildProfilePage() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Kullanıcı';
    final email = user?.email ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.cardShadow,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'T',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(userName, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(email, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            _ProfileTile(icon: LucideIcons.settings, label: 'Ayarlar', onTap: () {}),
            _ProfileTile(icon: LucideIcons.bell, label: 'Bildirimler', onTap: () {}),
            _ProfileTile(icon: LucideIcons.helpCircle, label: 'Yardım & Destek', onTap: () {}),
            _ProfileTile(icon: LucideIcons.info, label: 'Hakkında', onTap: () {}),
            const SizedBox(height: 16),
            _ProfileTile(
              icon: LucideIcons.logOut,
              label: 'Çıkış Yap',
              isDestructive: true,
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Navigation Bar ──────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: LucideIcons.home, label: 'Ana Sayfa', index: 0, current: _currentNavIndex, onTap: () => setState(() => _currentNavIndex = 0)),
              _NavItem(icon: LucideIcons.palette, label: 'Moodboard', index: 1, current: _currentNavIndex, onTap: () => setState(() => _currentNavIndex = 1)),
              _NavItem(icon: LucideIcons.users, label: 'Müşteriler', index: 2, current: _currentNavIndex, onTap: () => setState(() => _currentNavIndex = 2)),
              _NavItem(icon: LucideIcons.user, label: 'Profil', index: 3, current: _currentNavIndex, onTap: () => setState(() => _currentNavIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.accentGradient,
        boxShadow: AppColors.buttonShadow,
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddProjectScreen()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 26),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.logOut, size: 20, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text('Çıkış Yap', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Text(
          'Hesabından çıkış yapmak istediğine emin misin?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Çıkış Yap', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Glass Buton (Header için) ─────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─── Glass İstatistik Kartı ────────────────────────────
class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GlassStatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hızlı Erişim Butonu ──────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filtre Chip ──────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Proje Kartı ──────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final int index;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = project['status'] ?? 'active';
    final statusLabel = status == 'completed' ? 'Biten'
        : status == 'paused' ? 'Beklemede'
        : 'Aktif';
    final statusColor = status == 'completed'
        ? AppColors.statusCompleted
        : status == 'paused'
            ? AppColors.statusPaused
            : AppColors.statusActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      color: AppColors.surfaceVariant,
                      gradient: project['image_url'] == null
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.05),
                                AppColors.accent.withOpacity(0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: project['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: CachedNetworkImage(
                              imageUrl: project['image_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) => Center(
                                child: Icon(LucideIcons.image, color: AppColors.textTertiary.withOpacity(0.4), size: 28),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(LucideIcons.imageOff, color: AppColors.textTertiary),
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.home, size: 28, color: AppColors.primary.withOpacity(0.15)),
                                const SizedBox(height: 4),
                                Text(
                                  project['room_type'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Durum badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bilgi
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'] ?? 'İsimsiz Proje',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 12, color: AppColors.accent.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project['location'] ?? 'Konum yok',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (project['room_type'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project['room_type'],
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 80), duration: 400.ms)
        .slideY(begin: 0.05),
    );
  }
}

// ─── Boş Durum ────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAddProject;

  const _EmptyState({required this.hasFilter, required this.onAddProject});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.08), AppColors.accent.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                hasFilter ? LucideIcons.searchX : LucideIcons.layoutDashboard,
                size: 44,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter ? 'Sonuç bulunamadı' : 'Henüz proje yok',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Farklı filtreler deneyin.'
                  : 'İlk projenizi oluşturun ve\nyolculuğa başlayın.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: onAddProject,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Proje Oluştur',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profil Tile ──────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.error.withOpacity(0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDestructive ? AppColors.error.withOpacity(0.15) : AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDestructive ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight, size: 18, color: isDestructive ? AppColors.error.withOpacity(0.5) : AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
