import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildScaffoldPage(String title) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 15,fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      backgroundColor: Color(0xFF001F3F),
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Text(
        'Halaman $title\n(Sementara kosong)',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 16),
      ),
    ),
  );
}
