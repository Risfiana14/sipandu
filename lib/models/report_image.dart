import 'dart:io' as io;

class ReportImage {
  final String id;         // ID unik untuk gambar
  final String path;       // Path file di penyimpanan lokal
  final String? url;       // URL jika disimpan di cloud storage
  final DateTime createdAt; // Waktu pengambilan gambar
  final String? caption;   // Keterangan gambar (opsional)
  final String? thumbnailPath; // Path untuk thumbnail (opsional)

  ReportImage({
    required this.id,
    required this.path,
    this.url,
    required this.createdAt,
    this.caption,
    this.thumbnailPath,
  });

  // Mendapatkan File object dari path
  io.File get file => io.File(path);
  
  // Mendapatkan File object thumbnail jika ada
  io.File? get thumbnailFile => thumbnailPath != null ? io.File(thumbnailPath!) : null;

  // Memeriksa apakah file gambar ada
  bool get exists => file.existsSync();

  // Konversi ke JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'url': url,
      'created_at': createdAt.toIso8601String(),
      'caption': caption,
      'thumbnail_path': thumbnailPath,
    };
  }

  // Membuat objek dari JSON
  factory ReportImage.fromJson(Map<String, dynamic> json) {
    return ReportImage(
      id: json['id'],
      path: json['path'],
      url: json['url'],
      createdAt: DateTime.parse(json['created_at']),
      caption: json['caption'],
      thumbnailPath: json['thumbnail_path'],
    );
  }

  // Membuat thumbnail dari gambar asli
  Future<ReportImage> generateThumbnail(String savePath) async {
    // Di sini Anda bisa mengimplementasikan logika untuk membuat thumbnail
    // Misalnya menggunakan package flutter_image_compress
    
    // Contoh implementasi sederhana:
    // final result = await FlutterImageCompress.compressAndGetFile(
    //   path,
    //   savePath,
    //   quality: 70,
    //   minWidth: 300,
    //   minHeight: 300,
    // );
    
    // return ReportImage(
    //   id: id,
    //   path: path,
    //   url: url,
    //   createdAt: createdAt,
    //   caption: caption,
    //   thumbnailPath: result?.path,
    // );
    
    // Untuk sementara, kita return objek yang sama
    return this;
  }
}