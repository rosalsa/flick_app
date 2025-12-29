import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _username = "Loading...";
  String _email = "Loading...";
  File? _profileImage; 
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> myReviews = [];
  List<String> recentMovies = []; 
  List<String> favoriteMovies = []; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData(); 
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_username') ?? "User";
      _email = prefs.getString('user_email') ?? "email@gmail.com";
      
      String? imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && imagePath.isNotEmpty) {
        _profileImage = File(imagePath);
      }

      String? reviewsJson = prefs.getString('all_user_reviews');
      if (reviewsJson != null) {

        List<dynamic> decoded = json.decode(reviewsJson);

        myReviews = List<Map<String, dynamic>>.from(decoded);
      }

      recentMovies = prefs.getStringList('user_recents') ?? [];

      List<String> rawFavs = prefs.getStringList('user_favorites') ?? [];
      favoriteMovies = rawFavs.map((item) {
        return item.split('|')[1];
      }).toList();

    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', image.path);
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _showConfirmationDialog({
    required String title, 
    required String content, 
    required VoidCallback onYes
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF74A587),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(content, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('BACK', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: onYes,
                      child: const Text('YES', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false); 
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _handleDeleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (!mounted) return;
     Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dihapus.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null 
                          ? FileImage(_profileImage!) as ImageProvider
                          : const NetworkImage('https://i.pravatar.cc/150?img=3'), 
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4332),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('edit', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(_email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4332),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('follow', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 25),

            _buildSectionTitle('Review'),
            const SizedBox(height: 10),
            if (myReviews.isEmpty)
              _buildEmptyState('Belum ada review yang ditulis.')
            else
              ListView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myReviews.length,
                itemBuilder: (context, index) {
                  final review = myReviews[index];
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF74A587),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             CircleAvatar(
                                radius: 12,
                                backgroundImage: _profileImage != null 
                                  ? FileImage(_profileImage!) as ImageProvider
                                  : const NetworkImage('https://i.pravatar.cc/150?img=3'),
                              ),
                            const SizedBox(width: 8),
                            Text(_username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text('Movie: ${review['movieTitle']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                        const SizedBox(height: 3),
                        Text(
                          review['content'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

             _buildSectionTitle('Recent'),
             const SizedBox(height: 10),
             if (recentMovies.isEmpty)
              _buildEmptyState('Belum ada film yang dilihat/direview.')
             else
               _buildHorizontalMovieList(recentMovies),

             const SizedBox(height: 20),

             _buildSectionTitle('Favorite'),
             const SizedBox(height: 10),
             if (favoriteMovies.isEmpty)
                _buildEmptyState('Belum ada film favorit.')
             else
               _buildHorizontalMovieList(favoriteMovies),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                  ),
                  onPressed: () {
                    _showConfirmationDialog(
                      title: 'Apakah kamu yakin ingin menghapus akun?',
                      content: '',
                      onYes: _handleDeleteAccount,
                    );
                  },
                  child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                  ),
                  onPressed: () {
                     _showConfirmationDialog(
                      title: 'Apakah kamu yakin ingin keluar?',
                      content: '',
                      onYes: _handleLogout,
                    );
                  },
                  child: const Text('Left', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
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

  Widget _buildEmptyState(String message) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey[600]))),
    );
  }

  Widget _buildHorizontalMovieList(List<String> posterUrls) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: posterUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                posterUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}