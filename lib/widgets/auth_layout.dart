import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  final double cardHeight; // Tinggi area putih

  const AuthLayout({super.key, required this.child, this.cardHeight = 0.5});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  List<String> movieImages = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  void _fetchImages() async {
    try {
      final images = await ApiService.getPopularMovieImages();
      setState(() {
        movieImages = images.take(5).toList(); // Ambil 5 gambar teratas
      });
    } catch (e) {
      // Handle error (bisa pakai gambar placeholder lokal)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Slider
          if (movieImages.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
              ),
              items: movieImages.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                );
              }).toList(),
            )
          else
            Container(color: Colors.grey), // Loading state

          // 2. White Rounded Container (Bottom Sheet)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * widget.cardHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}