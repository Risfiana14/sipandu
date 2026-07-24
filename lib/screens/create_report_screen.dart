// lib/screens/create_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateReportScreen extends StatefulWidget {
  final String? initialCategory;
  final Map<String, dynamic> userData;

  const CreateReportScreen({
    super.key,
    required this.userData,
    this.initialCategory,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  LatLng _selectedLocation = LatLng(-7.2575, 112.7521); // Default: Surabaya
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _categories = [
    'Jalan',
    'Sampah',
    'Air',
    'Penerangan',
    'Keamanan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? _categories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _mapController.move(_selectedLocation, _mapController.zoom);
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userData['uid'] as String? ?? 
                    widget.userData['id'] as String? ?? 
                    FirebaseAuth.instance.currentUser?.uid;

      if (userId == null || userId.isEmpty) {
        throw Exception("ID Pengguna tidak ditemukan. Silakan coba login kembali.");
      }

      // Kirim data laporan langsung ke Firebase Firestore tanpa array gambar
      await _db.collection('laporan_masyarakat').add({
        'user_id': userId,
        'judul': _titleController.text.trim(),
        'kategori': _selectedCategory,
        'deskripsi': _descriptionController.text.trim(),
        'status': 'menunggu',
        'lokasi': {
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi Kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: 'Judul Laporan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category)),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Jelaskan detail masalah di sini...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty
                  ? 'Deskripsi tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: 24),
            const Text('Pilih Lokasi Kejadian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation,
                    zoom: 15.0,
                    onTap: _handleTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'id.app.sipandu',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
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
                child: Text('Ketuk pada peta untuk memilih lokasi',
                    style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitReport,
                icon: _isLoading ? Container() : const Icon(Icons.send),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KIRIM LAPORAN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}