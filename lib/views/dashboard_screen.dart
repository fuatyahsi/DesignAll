import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_project_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Supabase Stream: Veritabanındaki değişimleri anlık dinler
    final _projectsStream = Supabase.instance.client
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at');

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: Text("Projelerim", 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _projectsStream,
        builder: (context, snapshot) {
          // 1. Yüklenme Durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          // 2. Veri Yoksa veya Boşsa
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.folderOpen, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Henüz hiç proje eklenmemiş.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final projects = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: SummaryCard(count: projects.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        title: project['name'] ?? 'İsimsiz Proje',
                        location: project['location'] ?? 'Konum Belirtilmedi',
                        imageUrl: project['image_url'],
                      );
                    },
                    childCount: projects.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );
        },
        backgroundColor: Colors.black,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text("Yeni Proje", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final int count;
  const SummaryCard({super.key, required this.count});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hoş geldin Fuat,", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text("Bugün ilgilenmen gereken $count aktif projen var.", 
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final String title;
  final String location;
  final String? imageUrl;

  const ProjectCard({
    super.key, 
    required this.title, 
    required this.location, 
    this.imageUrl
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: imageUrl != null 
                  ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                  : null,
                color: Colors.grey[200],
              ),
              child: imageUrl == null ? const Center(child: Icon(LucideIcons.image)) : null,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(location, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}