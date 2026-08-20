import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:sipandu/models/report.dart';
import 'package:sipandu/screens/profile_screen.dart';
import 'package:sipandu/services/api_service.dart'; // Menggunakan ApiService Firebase
import 'package:sipandu/screens/report_detail_screen.dart';
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
  final ApiService _apiService = ApiService(); // Instance ApiService Firebase

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() {
    setState(() {
      // Memanggil fungsi Firebase dari api_service.dart lalu memetakan Map data ke model objek Report
      _allReportsFuture = _apiService.getAllReports().then((rawList) {
        return rawList.map((mapData) => Report.fromJson(mapData)).toList();
      });
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

  // Menerjemahkan enum ke string yang valid di Firebase Firestore
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
      // Mengubah status dokumen menggunakan ApiService yang sudah kita miliki
      bool success = await _apiService.updateReport(report.id, {
        'status': _statusEnumToStringForDb(newStatus),
      });
      
      if (!success) throw Exception("Gagal memperbarui status di server.");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status laporan "${report.title}" berhasil diubah.'),
        backgroundColor: Colors.green,
      ));
      setState(() {}); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal mengubah status: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
      setState(() => report.status = oldStatus); // Kembalikan status asal jika gagal
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 6),

                                  // EMAIL PELAPOR
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 17,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          report.reporter?.email ??
                                              'Email tidak tersedia',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

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
                                        .withAlpha(51), // Menggantikan dengan withAlpha untuk menghindari kemunduran versi
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
      body: const ProfileScreen(), // Ditambahkan kata kunci const
    );
  }
}