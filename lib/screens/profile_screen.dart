import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart'; // Correct import for PocketBase
import 'package:sipandu/screens/edit_profile_screen.dart';
import 'package:sipandu/services/pocketbase_client.dart';

const String pocketBaseUrl = 'http://127.0.0.1:8090';

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
      final record =
          await _pb.collection('users').update(id, body: updatedData);
      print('Update profile response: ${record.data}'); // Debugging
      return record.data;
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (_pb.authStore.isValid) {
        final record =
            await _pb.collection('users').getOne(_pb.authStore.model.id);
        print('Fetched user data: ${record.data}'); // Debugging
        return record.data;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
}

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userData = Map.from(widget.userData);
    _loadUserData();
    print('Initial userData: $_userData'); // Debugging for avatar
  }

  Future<void> _loadUserData() async {
    if (_userData.isNotEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData != null) {
        setState(() {
          _userData = userData;
        });
        print(
            'Loaded userData with avatar: ${_userData['avatar']}'); // Debugging
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_userData.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedData = await AuthService.updateProfile(
        id: _userData['id'] as String,
        name: _userData['name'] as String? ?? '',
        phone: _userData['phone'] as int?,
        address: _userData['address'] as String? ?? '',
      );

      if (updatedData != null) {
        setState(() {
          _userData = updatedData;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: _userData,
          onProfileUpdated: (updatedData) {
            setState(() {
              _userData = updatedData;
            });
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _userData['avatar'] != null
                ? NetworkImage(
                    '$pocketBaseUrl/api/files/users/${_userData['id']}/${_userData['avatar']}')
                : null,
            child: _userData['avatar'] == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userData['name'] ?? 'Pengguna Sipandu',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userData['email'] ?? 'Tidak ada email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            title: 'Informasi Kontak',
            items: [
              InfoItem(
                icon: Icons.email,
                title: 'Email',
                value: _userData['email'] ?? 'Tidak diatur',
              ),
              InfoItem(
                icon: Icons.phone,
                title: 'Telepon',
                value: (_userData['phone'] ?? '').toString(),
              ),
              InfoItem(
                icon: Icons.home,
                title: 'Alamat',
                value: _userData['address'] ?? 'Belum diatur',
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
                value: _userData['id'] ?? 'Tidak diketahui',
              ),
              InfoItem(
                icon: Icons.check_circle,
                title: 'Terverifikasi',
                value: (_userData['verified'] ?? false) ? 'Ya' : 'Tidak',
              ),
              InfoItem(
                icon: Icons.visibility,
                title: 'Email Visibilitas',
                value: (_userData['emailVisibility'] ?? false)
                    ? 'Publik'
                    : 'Pribadi',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _navigateToEditProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
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
