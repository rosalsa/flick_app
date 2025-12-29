import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // cardHeight 0.4 karena kontennya sedikit
    return AuthLayout(
      cardHeight: 0.4, 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FLICK',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332), // Warna Hijau Tua sesuai desain
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
            },
            child: const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'by Keluarga Cemara Corp.',
              style: TextStyle(fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}