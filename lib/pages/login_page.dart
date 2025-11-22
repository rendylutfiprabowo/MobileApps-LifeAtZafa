import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:get_storage/get_storage.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onLogout,
  });

  @override

  State<LoginPage> createState() => _LoginPageState();
}

bool _obscurePassword = true;

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;


  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(email, password);

    // debug: tampilkan hasil (boleh dihapus setelah fix)
    print(">>> LOGIN RESULT: $result");

    setState(() => _isLoading = false);

    final status = result['statusCode'] ?? 500;
    final data = result['data'] ?? {};

    if (status == 200) {
      final user = data['user'] ?? {};
      final token = data['token'];

      // pastikan user object ada
      if (user == null || user is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response user tidak valid')),
        );
        return;
      }

      // simpan user & token menggunakan GetStorage (atau AuthService)
      final box = GetStorage();
      box.write('user', {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'roles': user['roles'] ?? [],
        'token': token,
      });

      print("===== USER DISIMPAN =====");
      print(box.read('user'));

      // panggil callback login jika diperlukan
      widget.onLogin();

      // Lalu lanjut ke HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(onLogout: widget.onLogout),
        ),
      );
    } else {
      final msg = data['message'] ?? 'Login gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background-login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3), // overlay agar teks tetap terlihat
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),//R, T, L, B
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),

                    Center(
                      child: Image.asset(
                        'assets/logo-zafa.png',
                        width: 90, // bisa disesuaikan
                      ),
                    ),

                    const SizedBox(height: 10),
// Nama aplikasi
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Life at ",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w400, // regular
                              ),
                            ),
                            TextSpan(
                              text: "Zafa Tour",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700, // bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Silakan login untuk melanjutkan",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),


                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _emailController,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, size: 18, color: Colors.grey[700]),
                          hintText: "Email",
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: Colors.grey[700]),
                          hintText: "Password",
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),

                          // === IKON SHOW/HIDE PASSWORD ===
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text(
                          "Masuk",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(height: 60),

                    Center(
                      child: Text(
                        "© 2025 Tim IT & Multimedia",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
