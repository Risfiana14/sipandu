import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Periksa apakah layanan lokasi diaktifkan
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Service lokasi mati');
        return null;
      }

      // Periksa izin lokasi
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permission lokasi ditolak');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permission lokasi ditolak permanen');
        return null;
      }

      // Tambahkan timeout untuk menghindari menunggu terlalu lama
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
          'Berhasil mendapatkan lokasi: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Gagal ambil lokasi: $e');
      return null;
    }
  }

  static Future<String?> getAddressFromLatLng(Position position) async {
    try {
      debugPrint(
          'Mencoba mendapatkan alamat dari: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'id_ID', // Gunakan locale Indonesia
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint('Placemark ditemukan: $place');

        // Bangun alamat dengan memeriksa nilai null
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final subAdministrativeArea = place.subAdministrativeArea ?? '';
        final administrativeArea = place.administrativeArea ?? '';
        final postalCode = place.postalCode ?? '';
        final country = place.country ?? '';

        // Filter komponen alamat yang kosong
        final components = [
          street,
          subLocality,
          locality,
          subAdministrativeArea,
          administrativeArea,
          postalCode,
          country
        ].where((component) => component.isNotEmpty).toList();

        final address = components.join(', ');
        debugPrint('Alamat berhasil dibuat: $address');
        return address;
      }

      debugPrint('Tidak ada placemark yang ditemukan');
      return 'Alamat tidak ditemukan';
    } catch (e) {
      debugPrint('Gagal ambil alamat: $e');
      return 'Gagal mendapatkan alamat: $e';
    }
  }
}
