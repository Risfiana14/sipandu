import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Menggunakan Firestore langsung

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
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Instance Firestore untuk simpan data

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

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (pickedImages.isNotEmpty) {
        setState(() => _selectedImages.addAll(pickedImages));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error memilih gambar: $e';
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan tambahkan minimal satu gambar')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Ambil Uid Pengguna dari properti Firestore atau Firebase Auth fallback
      final userId = widget.userData['uid'] as String? ?? 
                     widget.userData['id'] as String? ?? 
                     FirebaseAuth.instance.currentUser?.uid;

      if (userId == null || userId.isEmpty) {
        throw Exception("ID Pengguna tidak ditemukan. Silakan coba login kembali.");
      }

      // 2. Kirim data laporan langsung ke Firebase Firestore
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
        'gambar_list': _selectedImages.map((img) => img.name).toList(),
        'createdAt': FieldValue.serverTimestamp(), // Timestamp server Firebase
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
      
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lampiran Gambar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    tooltip: 'Tambah Gambar dari Galeri'),
              ],
            ),
            const SizedBox(height: 8),
            _buildImagePreview(),
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

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('Belum ada gambar yang dipilih.')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List>(
              future: _selectedImages[index].readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(snapshot.data!, fit: BoxFit.cover));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}