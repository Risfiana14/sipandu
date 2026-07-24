// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/services/api_service.dart'; // Menggunakan ApiService Firebase
import 'package:sipandu/screens/report_detail_screen.dart';
import 'package:sipandu/screens/create_report_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Report>> _recentReportsFuture;
  final ApiService _apiService = ApiService(); // Instance ApiService Firebase

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
  }

  void _loadRecentReports() {
    setState(() {
      // Mengambil semua data dari Firebase dan dikonversi ke model objek Report
      _recentReportsFuture = _apiService.getAllReports().then((rawList) {
        return rawList.map((mapData) => Report.fromJson(mapData)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sipandu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentReports,
          )
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Report>>(
        future: _recentReportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          
          final reports = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1. HERO CARD (BANNER BIRU SELAMAT DATANG)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff3b82f6), // Warna biru sesuai UI mockup
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat datang, Pengguna!',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Laporkan masalah di komunitas Anda dan bantu membuat perubahan',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff3b82f6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateReportScreen(userData: widget.userData),
                            ),
                          );
                          if (result == true) _loadRecentReports();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Buat Laporan Baru', 
                          style: TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. KATEGORI LAPORAN (GRID 3 KOLOM)
                const Text(
                  'Kategori Laporan',
                  style: TextStyle(fontSize: 16, fontFamily: 'sans-serif', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [
                    _buildCategoryItem(Icons.edit_road, 'Jalan', Colors.orange[50]!, Colors.orange),
                    _buildCategoryItem(Icons.delete, 'Sampah', Colors.green[50]!, Colors.green),
                    _buildCategoryItem(Icons.opacity, 'Air', Colors.blue[50]!, Colors.blue),
                    _buildCategoryItem(Icons.lightbulb, 'Penerangan', Colors.yellow[50]!, Colors.amber),
                    _buildCategoryItem(Icons.shield, 'Keamanan', Colors.red[50]!, Colors.red),
                    _buildCategoryItem(Icons.more_horiz, 'Lainnya', Colors.purple[50]!, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. SEKSI LAPORAN TERBARU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Laporan Terbaru',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // Aksi ketika tombol Lihat Semua ditekan
                      },
                      child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tampilan jika data kosong
                if (reports.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Belum ada laporan masuk.'),
                    ),
                  )
                else
                  // LIST DAFTAR LAPORAN TERBARU
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reports.length > 5 ? 5 : reports.length, // Batasi maks 5 item
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      
                      // Cek apakah ada gambar di dalam list images laporan
                      final hasImage = report.images.isNotEmpty && 
                          report.images.first.toLowerCase().startsWith('http');

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: hasImage
                                  ? Image.network(
                                      report.images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, color: Colors.grey);
                                      },
                                    )
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          title: Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            report.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            report.formattedDate,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportDetailScreen(reportId: report.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff4caf50), // Warna hijau tombol laporan sesuai mockup
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateReportScreen(userData: widget.userData),
            ),
          );
          if (result == true) _loadRecentReports();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // Helper Widget untuk membuat Item Kategori dengan background bundar & bayangan halus
  Widget _buildCategoryItem(IconData icon, String label, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              color: Colors.black87
            ),
          ),
        ],
      ),
    );
  }
}