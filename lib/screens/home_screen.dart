// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/services/api_service.dart';
import 'package:sipandu/screens/report_detail_screen.dart';
import 'package:sipandu/screens/create_report_screen.dart';
import 'package:sipandu/screens/report_list_screen.dart';
import 'package:sipandu/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Report>> _recentReportsFuture;
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
  }

  void _loadRecentReports() {
    setState(() {
      _recentReportsFuture = _apiService.getAllReports().then((rawList) {
        return rawList.map((mapData) => Report.fromJson(mapData)).toList();
      });
    });
  }

  void _onCategoryTap(String categoryName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menampilkan kategori: $categoryName')),
    );
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
                    color: const Color(0xff3b82f6),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20), 
              ],
            ),
          );
        },
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Tombol Beranda
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        color: _currentIndex == 0 ? Colors.blue : Colors.grey,
                      ),
                      Text(
                        'Beranda',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentIndex == 0 ? Colors.blue : Colors.grey,
                          fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Tombol Laporan (Untuk melihat list semua laporan terbaru)
              InkWell(
                onTap: () async {
                  setState(() {
                    _currentIndex = 1;
                  });
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportListScreen(),
                    ),
                  );
                  setState(() {
                    _currentIndex = 0;
                  });
                  _loadRecentReports();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment,
                        color: _currentIndex == 1 ? Colors.blue : Colors.grey,
                      ),
                      Text(
                        'Laporan',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentIndex == 1 ? Colors.blue : Colors.grey[600],
                          fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Tombol Tambah
              InkWell(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateReportScreen(userData: widget.userData),
                    ),
                  );
                  if (result == true) _loadRecentReports();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xff4caf50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Tombol Profil
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: _currentIndex == 2 ? Colors.blue : Colors.grey,
                      ),
                      Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentIndex == 2 ? Colors.blue : Colors.grey,
                          fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onCategoryTap(label),
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
      ),
    );
  }
}