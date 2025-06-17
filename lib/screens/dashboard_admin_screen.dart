// lib/screens/dashboard_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/services/report_service.dart';
import 'package:sipandu/screens/report_detail_screen.dart'; // Untuk melihat detail laporan
import 'package:pocketbase/pocketbase.dart'; // Untuk interaksi langsung dengan PocketBase
import 'package:sipandu/services/pocketbase_client.dart'; // Untuk instance PocketBase

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late Future<List<Report>> _allReportsFuture;
  final PocketBase _pb = PocketBaseClient.instance; // Ambil instance PocketBase

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() {
    // Memuat semua laporan. Hapus filter 'user_id' jika ada di ReportService.getAllReports()
    // Kita akan buat fungsi baru di ReportService untuk admin
    _allReportsFuture = ReportService.getAllReportsForAdmin();
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

  // Fungsi untuk membangun thumbnail gambar
  Widget _buildThumbnail(List<String> images) {
    if (images.isEmpty) {
      return Container(
        width: 80,
        height: 80,
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
        images.first, // Ambil gambar pertama sebagai thumbnail
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
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
          print('Error loading thumbnail in DashboardAdminScreen: $error');
          return Container(
            width: 80,
            height: 80,
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

  // Fungsi untuk mengubah status laporan
  Future<void> _changeReportStatus(
      Report report, ReportStatus newStatus) async {
    try {
      setState(() {
        // Optimistic update: Langsung ubah status di UI
        report.status = newStatus;
      });

      // Lakukan pembaruan di PocketBase
      await _pb.collection('laporan').update(
        report.id,
        body: {
          'status': _getStatusText(newStatus).toLowerCase()
        }, // Pastikan format sesuai PB
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Status laporan ${report.title} berhasil diubah menjadi ${_getStatusText(newStatus)}')),
      );
      _loadAllReports(); // Refresh data setelah berhasil update
    } catch (e) {
      print('Error updating report status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
      // Revert optimistic update jika gagal
      setState(() {
        _loadAllReports(); // Memuat ulang dari server untuk mendapatkan status yang benar
      });
    }
  }

  // Dialog untuk memilih status baru
  void _showStatusChangeDialog(Report report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Status Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportStatus.values.map((status) {
              return ListTile(
                title: Text(_getStatusText(status)),
                onTap: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _changeReportStatus(
                      report, status); // Panggil fungsi ubah status
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadAllReports();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadAllReports();
          });
        },
        child: FutureBuilder<List<Report>>(
          future: _allReportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Terjadi kesalahan: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _loadAllReports()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.report_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Tidak ada laporan tersedia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () async {
                      // Admin juga bisa melihat detail laporan
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailScreen(reportId: report.id),
                        ),
                      );
                      if (result == true) {
                        // Jika ada perubahan dari detail
                        _loadAllReports(); // Refresh data
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        // Menggunakan Column agar bisa menampung banyak informasi
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildThumbnail(report.images),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.title,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Oleh: ${report.userId}', // Tampilkan user ID yang melaporkan
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(report.status)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(report.status),
                                  style: TextStyle(
                                    color: _getStatusColor(report.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                report.formattedDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () => _showStatusChangeDialog(report),
                              child: const Text('Ubah Status'),
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
      ),
    );
  }
}
