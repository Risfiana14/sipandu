// lib/services/pocketbase_client.dart
import 'package:pocketbase/pocketbase.dart';

const String pocketBaseUrl = 'http://159.223.74.55:8090/'; // Sesuaikan dengan URL PocketBase Anda

class PocketBaseClient {
  static final PocketBase _instance = PocketBase(pocketBaseUrl);

  static PocketBase get instance => _instance;
}