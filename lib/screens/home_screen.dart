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
        title: const Text('Sipandu Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentReports,
          )
        ],
      ),
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
          if (reports.isEmpty) {
            return const Center(child: Text('Belum ada laporan masuk.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length > 5 ? 5 : reports.length, // Tampilkan 5 laporan terbaru
            itemBuilder: (context, index) {
              final report = reports[index];
              
              // Cek apakah ada gambar di dalam list images laporan
              final hasImage = report.images.isNotEmpty && report.images.first.toLowerCase().startsWith('http');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  // Menambahkan Leading Widget untuk menampilkan gambar di Halaman Utama
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateReportScreen(userData: widget.userData),
            ),
          );
          if (result == true) _loadRecentReports();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}