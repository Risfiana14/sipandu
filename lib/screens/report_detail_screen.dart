// lib/screens/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipandu/models/report.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Report> _reportFuture;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReportData();
  }

  Future<Report> _loadReportData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('laporan_masyarakat')
          .doc(widget.reportId)
          .get();

      if (!doc.exists) {
        throw Exception("Laporan tidak ditemukan.");
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; 
      
      Report report = Report.fromJson(data);

      if (report.location.latitude != 0.0 || report.location.longitude != 0.0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _mapController.move(report.location, 15.0);
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _mapController.move(LatLng(-7.2575, 112.7521), 10.0); // Default Surabaya
          }
        });
      }
      
      return report;
    } catch (error) {
      print('Error loading report for map: $error');
      rethrow;
    }
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: FutureBuilder<Report>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Terjadi kesalahan: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _reportFuture = _loadReportData();
                      });
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(report.status).withOpacity(0.15),
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
                    const Spacer(),
                    Text(
                      report.formattedDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  report.title,
                  style: const TextStyle(fontSize: 24, fontStyle: FontStyle.normal, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Deskripsi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(report.description),
                const SizedBox(height: 24),

                const Text(
                  'Lokasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: report.location,
                        zoom: 15.0,
                        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'id.app.sipandu',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: report.location,
                              width: 80,
                              height: 80,
                              builder: (context) => Icon(
                                Icons.location_pin,
                                size: 50,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                    child: Text(
                        'Lat: ${report.location.latitude.toStringAsFixed(6)}, Lon: ${report.location.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall)),
                const SizedBox(height: 24),

                if (report.response != null && report.response!.isNotEmpty) ...[
                  const Text(
                    'Tanggapan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggapan Resmi:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(report.response!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}