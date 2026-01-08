import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../controllers/movie_detail_controller.dart';
import 'package:flick_app/api_service.dart';
import 'account_screen.dart';
import 'other_user_profile_screen.dart';

// Ubah jadi StatelessWidget karena tidak perlu setState lagi!
class MovieDetailScreen extends StatelessWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    // INJEKSI CONTROLLER (DI)
    // Saat halaman dibuka, controller dibuat & langsung load data
    final controller = Get.put(MovieDetailController());
    controller.loadMovieDetail(movieId);

    return Scaffold(
      backgroundColor: const Color(0xFF74A587),
      // Obx adalah widget ajaib GetX yang akan update otomatis kalau data di controller berubah
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        // Ambil data dari controller
        final movie = controller.movie;
        final credits = movie['credits']['cast'] as List;
        final videos = movie['videos']['results'] as List;
        final String posterUrl = '${ApiService.imageBaseUrl}${movie['poster_path']}';
        final String movieTitle = movie['title'];

        // Logika Trailer (Bisa dipindah ke controller idealnya, tapi disini gapapa untuk UI)
        String? videoKey;
        if (videos.isNotEmpty) {
           final trailer = videos.firstWhere((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
              orElse: () => videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null));
           if (trailer != null) videoKey = trailer['key'];
        }
        
        YoutubePlayerController? ytController;
        if (videoKey != null) {
          ytController = YoutubePlayerController(
            initialVideoId: videoKey,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Stack(
                  children: [
                    if (ytController != null)
                      YoutubePlayer(controller: ytController, showVideoProgressIndicator: true)
                    else
                      Image.network(posterUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
                    
                    Positioned(
                      top: 10, left: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(), // Pakai Get.back()
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10, right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          // Baca status favorit dari controller secara realtime
                          icon: Icon(
                            controller.isFavorite.value ? Icons.bookmark : Icons.bookmark_border,
                            color: controller.isFavorite.value ? Colors.yellow : Colors.white
                          ),
                          onPressed: () => controller.toggleFavorite(movieId, posterUrl),
                        ),
                      ),
                    ),
                  ],
                ),

                // --- INFO FILM ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movieTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                      Text('${movie['release_date']?.substring(0, 4) ?? '-'} • ${(movie['genres'] as List).map((e) => e['name']).join(', ')}', 
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(movie['vote_average'].toString().substring(0, 3), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                          const SizedBox(width: 10),
                          RatingBarIndicator(
                            rating: (movie['vote_average'] as num).toDouble() / 2,
                            itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 20.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text('Synopsis', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                      Text(movie['overview'] ?? '-', style: const TextStyle(color: Color(0xFF1B4332))),
                    ],
                  ),
                ),

                // --- TOMBOL ACTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildActionButton('Rate', const Color(0xFF1B4332), () => _showRatingDialog(context, controller, movieTitle, posterUrl)),
                      const SizedBox(width: 10),
                      _buildActionButton('Review', const Color(0xFF1B4332), () => _showRatingDialog(context, controller, movieTitle, posterUrl)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- LIST REVIEW (Reactive) ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1B4332), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      if (controller.reviews.isEmpty) const Text("Belum ada review.", style: TextStyle(color: Colors.white70)),
                      
                      // Loop data dari controller.reviews
                      ...controller.reviews.map((review) {
                         ImageProvider avatarImg;
                          if (review['isLocal'] == true && review['avatar'] != null) {
                             avatarImg = FileImage(File(review['avatar']));
                          } else {
                             avatarImg = NetworkImage(review['avatar'] ?? 'https://i.pravatar.cc/150?img=3');
                          }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                               if (review['isLocal'] == true) {
                                  Get.to(() => const AccountScreen(isEditable: false));
                                } else {
                                  Get.to(() => OtherUserProfileScreen(
                                      username: review['name'] ?? 'User', 
                                      avatarUrl: review['avatar'] ?? 'https://i.pravatar.cc/150?img=3'
                                  ));
                                }
                            },
                            child: Row(
                              children: [
                                CircleAvatar(radius: 18, backgroundImage: avatarImg),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(review['name'] ?? 'Anon', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(review['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
                
                // --- CAST SECTION (Tetap sama) ---
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1B4332), borderRadius: BorderRadius.circular(15)),
                      child: const Text('Cast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: credits.length,
                    itemBuilder: (context, index) {
                       final cast = credits[index];
                       return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: cast['profile_path'] != null 
                                ? NetworkImage('${ApiService.imageThumbnailUrl}${cast['profile_path']}')
                                : null,
                              child: cast['profile_path'] == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(height: 5),
                            SizedBox(width: 60, child: Text(cast['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)), maxLines: 2))
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Dialog juga di-update untuk panggil fungsi controller
  void _showRatingDialog(BuildContext context, MovieDetailController controller, String movieTitle, String posterUrl) {
    double tempRating = 3.0;
    TextEditingController reviewController = TextEditingController();

    Get.dialog(
       Dialog(
          backgroundColor: const Color(0xFF1B4332),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Write a Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  RatingBar.builder(
                    initialRating: tempRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => tempRating = rating,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Share your experience...', border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF74A587)),
                      onPressed: () {
                        // PANGGIL FUNGSI CONTROLLER
                        controller.submitReview(movieId, reviewController.text, tempRating, movieTitle, posterUrl);
                      },
                      child: const Text('Posting', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}