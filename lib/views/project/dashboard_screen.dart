import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import 'add_project_screen.dart';
import 'project_detail_screen.dart';
import '../ar/ar_measurement_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'completed', 'paused'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Tasarımcı';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, $userName',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.myProjects,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AR Butonu
                    _HeaderIconButton(
                      icon: LucideIcons.maximize,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ArMeasurementScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Profil / Çıkış
                    _HeaderIconButton(
                      icon: LucideIcons.logOut,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Arama ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Proje ara...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
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
              ),
            ),

            // ─── Filtre Chips ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Tümü', value: 'all', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Aktif', value: 'active', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Tamamlanan', value: 'completed', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Beklemede', value: 'paused', selected: _selectedFilter, onTap: (v) => setState(() => _selectedFilter = v)),
                    ],
                  ),
                ),
              ),
            ),

            // ─── İstatistik Kartları ─────────────────────
            SliverToBoxAdapter(
              child: projectsAsync.when(
                data: (projects) => _StatsRow(projects: projects),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ─── Proje Grid ──────────────────────────────
            projectsAsync.when(
              data: (projects) {
                // Filtrele
                var filtered = projects;
                if (_selectedFilter != 'all') {
                  filtered = filtered.where((p) => p['status'] == _selectedFilter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((p) =>
                    (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                    (p['location'] ?? '').toString().toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.folderOpen, size: 56, color: AppColors.border),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aramanızla eşleşen proje bulunamadı.'
                                : AppStrings.noProjects,
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = filtered[index];
                        return _ProjectCard(
                          project: project,
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(project: project),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Hata: $e', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddProjectScreen()),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Çıkış Yap', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

// ─── Header İkon Butonu ────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─── Filtre Chip ───────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── İstatistik Satırı ─────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> projects;

  const _StatsRow({required this.projects});

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => p['status'] == 'active' || p['status'] == null).length;
    final completed = projects.where((p) => p['status'] == 'completed').length;
    final paused = projects.where((p) => p['status'] == 'paused').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Toplam', value: '${projects.length}', color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Aktif', value: '$active', color: AppColors.statusActive)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Biten', value: '$completed', color: AppColors.statusCompleted)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Proje Kartı ───────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = project['status'] ?? 'active';
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
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppColors.softShadow,
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
                      color: AppColors.surfaceVariant,
                    ),
                    child: project['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
                            child: CachedNetworkImage(
                              imageUrl: project['image_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) => const Center(
                                child: Icon(LucideIcons.image, color: AppColors.textTertiary),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(LucideIcons.imageOff, color: AppColors.textTertiary),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(LucideIcons.image, size: 32, color: AppColors.textTertiary),
                          ),
                  ),
                  // Durum badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      project['name'] ?? 'İsimsiz Proje',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project['location'] ?? 'Konum yok',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    if (project['room_type'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project['room_type'],
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
