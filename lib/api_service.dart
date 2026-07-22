import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName = 'laporan_masyarakat';

  // 1. MENGAMBIL SEMUA DATA LAPORAN (Read / Fetch)
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Inject ID dokumen Firestore
        return data;
      }).toList();
    } catch (e) {
      print("Error Fetch Laporan: $e");
      return [];
    }
  }

  // 2. MEMBUAT LAPORAN BARU (Create)
  Future<bool> createReport(Map<String, dynamic> reportData) async {
    try {
      reportData['createdAt'] = FieldValue.serverTimestamp();
      
      await _db.collection(collectionName).add(reportData);
      return true;
    } catch (e) {
      print("Error Create Laporan: $e");
      return false;
    }
  }

  // 3. UPDATE DATA / STATUS LAPORAN (Update)
  Future<bool> updateReport(String reportId, Map<String, dynamic> updatedData) async {
    try {
      await _db.collection(collectionName).doc(reportId).update(updatedData);
      return true;
    } catch (e) {
      print("Error Update Laporan: $e");
      return false;
    }
  }

  // 4. MENGHAPUS LAPORAN (Delete)
  Future<bool> deleteReport(String reportId) async {
    try {
      await _db.collection(collectionName).doc(reportId).delete();
      return true;
    } catch (e) {
      print("Error Delete Laporan: $e");
      return false;
    }
  }
}