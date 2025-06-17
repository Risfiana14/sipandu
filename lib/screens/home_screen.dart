import 'package:flutter/material.dart';
import 'package:sipandu/screens/create_report_screen.dart';
import 'package:sipandu/screens/profile_screen.dart';
import 'package:sipandu/screens/report_list_screen.dart';
import 'package:sipandu/models/report.dart'; // Import model Report
import 'package:sipandu/services/report_service.dart'; // Import ReportService
import 'package:sipandu/screens/report_detail_screen.dart'; // Import ReportDetailScreen untuk navigasi

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(
        userData: widget.userData,
        onViewAllPressed: _navigateToReports,
        onReportCreated:
            _refreshHomeContent, // Tambahkan callback untuk refresh
      ),
      const ReportListScreen(), // Halaman daftar laporan penuh
      ProfileScreen(userData: widget.userData),
    ];
  }

  void _navigateToReports() {
    setState(() {
      _selectedIndex = 1; // Navigasi ke tab "Laporan"
    });
  }

  // Fungsi ini akan dipanggil saat laporan baru berhasil dibuat
  void _refreshHomeContent() {
    // Memaksa HomeContent untuk di-rebuild dan mengambil data terbaru
    setState(() {
      _screens[0] = HomeContent(
        userData: widget.userData,
        onViewAllPressed: _navigateToReports,
        onReportCreated: _refreshHomeContent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

class HomeContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onViewAllPressed;
  final VoidCallback onReportCreated; // Callback baru

  const HomeContent({
    super.key,
    required this.userData,
    required this.onViewAllPressed,
    required this.onReportCreated, // Inisialisasi callback
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
    // Ambil laporan terbaru dari layanan, batasi jumlahnya jika perlu
    _recentReportsFuture = ReportService
        .getUserReports(); // ReportService mengambil semua, kita filter di sini
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
      default:
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
      default:
        return 'Tidak Diketahui';
    }
  }

  Widget _buildThumbnail(List<String> images) {
    if (images.isEmpty) {
      return Container(
        width: 60, // Ukuran thumbnail lebih kecil untuk list di home
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images.first,
        width: 60, // Ukuran thumbnail lebih kecil
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading thumbnail in HomeContent: $error');
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image, color: Colors.grey),
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Laporkan masalah di komunitas Anda dan bantu membuat perubahan',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateReportScreen(userData: widget.userData),
                          ),
                        );
                        // Jika laporan berhasil dibuat (misal, dikirim balik true/success)
                        if (result == true) {
                          widget
                              .onReportCreated(); // Panggil callback untuk refresh HomeContent
                          _loadRecentReports(); // Muat ulang laporan terbaru
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Laporan Baru'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kategori Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCategoryCard(
                      context, 'Jalan', Icons.add_road, Colors.orange),
                  _buildCategoryCard(
                      context, 'Sampah', Icons.delete, Colors.green),
                  _buildCategoryCard(
                      context, 'Air', Icons.water_drop, Colors.blue),
                  _buildCategoryCard(
                      context, 'Penerangan', Icons.lightbulb, Colors.amber),
                  _buildCategoryCard(
                      context, 'Keamanan', Icons.security, Colors.red),
                  _buildCategoryCard(
                      context, 'Lainnya', Icons.more_horiz, Colors.purple),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Laporan Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: widget.onViewAllPressed,
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Implementasi Laporan Terbaru menggunakan FutureBuilder
              FutureBuilder<List<Report>>(
                future: _recentReportsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Gagal memuat laporan: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  final limitedReports =
                      reports.take(3).toList(); // Ambil hanya 3 laporan terbaru

                  if (limitedReports.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Tidak ada laporan terbaru.'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: limitedReports.length,
                    itemBuilder: (context, index) {
                      final report = limitedReports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1, // Sedikit lebih rendah dari daftar penuh
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailScreen(reportId: report.id),
                              ),
                            );
                            if (result == true) {
                              // Jika detail screen menandakan perubahan
                              _loadRecentReports(); // Refresh saat kembali dari detail
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildThumbnail(report.images),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        report.description,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getStatusColor(report.status)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(report.status),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getStatusColor(
                                                    report.status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            report.formattedDate,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                        ],
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
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateReportScreen(
              initialCategory: title,
              userData: widget.userData,
            ),
          ),
        );
        if (result == true) {
          widget.onReportCreated();
          _loadRecentReports();
        }
      },
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
