import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daftar Laporan",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blue),
                    title: Text("Laporan Presensi"),
                    subtitle: Text("Belum ada data"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_turned_in, color: Colors.green),
                    title: Text("Laporan Kunjungan Sales"),
                    subtitle: Text("Belum ada data"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.orange),
                    title: Text("Laporan Slip Gaji"),
                    subtitle: Text("Belum ada data"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.red),
                    title: Text("Laporan Klaim Beban"),
                    subtitle: Text("Belum ada data"),
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
