import 'package:flutter/material.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/screens/profile_screen.dart';
import 'package:sipandu/services/report_service.dart';
import 'package:sipandu/screens/report_detail_screen.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/services/pocketbase_client.dart';

// Asumsi file ini ada di project Anda untuk halaman edit profil
import 'package:sipandu/screens/edit_profile_screen.dart';

// ======================================================================
// BAGIAN UTAMA DASHBOARD ADMIN
// ======================================================================

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  int _selectedIndex = 0;

  // Daftar widget untuk Bottom Navigation Bar
  static final List<Widget> _widgetOptions = <Widget>[
    const AdminReportsView(), // Halaman utama daftar laporan
    const AdminProfilePage(), // Halaman profil yang di-wrap
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ======================================================================
// WIDGET UNTUK MENAMPILKAN DAFTAR LAPORAN (VIEW UTAMA ADMIN)
// ======================================================================

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  late Future<List<Report>> _allReportsFuture;
  final PocketBase _pb = PocketBaseClient.instance;

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() {
    setState(() {
      _allReportsFuture = ReportService.getAllReportsForAdmin();
    });
  }

  // --- FUNGSI HELPER UNTUK TAMPILAN ---

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange.shade800;
      case ReportStatus.inProcess:
        return Colors.blue.shade800;
      case ReportStatus.resolved:
        return Colors.green.shade800;
      case ReportStatus.rejected:
        return Colors.red.shade800;
      case ReportStatus.unknown:
      default:
        return Colors.grey.shade800;
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
      default:
        return 'Tidak Diketahui';
    }
  }

  // --- FUNGSI HELPER UNTUK LOGIKA ---

  // PERBAIKAN UTAMA: Menerjemahkan enum ke string yang valid di database
  String _statusEnumToStringForDb(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'menunggu';
      case ReportStatus.inProcess:
        return 'diproses';
      case ReportStatus.resolved:
        return 'selesai';
      case ReportStatus.rejected:
        return 'ditolak';
      case ReportStatus.unknown:
        return 'menunggu'; // Nilai fallback
    }
  }

  Future<void> _changeReportStatus(Report report, ReportStatus newStatus) async {
    final oldStatus = report.status;
    setState(() => report.status = newStatus); // Optimistic UI update

    try {
      // Gunakan fungsi penerjemah saat mengirim data ke server
      final body = {'status': _statusEnumToStringForDb(newStatus)};
      await _pb.collection('laporan').update(report.id, body: body);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status laporan "${report.title}" berhasil diubah.'),
        backgroundColor: Colors.green,
      ));
      // Tidak perlu panggil _loadAllReports() lagi karena UI sudah diupdate
      setState(() {}); 

    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Gagal mengubah status: $e';
      if (e is ClientException) {
        errorMessage = 'Gagal mengubah status: ${e.response['data']}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
      setState(() => report.status = oldStatus); // Kembalikan status jika gagal
    }
  }

  void _showStatusChangeDialog(Report report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Status Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportStatus.values
                .where((s) => s != ReportStatus.unknown)
                .map((status) => ListTile(
                      title: Text(_getStatusText(status), style: TextStyle(color: _getStatusColor(status))),
                      onTap: () {
                        Navigator.of(context).pop();
                        _changeReportStatus(report, status);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            )
          ],
        );
      },
    );
  }

  Widget _buildThumbnail(List<String> images) {
    if (images.isEmpty) {
      return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.image_not_supported, color: Colors.grey[400]));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images.first,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[400])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Masuk'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllReports)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllReports(),
        child: FutureBuilder<List<Report>>(
          future: _allReportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
            }
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return const Center(child: Text('Tidak ada laporan tersedia.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ReportDetailScreen(reportId: report.id)));
                      if (result == true) _loadAllReports();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
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
                                    Text(report.title,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('Oleh: ${report.reporter?.name ?? report.userId}',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(report.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
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
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(_getStatusText(report.status).toUpperCase(),
                                    style: TextStyle(
                                        color: _getStatusColor(report.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                              Text(report.formattedDate,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text('Ubah Status'),
                              onPressed: () => _showStatusChangeDialog(report),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold)
                              ),
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


// ======================================================================
// HALAMAN PROFIL ADMIN (WRAPPER)
// ======================================================================

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Admin'),
      ),
      // Memanggil ProfileScreen yang sudah kita perbaiki agar mandiri
      // Tidak perlu passing userData lagi
      body: ProfileScreen(),
    );
  }
}