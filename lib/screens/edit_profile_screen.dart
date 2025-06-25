// Hapus 'dart:io', karena tidak kompatibel dengan web.
import 'dart:typed_data'; // Impor untuk Uint8List (menampilkan gambar baru)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http; // Diperlukan untuk http.MultipartFile
import 'package:sipandu/services/pocketbase_client.dart'; // Sesuaikan path jika perlu

const String pocketBaseUrl = 'http://159.223.74.55:8090/';

class EditProfileScreen extends StatefulWidget {
  // Data yang diterima dari ProfileScreen adalah Map dari record.toJson()
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  XFile? _selectedImage;

  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final PocketBase _pb = PocketBaseClient.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Mengakses data dari Map yang diterima
    nameController = TextEditingController(text: widget.userData['name'] ?? '');
    phoneController =
        TextEditingController(text: (widget.userData['phone'] ?? '').toString());
    addressController =
        TextEditingController(text: widget.userData['address'] ?? '');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userData['id'] as String;

      final body = <String, dynamic>{
        'name': nameController.text.trim(),
        'phone': int.tryParse(phoneController.text.trim()) ?? 0,
        'address': addressController.text.trim(),
      };

      List<http.MultipartFile> files = [];
      if (_selectedImage != null) {
        files.add(http.MultipartFile.fromBytes(
          'avatar',
          await _selectedImage!.readAsBytes(),
          filename: _selectedImage!.name,
        ));
      }

      final record = await _pb
          .collection('users')
          .update(userId, body: body, files: files);

      widget.onProfileUpdated(record.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _errorMessage = 'Gagal memperbarui profil: $e';
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

  @override
  Widget build(BuildContext context) {
    String? currentAvatarUrl;
    final currentAvatarFileName = widget.userData['avatar'];
    if (currentAvatarFileName != null && currentAvatarFileName.isNotEmpty) {
      currentAvatarUrl = _pb
          .getFileUrl(
            RecordModel.fromJson(widget.userData),
            currentAvatarFileName,
          )
          .toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(color: Colors.red.shade700))),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _buildAvatarImage(currentAvatarUrl),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Ketuk gambar untuk mengganti'),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Username tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? currentAvatarUrl) {
    if (_selectedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else if (currentAvatarUrl != null) {
      return Image.network(currentAvatarUrl, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 60));
    } else {
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}