import 'dart:convert'; // Untuk mengelola data JSON
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../api_service.dart';
import 'other_user_profile_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Future<Map<String, dynamic>>? _movieDetail;
  YoutubePlayerController? _youtubeController;
  
  String _currentUsername = '';
  String? _currentProfilePath;
  bool _isFavorite = false;

  List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Prince Poetiray',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'content': 'There is my new favorite movie, JUMBO is 100% best animated movie in Southeast Asian!',
      'rating': 5.0,
      'isLocal': false 
    },
    {
      'name': 'Quinn Salman',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'content': 'Sangat menyentuh hati, animasinya juga luar biasa untuk ukuran film lokal.',
      'rating': 4.5,
      'isLocal': false
    },
  ];

  @override
  void initState() {
    super.initState();
    _movieDetail = ApiService.getMovieDetail(widget.movieId);
    _loadUserData();
    _checkIfFavorite();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('user_username') ?? 'User';
      _currentProfilePath = prefs.getString('profile_image_path');
    });

    _loadLocalReviews(prefs);
  }

  void _loadLocalReviews(SharedPreferences prefs) {
    String? jsonString = prefs.getString('all_user_reviews');
    if (jsonString != null) {
      List<dynamic> savedReviews = json.decode(jsonString);
      
      for (var review in savedReviews) {
        if (review['movieId'] == widget.movieId) {
          setState(() {
            _reviews.insert(0, {
              'name': review['username'],
              'avatar': review['userImage'],
              'content': review['content'],
              'rating': review['rating'],
              'isLocal': true
            });
          });
        }
      }
    }
  }

  // 2. Cek Status Favorit
  void _checkIfFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('user_favorites') ?? [];
    bool found = favs.any((item) => item.startsWith('${widget.movieId}|'));
    setState(() {
      _isFavorite = found;
    });
  }

  // 3. Fungsi Tombol Save / Favorite
  void _toggleFavorite(String posterUrl) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('user_favorites') ?? [];
    String dataString = '${widget.movieId}|$posterUrl'; // Format simpan: "ID|URL_POSTER"

    setState(() {
      if (_isFavorite) {
        // Hapus dari favorit (Cari yang ID-nya sama)
        favs.removeWhere((item) => item.startsWith('${widget.movieId}|'));
        _isFavorite = false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari Favorit')));
      } else {
        // Tambah ke favorit
        favs.insert(0, dataString);
        _isFavorite = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disimpan ke Favorit')));
      }
    });
    
    await prefs.setStringList('user_favorites', favs);
  }

  // 4. Fungsi Submit Review
  void _submitReview(String content, double rating, String movieTitle, String posterUrl) async {
    if (content.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _reviews.insert(0, {
        'name': _currentUsername,
        'avatar': _currentProfilePath,
        'content': content,
        'rating': rating,
        'isLocal': true
      });
    });

    Map<String, dynamic> newReviewData = {
      'movieId': widget.movieId,
      'movieTitle': movieTitle,
      'posterUrl': posterUrl,
      'username': _currentUsername,
      'userImage': _currentProfilePath,
      'content': content,
      'rating': rating,
      'date': DateTime.now().toString(),
    };

    String? jsonString = prefs.getString('all_user_reviews');
    List<dynamic> allReviews = jsonString != null ? json.decode(jsonString) : [];
    allReviews.insert(0, newReviewData);
    await prefs.setString('all_user_reviews', json.encode(allReviews));

    // C. Tambahkan ke "RECENT"
    List<String> recents = prefs.getStringList('user_recents') ?? [];
    recents.remove(posterUrl); 
    recents.insert(0, posterUrl);
    // Batasi max 10 recent
    if (recents.length > 10) recents.removeLast();
    await prefs.setStringList('user_recents', recents);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim!')));
  }

  void _showRatingDialog(String movieTitle, String posterUrl) {
    double tempRating = 3.0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1B4332),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info User
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey,
                        backgroundImage: _currentProfilePath != null 
                            ? FileImage(File(_currentProfilePath!)) as ImageProvider
                            : const NetworkImage('https://i.pravatar.cc/150?img=3'),
                      ),
                      const SizedBox(width: 10),
                      Text(_currentUsername, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Bintang Rating
                  RatingBar.builder(
                    initialRating: tempRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      tempRating = rating;
                    },
                  ),
                  const SizedBox(height: 20),
              
                  // Input Text
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Deskripsikan pengalaman anda',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
              
                  // Tombol Posting
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74A587),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        _submitReview(reviewController.text, tempRating, movieTitle, posterUrl);
                      },
                      child: const Text('Posting', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF74A587),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _movieDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final movie = snapshot.data!;
          final credits = movie['credits']['cast'] as List;
          final videos = movie['videos']['results'] as List;
          
          // Data Penting untuk disimpan
          final String posterUrl = '${ApiService.imageBaseUrl}${movie['poster_path']}';
          final String movieTitle = movie['title'];

          // Cari Trailer
          String? videoKey;
          if (videos.isNotEmpty) {
            final trailer = videos.firstWhere(
              (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
              orElse: () => videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null),
            );
            if (trailer != null) videoKey = trailer['key'];
          }

          if (videoKey != null && _youtubeController == null) {
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoKey,
              flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. HEADER
                  Stack(
                    children: [
                      if (_youtubeController != null)
                        YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: const Color(0xFF1B4332),
                        )
                      else
                        Image.network(
                          posterUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      
                      // Tombol Back
                      Positioned(
                        top: 10, left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      // TOMBOL SAVE (FAVORITE)
                      Positioned(
                        top: 10, right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.bookmark : Icons.bookmark_border, 
                              color: _isFavorite ? Colors.yellow : Colors.white
                            ),
                            onPressed: () => _toggleFavorite(posterUrl),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- 2. JUDUL & INFO ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movieTitle,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                        ),
                        Text(
                          '${movie['release_date']?.substring(0, 4) ?? '-'} • ${(movie['genres'] as List).map((e) => e['name']).join(', ')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Text(
                              movie['vote_average'].toString().substring(0, 3),
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                            ),
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
                        Text(movie['overview'] ?? 'No synopsis available.', style: const TextStyle(color: Color(0xFF1B4332))),
                      ],
                    ),
                  ),

                  // --- 3. TOMBOL RATE & REVIEW ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildActionButton('Rate', const Color(0xFF1B4332), () => _showRatingDialog(movieTitle, posterUrl)),
                        const SizedBox(width: 10),
                        _buildActionButton('Review', const Color(0xFF1B4332), () => _showRatingDialog(movieTitle, posterUrl)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 4. LIST REVIEW ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_reviews.isEmpty)
                          const Text("Belum ada review.", style: TextStyle(color: Colors.white70)),

                        ..._reviews.map((review) {
                          ImageProvider avatarImg;
                          if (review['isLocal'] == true && review['avatar'] != null) {
                             avatarImg = FileImage(File(review['avatar']));
                          } else {
                             avatarImg = NetworkImage(review['avatar'] ?? 'https://i.pravatar.cc/150?img=3');
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                if (review['isLocal'] == false) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => 
                                    OtherUserProfileScreen(username: review['name'], avatarUrl: review['avatar'])
                                  ));
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey,
                                    backgroundImage: avatarImg,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(review['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        RatingBarIndicator(
                                          rating: (review['rating'] as num).toDouble(),
                                          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                          itemCount: 5,
                                          itemSize: 12.0,
                                        ),
                                        Text(
                                          review['content'],
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  
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
                      itemCount: credits.length > 10 ? 10 : credits.length,
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
                                backgroundColor: Colors.grey,
                                child: cast['profile_path'] == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  cast['name'], 
                                  textAlign: TextAlign.center, 
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
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
        },
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}