import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/state/auth_state.dart';
import 'core/layout/main_layout.dart';
import 'pages/home_page.dart';
import 'pages/absensi_page.dart';
import 'pages/laporan_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  runApp(const ZafaApp());
}

class ZafaApp extends StatefulWidget {
  const ZafaApp({super.key});

  @override
  State<ZafaApp> createState() => _ZafaAppState();
}

class _ZafaAppState extends State<ZafaApp> {
  final AuthState authState = AuthState();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: authState,
      builder: (context, isLoggedIn, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zafa App',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          home: isLoggedIn
              ? MainLayout(authState: authState)
              : LoginPage(
            onLogin: authState.login,
            onLogout: authState.logout,
          ),
        );
      },
    );
  }
}
