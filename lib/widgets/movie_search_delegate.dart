import 'package:flutter/material.dart';
import '../api_service.dart';
import '../screens/movie_detail_screen.dart';

class MovieSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search movie...';

  // --- PERBAIKAN TEMA WARNA ---
  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B4332), // Header Hijau Tua
        elevation: 0,
      ),
      // Warna teks input diubah menjadi HITAM agar terlihat di background putih
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.black, fontSize: 18),
      ),
      // Warna kursor input
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFF1B4332)),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white, // Latar belakang input putih
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
         border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none
        ),
      ),
      // Ikon back dan clear tetap putih agar kontras dengan header hijau
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Opsional: Jika ingin hemat API call, bisa dikosongkan atau return _buildSearchResults()
    // Jika langsung memanggil API di sini, setiap ketikan akan request ke server.
     if (query.isEmpty) {
      return Container(color: Colors.white);
    }
    // Debouncing (penundaan pencarian) idealnya diterapkan di sini, 
    // tapi untuk simplifikasi kita panggil langsung.
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Container(
        color: Colors.white,
        child: const Center(child: Text("Ketik judul film untuk mencari.", style: TextStyle(color: Colors.grey))),
      );
    }

    // --- MENGGUNAKAN API SERVICE ASLI ---
    return FutureBuilder(
      future: ApiService.searchMovies(query), // Panggil fungsi asli
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.white, child: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
           return Container(color: Colors.white, child: Center(child: Text('Terjadi kesalahan koneksi.', style: TextStyle(color: Colors.grey[700]))));
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Container(
            color: Colors.white,
            child: Center(child: Text('Film "$query" tidak ditemukan.', style: TextStyle(color: Colors.grey[700]))),
          );
        }

        final results = snapshot.data as List<dynamic>;

        return Container(
          color: Colors.white,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final movie = results[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Gunakan thumbnail URL yang lebih kecil
                  child: Image.network(
                          '${ApiService.imageThumbnailUrl}${movie["poster_path"]}',
                          width: 50, 
                          height: 75,
                          fit: BoxFit.cover,
                          // Handle jika gambar gagal loading saat search
                          errorBuilder: (context, error, stackTrace) => 
                            Container(width: 50, height: 75, color: Colors.grey[300], child: const Icon(Icons.movie, color: Colors.grey)),
                        ),
                ),
                title: Text(movie['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(movie['release_date']?.split('-')[0] ?? '-', style: const TextStyle(color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    // Aksi tutup (kosongkan dulu untuk sekarang)
                  },
                ),
                onTap: () {
                  Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => MovieDetailScreen(movieId: movie['id']))
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}