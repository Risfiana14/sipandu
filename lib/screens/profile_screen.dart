import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/screens/edit_profile_screen.dart'; // Pastikan path ini benar
import 'package:sipandu/services/pocketbase_client.dart'; // Pastikan path ini benar

const String pocketBaseUrl = 'http://159.223.74.55:8090/';

// --- PERBAIKAN PADA AUTHSERVICE ---
class AuthService {
  static final PocketBase _pb = PocketBaseClient.instance;

  static Future<void> logout() async {
    _pb.authStore.clear();
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String id,
    required String name,
    required int? phone,
    required String address,
  }) async {
    try {
      final updatedData = {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
      };
      // Fungsi update tidak kita ubah agar tidak memengaruhi EditProfileScreen
      final record = await _pb.collection('users').update(id, body: updatedData);
      return record.data;
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  // PERUBAIKAN 1: Mengubah return type menjadi RecordModel?
  // Ini penting agar kita bisa mengakses data lengkap termasuk file.
  static Future<RecordModel?> getCurrentUserData() async {
    try {
      if (_pb.authStore.isValid) {
        final record = await _pb.collection('users').getOne(_pb.authStore.model.id);
        print('Fetched user record: $record'); // Debugging
        return record; // <-- Mengembalikan seluruh RecordModel
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
}

// --- PERBAIKAN PADA PROFILE SCREEN ---
class ProfileScreen extends StatefulWidget {
  // Kita hapus parameter userData dari constructor agar screen ini mandiri
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // PERUBAIKAN 2: Mengubah tipe state menjadi RecordModel?
  RecordModel? _userData;
  bool _isLoading = true; // Langsung set true karena kita akan fetch data
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Langsung panggil fungsi untuk memuat data saat screen dibuka
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Pastikan state di-set loading
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userData = await AuthService.getCurrentUserData();
      if (mounted) { // Selalu cek 'mounted' sebelum setState di async operation
        setState(() {
          if (userData != null) {
            _userData = userData;
            print('Loaded userData with avatar: ${_userData!.data['avatar']}');
          } else {
            _errorMessage = 'Gagal memuat data pengguna';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error memuat data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditProfile() {
    if (_userData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          // Kirim data sebagai Map agar EditProfileScreen tidak perlu diubah
          userData: _userData!.toJson(),
          onProfileUpdated: (updatedData) {
            // Saat kembali, muat ulang data dari server untuk memastikan konsistensi
            _loadUserData();
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          // Tambahkan tombol refresh untuk memudahkan debugging
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      // Tampilkan loading indicator atau profile content
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? Center(child: Text(_errorMessage ?? 'Data tidak ditemukan.'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    // Ambil instance PocketBase
    final pb = PocketBaseClient.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // PERUBAIKAN 3: Menggunakan pb.getFileUrl untuk menampilkan avatar
          CircleAvatar(
            radius: 50,
            backgroundImage: (_userData!.data['avatar'] != null &&
                    _userData!.data['avatar'].isNotEmpty)
                ? NetworkImage(
                    // Membuat URL aman yang berisi token sementara
                    pb.getFileUrl(_userData!, _userData!.data['avatar']).toString(),
                  )
                : null,
            child: (_userData!.data['avatar'] == null ||
                    _userData!.data['avatar'].isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          // PERUBAIKAN 4: Mengakses data melalui _userData.data['...']
          Text(
            _userData!.data['name']?.toString() ?? 'Pengguna Sipandu',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userData!.data['email']?.toString() ?? 'Tidak ada email',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            title: 'Informasi Kontak',
            items: [
              InfoItem(
                icon: Icons.email,
                title: 'Email',
                value: _userData!.data['email']?.toString() ?? 'Tidak diatur',
              ),
              InfoItem(
                icon: Icons.phone,
                title: 'Telepon',
                value: _userData!.data['phone']?.toString() ?? 'Belum diatur',
              ),
              InfoItem(
                icon: Icons.home,
                title: 'Alamat',
                value: _userData!.data['address']?.toString() ?? 'Belum diatur',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informasi Akun',
            items: [
              InfoItem(
                icon: Icons.verified_user,
                title: 'ID Pengguna',
                value: _userData!.id, // ID bisa diakses langsung
              ),
              InfoItem(
                icon: Icons.check_circle,
                title: 'Terverifikasi',
                value: _userData!.data['verified'] == true ? 'Ya' : 'Tidak',
              ),
              InfoItem(
                icon: Icons.visibility,
                title: 'Email Visibilitas',
                value: _userData!.data['emailVisibility'] == true ? 'Publik' : 'Pribadi',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<InfoItem> items}) {
    // Widget ini tidak perlu diubah
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                            Text(item.value, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class InfoItem {
  // Class ini tidak perlu diubah
  final IconData icon;
  final String title;
  final String value;

  InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}