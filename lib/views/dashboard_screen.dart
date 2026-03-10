import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: SummaryCard(), // Özet bilgi kartı
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
                (context, index) => const ProjectCard(),
                childCount: 4, // Örnek sayı
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.black,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text("Yeni Proje", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});
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
          Text("Bugün ilgilenmen gereken 3 aktif projen var.", 
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key});
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
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage("https://picsum.photos/400/300"), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Modern Ofis", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Şişli / İstanbul", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}