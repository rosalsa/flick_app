import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/auth_layout.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    String inputUsername = _usernameController.text.trim();
    String inputPassword = _passwordController.text.trim();

    if (inputUsername.isEmpty || inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password harus diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // --- PERBAIKAN LOGIKA DISINI ---
    // Kita cek apakah data usernamenya ADA di memori
    String? storedUsername = prefs.getString('user_username');
    String? storedPassword = prefs.getString('user_password');

    // Jika storedUsername NULL, berarti memang belum pernah daftar / akun dihapus
    if (storedUsername == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun tidak ditemukan. Silakan Register dulu.'), backgroundColor: Colors.orange),
      );
    } 
    // Jika ada, cek kecocokan password
    else if (inputUsername == storedUsername && inputPassword == storedPassword) {
      // SET STATUS LOGIN JADI TRUE
      await prefs.setBool('is_logged_in', true);

       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
      );
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Password salah!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      cardHeight: 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SIGN IN FLICK',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Username',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                  },
                  child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _handleLogin, // Panggil logika login
                  child: const Text('Go', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Center(child: Text('by Keluarga Cemara Corp.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}