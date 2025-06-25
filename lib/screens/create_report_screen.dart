import 'dart:convert'; // Untuk jsonEncode
import 'dart:typed_data'; // Untuk FutureBuilder Image.memory
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart'; // Impor PocketBase
import 'package:http/http.dart' as http; // Impor untuk MultipartRequest
import 'package:sipandu/services/pocketbase_client.dart'; // Impor PocketBaseClient
import 'package:flutter/foundation.dart'
    show kIsWeb; // Impor untuk mendeteksi web

// Impor File secara kondisional. Ini penting untuk kompatibilitas web.
// Di web, dart:io tidak tersedia, jadi kita menggunakan dummy File dari dart:html
// yang tidak akan pernah dipakai karena XFile langsung dibaca bytes-nya.
// Tapi import ini diperlukan agar kode tidak error saat parsing.
import 'dart:io' if (dart.library.html) 'dart:html';

const String pocketBaseUrl = 'http://159.223.74.55:8090'; // URL PocketBase Anda

class CreateReportScreen extends StatefulWidget {
  /// Parameter untuk mengisi kategori secara otomatis jika diakses dari
  /// shortcut kategori di halaman utama.
  final String? initialCategory;

  /// Map yang berisi data pengguna yang sedang login,
  /// terutama 'id' dan 'name'.
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
  // Global key untuk validasi form.
  final _formKey = GlobalKey<FormState>();

  // Controller untuk setiap input field.
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  // State untuk menyimpan data dari form.
  LatLng _selectedLocation =
      LatLng(-7.2575, 112.7521); // Lokasi default: Surabaya, Indonesia
  String? _selectedCategory;
  final List<XFile> _selectedImages = []; // Tetap gunakan XFile
  bool _isLoading = false;
  String? _errorMessage; // Untuk menampilkan pesan error

  // Instance untuk memilih gambar.
  final ImagePicker _picker = ImagePicker();

  // PocketBase instance
  final PocketBase _pb = PocketBaseClient.instance;

  // List opsi untuk dropdown kategori.
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
    // Debugging: Print userData received by CreateReportScreen
    print(
        'CreateReportScreen: userData received in initState: ${widget.userData}');
    print(
        'CreateReportScreen: userData ID in initState: ${widget.userData['id']}');
    print(
        'CreateReportScreen: PocketBase authStore model ID: ${_pb.authStore.model.id}');

    // Set kategori awal dari parameter widget jika ada.
    _selectedCategory = widget.initialCategory ?? _categories[0];
  }

  @override
  void dispose() {
    // Selalu dispose controller untuk membebaskan memori.
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Fungsi yang dipanggil saat pengguna mengetuk peta untuk memilih lokasi.
  void _handleTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      // Tambahkan debugging di sini untuk memastikan _selectedLocation terupdate
      print(
          'CreateReportScreen: Lokasi peta dipilih: Latitude ${location.latitude}, Longitude ${location.longitude}');
    });
    // Pindahkan view peta ke lokasi yang baru dipilih.
    _mapController.move(_selectedLocation, _mapController.zoom);
  }

  /// Fungsi untuk membuka galeri dan memilih beberapa gambar.
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage(
        imageQuality: 70, // Kompres gambar untuk mengurangi ukuran
        maxWidth: 1024, // Ubah resolusi untuk mengurangi ukuran
      );
      if (pickedImages.isNotEmpty) {
        setState(() => _selectedImages.addAll(pickedImages));
      }
    } catch (e) {
      if (!mounted) return; // Pastikan widget masih ada di tree
      setState(() {
        _errorMessage = 'Error memilih gambar: $e';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error memilih gambar: $e')));
    }
  }

  /// Fungsi untuk menghapus gambar yang sudah dipilih.
  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  /// Fungsi utama untuk mengirim laporan.
  Future<void> _submitReport() async {
    // 1. Validasi form.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validasi gambar.
    if (_selectedImages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Silakan tambahkan minimal satu gambar')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
    });

    try {
      // 3. Ambil ID pengguna. Prioritaskan dari userData, fallback ke authStore.model.id
      final userId = widget.userData['id'] as String? ?? _pb.authStore.model.id;

      print(
          'CreateReportScreen: Attempting to get userId. widget.userData[\'id\']: ${widget.userData['id']}');
      print(
          'CreateReportScreen: PocketBase authStore model ID: ${_pb.authStore.model.id}');
      print('CreateReportScreen: Final userId to use: $userId');

      if (userId == null || userId.isEmpty) {
        throw Exception(
            "ID Pengguna tidak ditemukan. Silakan coba login kembali.");
      }

      // Debugging: Confirm userId before use
      print('CreateReportScreen: userId found: $userId');

      // Tambahkan debugging lokasi sebelum dikirim
      print(
          'CreateReportScreen: _selectedLocation Latitude before submission: ${_selectedLocation.latitude}');
      print(
          'CreateReportScreen: _selectedLocation Longitude before submission: ${_selectedLocation.longitude}');

      // **Mulai Proses Pengiriman Data ke PocketBase dengan MultipartRequest**
      // Ini adalah cara yang tepat untuk mengirim data teks dan file (gambar).
      final request = http.MultipartRequest(
        'POST', // Menggunakan POST untuk membuat record baru
        Uri.parse('$pocketBaseUrl/api/collections/laporan/records'),
      );

      // Tambahkan field teks ke request
      request.fields['user_id'] = userId;
      request.fields['judul'] = _titleController.text;
      request.fields['kategori'] = _selectedCategory!; // Pastikan tidak null
      request.fields['deskripsi'] = _descriptionController.text;

      // Konversi lokasi menjadi string JSON untuk field 'json' di PocketBase
      final String lokasiJson = jsonEncode({
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
      });
      print(
          'CreateReportScreen: Lokasi JSON being sent: $lokasiJson'); // Debugging JSON yang dikirim
      request.fields['lokasi'] = lokasiJson;

      // **PERBAIKAN UTAMA: Set status ke nilai yang valid dari PocketBase**
      // Berdasarkan gambar, opsi yang valid adalah 'menunggu', 'diproses', 'selesai'.
      request.fields['status'] = 'menunggu';

      // Tambahkan file gambar ke request
      for (var i = 0; i < _selectedImages.length; i++) {
        // Baca bytes dari XFile. Ini bekerja di semua platform (mobile, desktop, web).
        final bytes = await _selectedImages[i].readAsBytes();

        request.files.add(http.MultipartFile.fromBytes(
          'gambar', // Nama field di PocketBase Anda untuk gambar
          bytes,
          filename: _selectedImages[i].name, // Sertakan nama file asli
          // contentType: MediaType('image', 'jpeg'), // Opsional: tentukan content type jika perlu validasi ketat
        ));
      }

      // Tambahkan header autentikasi
      request.headers
          .addAll({'Authorization': 'Bearer ${_pb.authStore.token}'});

      // Kirim request
      final response = await request.send();

      // Tangani respons
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Laporan berhasil dibuat (200 OK atau 201 Created)
        final responseBody = await http.Response.fromStream(response);
        final jsonData = jsonDecode(responseBody.body);
        print(
            'PocketBase response for report creation: $jsonData'); // Debugging

        if (!mounted) return; // Pastikan widget masih ada di tree
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } else {
        // Ada kesalahan dari server PocketBase
        final errorBody = await response.stream.bytesToString();
        print(
            'CreateReportScreen: Failed to submit report. Status: ${response.statusCode}, Body: $errorBody'); // Debugging
        throw Exception(
            'Gagal mengirim laporan: Status ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (!mounted) return; // Pastikan widget masih ada di tree
      setState(() {
        _errorMessage = e.toString();
      });
      print('CreateReportScreen: Error submitting report: $e'); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Terjadi Kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        // Pastikan widget masih ada di tree
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
            // Menampilkan pesan error jika ada
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
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Input Judul
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

            // Dropdown Kategori
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

            // Input Deskripsi
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

            // Widget Peta
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
                    // Lapisan dasar peta dari OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'id.app.sipandu', // Ganti dengan package name aplikasi Anda
                    ),
                    // Lapisan untuk menampilkan penanda (marker)
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

            // Bagian Upload Gambar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lampiran Gambar',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    tooltip: 'Tambah Gambar dari Galeri'),
              ],
            ),
            const SizedBox(height: 8),
            _buildImagePreview(),
            const SizedBox(height: 32),

            // Tombol Kirim Laporan
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

  /// Widget untuk menampilkan preview gambar yang dipilih.
  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border:
              Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
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
            // Gunakan FutureBuilder untuk menampilkan gambar dari XFile secara aman.
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
            // Tombol hapus untuk setiap gambar.
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
