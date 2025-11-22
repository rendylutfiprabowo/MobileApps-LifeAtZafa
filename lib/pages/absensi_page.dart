import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AbsensiPage extends StatelessWidget {
  const AbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Absensi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Laporan Presensi", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Hadir"),
                    subtitle: Text("Jam Masuk: 08:00"),
                  ),
                  ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text("Terlambat"),
                    subtitle: Text("Jam Masuk: 08:20"),
                  ),
                  ListTile(
                    leading: Icon(Icons.close, color: Colors.red),
                    title: Text("Mangkir"),
                    subtitle: Text("Tidak ada data masuk"),
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
