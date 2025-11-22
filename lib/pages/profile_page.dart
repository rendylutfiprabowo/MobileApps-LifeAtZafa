import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
            const SizedBox(height: 16),
            Text(
              "Rendy",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Administrator",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text("Email"),
                    subtitle: Text("rendy@example.com"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text("Jabatan"),
                    subtitle: Text("Administrator"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text("Ubah Password"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text("Tentang Aplikasi"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
