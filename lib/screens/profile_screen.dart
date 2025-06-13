import 'package:flutter/material.dart';
import 'package:sipandu/models/user_profile.dart';
import 'package:sipandu/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

UserProfile? _globalUserProfile;

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_globalUserProfile != null) {
        setState(() {
          _userProfile = _globalUserProfile;
          _isLoading = false;
        });
        return;
      }

      final dummyProfile = UserProfile(
        id: '1',
        email: 'user@example.com',
        name: 'Pengguna Sipandu',
        phone: '081234567890',
        address: 'Jl. Contoh No. 123, Jakarta',
        avatarUrl: null,
        createdAt: DateTime.now(),
      );

      _globalUserProfile = dummyProfile;

      if (mounted) {
        setState(() {
          _userProfile = dummyProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateProfile(UserProfile updatedProfile) {
    _globalUserProfile = updatedProfile;

    if (mounted) {
      setState(() {
        _userProfile = updatedProfile;
      });
    }
  }

  void _navigateToEditProfile() {
    if (_userProfile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userProfile: _userProfile!,
          onProfileUpdated: _updateProfile,
        ),
      ),
    );
  }

  void _logout() {
    _globalUserProfile = null;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    // Ganti '/login' dengan route yang sesuai untuk halaman login/register Anda
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_isLoading && _userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_userProfile == null
              ? const Center(child: Text('Profil tidak ditemukan'))
              : _buildProfileContent()),
    );
  }

  Widget _buildProfileContent() {
    if (_userProfile == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _userProfile!.avatarUrl != null
                ? NetworkImage(_userProfile!.avatarUrl!)
                : null,
            child: _userProfile!.avatarUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile!.email,
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
                value: _userProfile!.email,
              ),
              InfoItem(
                icon: Icons.phone,
                title: 'Telepon',
                value: _userProfile!.phone ?? 'Belum diatur',
              ),
              InfoItem(
                icon: Icons.home,
                title: 'Alamat',
                value: _userProfile!.address ?? 'Belum diatur',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informasi Akun',
            items: [
              InfoItem(
                icon: Icons.calendar_today,
                title: 'Bergabung Sejak',
                value:
                    '${_userProfile!.createdAt.day}/${_userProfile!.createdAt.month}/${_userProfile!.createdAt.year}',
              ),
              InfoItem(
                icon: Icons.verified_user,
                title: 'ID Pengguna',
                value: _userProfile!.id,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _logout,
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
