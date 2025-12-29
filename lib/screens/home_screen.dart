import 'package:flutter/material.dart';
import '../api_service.dart';
import 'account_screen.dart';
import '../widgets/movie_search_delegate.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> movies = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMovies();
  }

  void _fetchMovies() async {
    try {
      final fetchedMovies = await ApiService.getPopularMovies();
      setState(() {
        movies = fetchedMovies;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar diubah sedikit agar TabBar tidak tertutup shadow
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110), // Tinggi custom untuk menampung TabBar
        child: AppBar(
          backgroundColor: const Color(0xFF1B4332),
          elevation: 0,
          title: const Text('FLICK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'FILM', height: 50), // Beri tinggi agar lega
              Tab(text: 'ACCOUNT', height: 50),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Tab 1: Film Grid ---
          Column(
            children: [
              // Container Search Bar (Hanya kosmetik, fungsinya dipindah ke icon)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      // Jadikan TextField readOnly agar keyboard tidak muncul di sini
                      child: TextField(
                        readOnly: true, 
                        onTap: () {
                           // Panggil fungsi search saat textfield diklik
                           showSearch(context: context, delegate: MovieSearchDelegate());
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Ikon Search
                    GestureDetector(
                      onTap: () {
                        // Panggil fungsi search saat ikon diklik
                        showSearch(context: context, delegate: MovieSearchDelegate());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF74A587),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(alignment: Alignment.centerLeft, child: Text('Daftar Film', style: TextStyle(fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 10),
              // Grid Film
              Expanded(
                child: movies.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigasi ke Halaman Detail
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => MovieDetailScreen(movieId: movie['id']))
                              );
                            },
                            child:  ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                '${ApiService.imageBaseUrl}${movie['poster_path']}',
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          
          // --- Tab 2: Account Screen ---
          // Gunakan widget yang baru kita buat
          const AccountScreen(), 
        ],
      ),
    );
  }
}