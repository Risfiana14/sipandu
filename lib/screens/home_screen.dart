import 'package:flutter/material.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/screens/create_report_screen.dart';
import 'package:sipandu/screens/profile_screen.dart';
import 'package:sipandu/screens/report_detail_screen.dart';
import 'package:sipandu/screens/report_list_screen.dart';
import 'package:sipandu/services/report_service.dart';

class HomeScreen extends StatefulWidget {
  // userData masih diperlukan untuk diteruskan ke halaman lain seperti CreateReport
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Key unik untuk HomeContent, digunakan untuk memicu rebuild penuh saat refresh
  Key _homeContentKey = UniqueKey();

  // Daftar screen tidak perlu dibuat di initState agar key bisa diperbarui
  List<Widget> _getScreens() => [
        HomeContent(
          key: _homeContentKey, // Gunakan key di sini
          userData: widget.userData,
          onViewAllPressed: () => _onItemTapped(1), // Pindah ke tab Laporan
          onNavigate: _navigateAndRefresh, // Teruskan fungsi navigasi
        ),
        const ReportListScreen(),
        // ProfileScreen sudah diubah menjadi mandiri (tidak butuh userData di constructor)
        ProfileScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi ini akan memaksa HomeContent untuk dibuat ulang dengan data baru
  void _refreshHomeContent() {
    setState(() {
      _homeContentKey = UniqueKey();
    });
  }
  
  // Fungsi terpusat untuk navigasi yang mungkin memerlukan refresh setelahnya
  void _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );

    // Jika halaman yang dituju (misal Create/Detail) mengembalikan true,
    // refresh konten halaman beranda
    if (result == true && mounted) {
      _refreshHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// WIDGET KONTEN UTAMA HALAMAN BERANDA
// =======================================================================

class HomeContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onViewAllPressed;
  final void Function(Widget) onNavigate;

  const HomeContent({
    super.key,
    required this.userData,
    required this.onViewAllPressed,
    required this.onNavigate,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Report>> _recentReportsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
  }

  void _loadRecentReports() {
    setState(() {
      _recentReportsFuture = ReportService.getUserReports();
    });
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProcess:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Menunggu';
      case ReportStatus.inProcess:
        return 'Diproses';
      case ReportStatus.resolved:
        return 'Selesai';
      case ReportStatus.rejected:
        return 'Ditolak';
      case ReportStatus.unknown:
        return 'Tidak Diketahui';
    }
  }

  Widget _buildThumbnail(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrls.first,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.broken_image, color: Colors.grey[400]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipandu'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadRecentReports(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KARTU SELAMAT DATANG ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang, ${widget.userData['name'] ?? 'Pengguna'}!',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Laporkan masalah di komunitas Anda dan bantu membuat perubahan.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(
                          CreateReportScreen(userData: widget.userData),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Buat Laporan Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // --- JUDUL KATEGORI ---
                const Text('Kategori Laporan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // --- GRID KATEGORI ---
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildCategoryCard(context, 'Jalan', Icons.add_road_outlined, Colors.orange),
                    _buildCategoryCard(context, 'Sampah', Icons.delete_outline, Colors.green),
                    _buildCategoryCard(context, 'Air', Icons.water_drop_outlined, Colors.blue),
                    _buildCategoryCard(context, 'Penerangan', Icons.lightbulb_outline, Colors.amber),
                    _buildCategoryCard(context, 'Keamanan', Icons.security_outlined, Colors.red),
                    _buildCategoryCard(context, 'Lainnya', Icons.more_horiz_outlined, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
                // --- JUDUL LAPORAN TERBARU ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Laporan Terbaru',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: widget.onViewAllPressed,
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // --- DAFTAR LAPORAN TERBARU ---
                FutureBuilder<List<Report>>(
                  future: _recentReportsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
                    }
                    final reports = snapshot.data ?? [];
                    if (reports.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Tidak ada laporan terbaru.'),
                      ));
                    }
                    // Batasi hanya 3 laporan di halaman beranda
                    final limitedReports = reports.take(3).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: limitedReports.length,
                      itemBuilder: (context, index) {
                        final report = limitedReports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => widget.onNavigate(ReportDetailScreen(reportId: report.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildThumbnail(report.images),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(report.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(report.description,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(report.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getStatusText(report.status).toUpperCase(),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: _getStatusColor(report.status),
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () => widget.onNavigate(
        CreateReportScreen(
          initialCategory: title,
          userData: widget.userData,
        ),
      ),
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}