import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class ApiService {
  // GANTI DENGAN API KEY KAMU
  static String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  
  static String baseUrl = dotenv.env['BASE_URL'] ?? '';
  
  static String imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
  
  static String imageThumbnailUrl = dotenv.env['IMAGE_THUMBNAIL_URL'] ?? '';

  static Future<List<String>> getPopularMovieImages() async {
    final response = await http.get(Uri.parse('$baseUrl/movie/popular?api_key=$apiKey'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((movie) => '$imageBaseUrl${movie['poster_path']}').toList();
    } else {
      throw Exception('Gagal memuat gambar');
    }
  }

  static Future<List<dynamic>> getPopularMovies() async {
    final response = await http.get(Uri.parse('$baseUrl/movie/popular?api_key=$apiKey'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Gagal memuat film');
    }
  }

  static Future<List<dynamic>> searchMovies(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$encodedQuery'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.where((movie) => movie['poster_path'] != null).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMovieDetail(int movieId) async {
    final response = await http.get(Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey&append_to_response=credits,videos'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat detail film');
    }
  }
}