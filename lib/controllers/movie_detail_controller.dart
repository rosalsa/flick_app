import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flick_app/api_service.dart';

class MovieDetailController extends GetxController {
  // Variabel Data (Dibuat .obs agar reaktif/otomatis update)
  var isLoading = true.obs;
  var movie = {}.obs;
  var isFavorite = false.obs;
  var reviews = <Map<String, dynamic>>[].obs; // List kosong awal
  
  // Data User
  String currentUsername = '';
  String? currentProfilePath;

  // Data Dummy Awal
  final List<Map<String, dynamic>> _dummyReviews = [
    {
      'name': 'Prince Poetiray',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'content': 'There is my new favorite movie!',
      'rating': 5.0,
      'isLocal': false 
    },
    {
      'name': 'Quinn Salman',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'content': 'Sangat menyentuh hati.',
      'rating': 4.5,
      'isLocal': false
    },
  ];

  // Fungsi dipanggil saat Controller pertama kali jalan (pengganti initState)
  void loadMovieDetail(int movieId) async {
    isLoading.value = true;
    try {
      // 1. Ambil Data API
      var data = await ApiService.getMovieDetail(movieId);
      movie.value = data;

      // 2. Load Data User & Review Lokal
      await _loadUserData(movieId);
      
      // 3. Cek Favorit
      await _checkIfFavorite(movieId);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserData(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    currentUsername = prefs.getString('user_username') ?? 'User';
    currentProfilePath = prefs.getString('profile_image_path');

    // Reset reviews dengan dummy, lalu tambah review lokal
    reviews.assignAll(_dummyReviews);

    String? jsonString = prefs.getString('all_user_reviews');
    if (jsonString != null) {
      List<dynamic> savedReviews = json.decode(jsonString);
      for (var review in savedReviews) {
        if (review['movieId'] == movieId) {
          reviews.insert(0, {
            'name': review['username'],
            'avatar': review['userImage'],
            'content': review['content'],
            'rating': review['rating'],
            'isLocal': true 
          });
        }
      }
    }
  }

  Future<void> _checkIfFavorite(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('user_favorites') ?? [];
    isFavorite.value = favs.any((item) => item.startsWith('$movieId|'));
  }

  // Fungsi Aksi: Toggle Favorite
  void toggleFavorite(int movieId, String posterUrl) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('user_favorites') ?? [];
    String dataString = '$movieId|$posterUrl';

    if (isFavorite.value) {
      favs.removeWhere((item) => item.startsWith('$movieId|'));
      isFavorite.value = false;
      Get.snackbar("Sukses", "Dihapus dari Favorit", backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 1));
    } else {
      favs.insert(0, dataString);
      isFavorite.value = true;
      Get.snackbar("Sukses", "Disimpan ke Favorit", backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 1));
    }
    await prefs.setStringList('user_favorites', favs);
  }

  // Fungsi Aksi: Submit Review
  void submitReview(int movieId, String content, double rating, String movieTitle, String posterUrl) async {
    if (content.isEmpty) return;
    
    // Update UI List
    reviews.insert(0, {
      'name': currentUsername,
      'avatar': currentProfilePath,
      'content': content,
      'rating': rating,
      'isLocal': true
    });

    // Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> newReviewData = {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'posterUrl': posterUrl,
      'username': currentUsername,
      'userImage': currentProfilePath,
      'content': content,
      'rating': rating,
      'date': DateTime.now().toString(),
    };

    String? jsonString = prefs.getString('all_user_reviews');
    List<dynamic> allReviews = jsonString != null ? json.decode(jsonString) : [];
    allReviews.insert(0, newReviewData);
    await prefs.setString('all_user_reviews', json.encode(allReviews));

    // Update Recent
    List<String> recents = prefs.getStringList('user_recents') ?? [];
    recents.remove(posterUrl);
    recents.insert(0, posterUrl);
    if (recents.length > 10) recents.removeLast();
    await prefs.setStringList('user_recents', recents);

    Get.back(); // Tutup Dialog otomatis via GetX
    Get.snackbar("Sukses", "Ulasan berhasil dikirim!", backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 1));
  }
}