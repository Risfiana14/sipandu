// lib/services/pocketbase_client.dart
import 'package:pocketbase/pocketbase.dart';

const String pocketBaseUrl = 'http://127.0.0.1:8090'; // Sesuaikan dengan URL PocketBase Anda

class PocketBaseClient {
  static final PocketBase _instance = PocketBase(pocketBaseUrl);

  static PocketBase get instance => _instance;
}