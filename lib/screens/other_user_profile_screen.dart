import 'package:flutter/material.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String username;
  final String avatarUrl;

  const OtherUserProfileScreen({
    super.key, 
    required this.username, 
    required this.avatarUrl
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  bool isFollowing = false; // Status follow

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        title: const Text('FLICK', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(widget.avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${widget.username.toLowerCase()}@gmail.com', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      
                      // TOMBOL FOLLOW
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFollowing = !isFollowing;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFollowing ? 'You followed ${widget.username}' : 'Unfollowed ${widget.username}'),
                              duration: const Duration(seconds: 1),
                            )
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFollowing ? Colors.grey : const Color(0xFF1B4332),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow', 
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 25),

              // Bagian Review (Dummy agar terlihat penuh)
              _buildSectionTitle('Recent Reviews'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF74A587),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'This user has excellent taste in movies! JUMBO is their favorite.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 20),
              _buildSectionTitle('Favorites'),
              const SizedBox(height: 10),
              // Tampilkan gambar dummy
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPoster('https://image.tmdb.org/t/p/w200/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg'),
                    _buildPoster('https://image.tmdb.org/t/p/w200/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg'),
                    _buildPoster('https://image.tmdb.org/t/p/w200/r2J02Z2OpLYct2MW8W7M7UI9uev.jpg'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPoster(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: 100, fit: BoxFit.cover),
      ),
    );
  }
}