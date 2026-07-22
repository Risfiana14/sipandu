import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:sipandu/screens/edit_profile_screen.dart'; // Pastikan path ini benar

// --- PERBAIKAN PADA AUTHSERVICE ---
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final updatedData = {
        'name': name,
        'phone': phone,
        'address': address,
      };
      
      // Update data pada dokumen pengguna di Firestore
      await _db.collection('users').doc(id).update(updatedData);
      
      // Kembalikan data map lengkap agar kompatibel
      updatedData['uid'] = id;
      return updatedData;
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  // Mengubah return type menjadi Map<String, dynamic>? yang diambil dari Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          data['uid'] = userDoc.id; // Menyisipkan UID dokumen Firestore
          print('Fetched user record: $data'); // Debugging
          return data;
        }
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
  // Constructor mandiri tanpa parameter userData kaku
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mengubah tipe state menjadi Map untuk menampung data dokumen Firestore
  Map<String, dynamic>? _userData;
  bool _isLoading = true; 
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userData = await AuthService.getCurrentUserData();
      if (mounted) { 
        setState(() {
          if (userData != null) {
            _userData = userData;
            print('Loaded userData with avatar: ${_userData!['avatar']}');
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
          userData: _userData!,
          onProfileUpdated: (updatedData) {
            // Memuat ulang data dari Firestore untuk memastikan sinkronisasi UI
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? Center(child: Text(_errorMessage ?? 'Data tidak ditemukan.'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final String? avatarUrl = _userData!['avatar'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Menggunakan logika pemuatan gambar dari URL String Firestore
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty || !avatarUrl.startsWith('http'))
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userData!['name']?.toString() ?? 'Pengguna Sipandu',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userData!['email']?.toString() ?? 'Tidak ada email',
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
                value: _userData!['email']?.toString() ?? 'Tidak diatur',
              ),
              InfoItem(
                icon: Icons.phone,
                title: 'Telepon',
                value: _userData!['phone']?.toString() ?? 'Belum diatur',
              ),
              InfoItem(
                icon: Icons.home,
                title: 'Alamat',
                value: _userData!['address']?.toString() ?? 'Belum diatur',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informasi Akun',
            items: [
              InfoItem(
                icon: Icons.verified_user,
                title: 'ID Pengguna (UID)',
                value: _userData!['uid']?.toString() ?? 'Tidak ada ID', 
              ),
              InfoItem(
                icon: Icons.check_circle,
                title: 'Role / Peran',
                value: (_userData!['role']?.toString() ?? 'user').toUpperCase(),
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

  Widget _buildInfoCard({required String title, required List<InfoItem> items}) {
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
  final IconData icon;
  final String title;
  final String value;

  InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}