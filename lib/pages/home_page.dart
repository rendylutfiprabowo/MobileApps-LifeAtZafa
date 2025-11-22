import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart'; // NEW: geolocator import
import '../services/api_service.dart';
import 'home/laporan_presensi_page.dart';
import 'home/kunjungan_sales_page.dart';
import 'home/slip_gaji_page.dart';
import 'home/klaim_beban_page.dart';
import 'home/tugas/detail_tugas_page.dart';
import 'home/tugas/home_tugas_page.dart';
import 'home/lembur_page.dart';
import 'home/izin_cuti_page.dart';
import 'home/kasbon_page.dart';
import 'login_page.dart';


class HomePage extends StatefulWidget {
  final VoidCallback onLogout;
  const HomePage({super.key, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentTime = DateFormat('HH.mm').format(DateTime.now());

  Map<String, dynamic>? userData;
  Map<String, dynamic>? userDetailData;
  Map<String, dynamic>? todayPresensi;

  // >>> CHANGED: add selected index for bottom navigation
  int _selectedIndex = 0;
  // <<< CHANGED

  // NEW: variables for lokasi/radius check
  bool isDalamRadius = true; // assume true until checked (keeps UX same until check)
  double jarakUserMeter = 0.0;
  double kantorLat = 0.0;
  double kantorLng = 0.0;
  double kantorRadiusMeter = 0.0;

  @override
  void initState() {
    super.initState();
    // _updateTime();
    fetchUser();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      // Update jam
      setState(() {
        currentTime = DateFormat('HH.mm').format(DateTime.now());
      });

      // Refresh data presensi otomatis
      await fetchTodayPresensi();

      // Loop lagi tiap detik
      _startAutoRefresh();
    });
  }

  Future<void> fetchUser() async {
    final storage = GetStorage();
    final savedUser = storage.read('user');

    if (savedUser == null) return;

    setState(() => userData = savedUser);

    await fetchDetailUser();
    await fetchTodayPresensi();

    // NEW: setelah ambil user dan detail, coba cek lokasi kantor & posisi device
    await cekRadiusDariApi(); // NEW

    if (!mounted) return;
    setState(() {});
  }

  Future<void> fetchDetailUser() async {
    final userId = userData?['id'];
    if (userId == null) return;

    final response = await ApiService.getUserDetailById(userId);

    if (response['statusCode'] == 200) {
      setState(() {
        userDetailData = response['data'];
      });
    }
  }

  Future<void> fetchTodayPresensi() async {
    final userId = userData?['id'];
    if (userId == null) return;

    final response = await ApiService.getPresensiByUser(userId);
    final allPresensi = response['data'];

    if (allPresensi == null || allPresensi is! List) {
      setState(() => todayPresensi = null);
      return;
    }

    final now = DateTime.now();
    final todayData = allPresensi.firstWhere(
          (p) {
        try {
          final tgl = DateTime.parse(p['tanggal'].toString());
          return tgl.year == now.year &&
              tgl.month == now.month &&
              tgl.day == now.day;
        } catch (_) {
          return false;
        }
      },
      orElse: () => null,
    );
    setState(() => todayPresensi = todayData);
  }

  Future<void> handleMasuk() async {
    // NEW: pastikan kita cek ulang posisi sebelum benar-benar mengirim absen
    await cekRadiusDariApi(); // NEW: refresh lokasi kantor & device posisi

    if (!isDalamRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda berada di luar radius kantor (${jarakUserMeter.toStringAsFixed(1)} m). Tidak dapat absen.')),
      );
      return;
    }

    final box = GetStorage();
    final user = box.read('user') ?? {};
    final userId = user['id'];
    if (userDetailData == null) return;
    final shiftId = userDetailData?['shift_id'];
    if (userId == null || shiftId == null) return;
    final res = await ApiService.absenMasuk(userId, shiftId);
    if (res['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil absen masuk')),
      );
      await fetchTodayPresensi();   // refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['data']['message'] ?? 'Gagal absen')),
      );
    }
  }

  Future<void> handleKeluar() async {
    if (todayPresensi == null) return;
    final presensiId = todayPresensi!['id'];

    final res = await ApiService.absenKeluar(presensiId);
    if (res['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil absen keluar')),
      );
      fetchUser(); // reload todayPresensi
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['data']['message'] ?? 'Gagal absen keluar')),
      );
    }
  }

  Future<void> handleIstirahat() async {
    if (todayPresensi == null) return;
    final presensiId = todayPresensi!['id'];

    final res = await ApiService.toggleIstirahat(presensiId);

    if (res['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status istirahat diperbarui')),
      );

      // Update state langsung dari response API
      setState(() {
        todayPresensi = res['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['data']['message'] ?? 'Gagal update istirahat')),
      );
    }
  }

  // NEW: fungsi untuk cek lokasi kantor dari API dan posisi device lalu hitung jarak
  Future<void> cekRadiusDariApi() async {
    try {
      final box = GetStorage();
      final user = box.read('user') ?? {};
      final userId = user['id'];
      if (userId == null) return;

      final res = await ApiService.getLokasiByUser(userId);
      if (res == null) return;
      if (res['status'] != true) {
        // jika API tidak mengembalikan lokasi, biarkan isDalamRadius tetap sebagaimana saat ini
        print('Lokasi API tidak ditemukan: ${res['message']}');
        return;
      }

      final data = res['data'];
      // parse lat/lng/radius (pastikan format string -> double)
      kantorLat = double.tryParse(data['latitude'].toString()) ?? 0.0;
      kantorLng = double.tryParse(data['longitude'].toString()) ?? 0.0;
      kantorRadiusMeter = double.tryParse(data['radius'].toString()) ?? 0.0;

      // cek permission & ambil posisi device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        print('Location services disabled');
        setState(() {
          isDalamRadius = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // permission denied
          print('Location permission denied');
          setState(() {
            isDalamRadius = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // permissions are denied forever
        print('Location permission denied forever');
        setState(() {
          isDalamRadius = false;
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      // hitung jarak (meter) menggunakan helper bawaan geolocator
      double distanceInMeters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        kantorLat,
        kantorLng,
      );

      setState(() {
        jarakUserMeter = distanceInMeters;
        isDalamRadius = distanceInMeters <= kantorRadiusMeter;
      });

      print('Jarak ke kantor: ${jarakUserMeter.toStringAsFixed(1)} m (radius: $kantorRadiusMeter m)');

    } catch (e) {
      print('Error cekRadiusDariApi: $e');
      // jangan crash UI, hanya set false supaya tombol disable
      setState(() {
        isDalamRadius = false;
      });
    }
  }

  bool get sudahMasuk =>
      todayPresensi != null && todayPresensi!['jam_masuk'] != null;

  bool get sudahKeluar =>
      todayPresensi != null && todayPresensi!['jam_keluar'] != null;

  bool get sedangIstirahat {
    final mulai = todayPresensi?['jamIstirahat']?['jam_mulai_istirahat'];
    final selesai = todayPresensi?['jamIstirahat']?['jam_selesai_istirahat'];
    return mulai != null && selesai == null;
  }

  bool get sudahSelesaiIstirahat {
    final mulai = todayPresensi?['jamIstirahat']?['jam_mulai_istirahat'];
    final selesai = todayPresensi?['jamIstirahat']?['jam_selesai_istirahat'];
    return mulai != null && selesai != null;
  }

  bool get tombolIstirahatEnabled {
    final mulai = todayPresensi?['jamIstirahat']?['jam_mulai_istirahat'];
    final selesai = todayPresensi?['jamIstirahat']?['jam_selesai_istirahat'];

    // Disable kalau kedua jam sudah ada
    final sudahFullIstirahat = mulai != null && selesai != null;

    return sudahMasuk && !sudahKeluar && !sudahFullIstirahat;
  }

  // <<< CHANGED: tombolMasukEnabled sekarang juga memperhatikan isDalamRadius pada UI usage
  bool get tombolMasukEnabled => !sudahMasuk && isDalamRadius; // CHANGED

  bool get tombolKeluarEnabled =>
      (sudahMasuk && !sedangIstirahat && !sudahKeluar);


  @override
  Widget build(BuildContext context) {
    // final mulai = todayPresensi?['jamIstirahat']?['jam_mulai_istirahat'];
    // final selesai = todayPresensi?['jamIstirahat']?['jam_selesai_istirahat'];
    // print("FULL todayPresensi: $todayPresensi");
    // print ("mulai istirahat : $mulai");
    // print ("selesai istirahat: $selesai");

    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(DateTime.now());
    final fullDate = DateFormat('d MMMM yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // >>> CHANGED: keep body the same but add bottomNavigationBar copied from MainLayout
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header profile
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE8F0FE),
                        child: Icon(Iconsax.user,
                            color: const Color(0xFF001F3F),
                            size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text("Rendy Lutfi Prabowo",
                            Text(
                                userData?['name'] ?? '-',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(
                              (userData?['roles'] != null && userData!['roles'] is List)
                                  ? userData!['roles'].join(', ')     // convert List → String
                                  : '-',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.notification,  color: const Color(0xFF001F3F),),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.logout, color: Colors.red),
                        onPressed: () {
                          widget.onLogout();  // update state login
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(
                                onLogin: widget.onLogout, // tdk kepake, gapapa
                                onLogout: widget.onLogout,
                              ),
                            ),
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Greeting
              Text("Hallo 👋 ${userData?['name'] ?? '-'}",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Semangat kerja ya!",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600])),

              const SizedBox(height: 16),

              // Card waktu dan tombol
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // Waktu sekarang
                      Text(
                        "$currentTime WIB",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF001F3F),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),
                      // Bagian header kiri-kanan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kiri: nama shift, jam kerja, jam masuk
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userDetailData?['shift']?['nama_shift'] ?? 'Tidak ditemukan',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userDetailData?['shift'] != null
                                    ? "${userDetailData!['shift']['shift_start'].substring(0,5)} - ${userDetailData!['shift']['shift_end'].substring(0,5)}"
                                    : 'Tidak ditemukan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // todayPresensi != null ? "In : ${todayPresensi!['jam_masuk'] ?? '-'}" : "In : -",
                                "In : ${todayPresensi?['jam_masuk'] != null
                                    ? DateFormat('HH:mm')
                                    .format(DateTime.parse(todayPresensi?['jam_masuk']).toLocal())
                                    : '-'} WIB",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: const Color(0xFF001F3F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Kanan: hari, tanggal, jam keluar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fullDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Out : ${todayPresensi?['jam_keluar'] != null
                                    ? DateFormat('HH:mm')
                                    .format(DateTime.parse(todayPresensi?['jam_keluar']).toLocal())
                                    : '-'} WIB",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Color(0xFF001F3F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Garis pemisah tipis
                      Divider(color: Colors.grey[300], thickness: 1),
                      const SizedBox(height: 16),
                      Text(
                        userDetailData?['shift'] != null
                            ? "Jam kerja kamu pukul ${userDetailData!['shift']['shift_start'].substring(0,5)} - ${userDetailData!['shift']['shift_end'].substring(0,5)} WIB"
                            : "Jam Kerja Tidak ditemukan",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Tombol Masuk & Keluar
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: tombolMasukEnabled ? handleMasuk : null, // CHANGED: now also depends on isDalamRadius via getter
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tombolMasukEnabled ? Color(0xFF001F3F) : Colors.grey.shade300,
                                // DISABLED
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Masuk',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: todayPresensi == null
                                      ? Colors.white            // ENABLED
                                      : Colors.grey.shade500,   // DISABLED
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: tombolKeluarEnabled ? handleKeluar : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: tombolKeluarEnabled ? Color(0xFF001F3F) : Colors.grey.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                "Keluar",
                                style: GoogleFonts.poppins(
                                  color: tombolKeluarEnabled ? Color(0xFF001F3F) : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child:
                          OutlinedButton.icon(
                            onPressed: tombolIstirahatEnabled ? handleIstirahat : null,
                            icon: Icon(
                              Icons.coffee,
                              color: tombolIstirahatEnabled ? const Color(0xFF001F3F) : Colors.grey,
                              size: 18,
                            ),
                            label: Text(
                              sedangIstirahat ? "Beres Istirahat" : "Mulai Istirahat",
                              style: GoogleFonts.poppins(
                                color: tombolIstirahatEnabled ? Color(0xFF001F3F) : Colors.grey,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: tombolIstirahatEnabled ? Color(0xFF001F3F) : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                      ),
                      const SizedBox(height: 20),

                      // Garis pemisah tipis
                      Divider(color: Colors.grey[300], thickness: 1),

                      const SizedBox(height: 16),
                      // Ringkasan Kehadiran Bulan Ini
                      Text(
                        "Ringkasan Kehadiran Bulan Ini",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Attend
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "ATTEND",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "0 Days",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Permit
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "PERMIT",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "0 Days",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF001F3F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: const Color(0xFF001F3F),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Leave
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "LEAVE BALANCE",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "0 Days",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Menu grid bawah
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                childAspectRatio: 0.82,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenu(Iconsax.document, 'Laporan\nPresensi', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanPresensiPage()));
                  }),
                  _buildMenu(Iconsax.user_tick, 'Kunjungan\nSales', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KunjunganSalesPage()));
                  }),
                  _buildMenu(Iconsax.receipt_2, 'Slip\nGaji', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SlipGajiPage()));
                  }),
                  _buildMenu(Iconsax.money, 'Klaim\nBeban', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KlaimBebanPage()));
                  }),
                  _buildMenu(Iconsax.task_square, 'Tugas', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeTugasPage()));
                  }),
                  _buildMenu(Iconsax.clock, 'Lembur', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LemburPage()));
                  }),
                  _buildMenu(Iconsax.calendar, 'Izin/Cuti', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const IzinCutiPage()));
                  }),
                  _buildMenu(Iconsax.card, 'Kasbon', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KasbonPage()));
                  }),

                ],
              ),
              const SizedBox(height: 20),

              // Section Pengumuman
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul dan tombol "Lihat Lainnya"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pengumuman",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Arahkan ke halaman pengumuman jika ada
                          },
                          child: Text(
                            "Lihat Lainnya",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF001F3F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Jika tidak ada pengumuman
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          "Pengumuman Kosong",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildMenu(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,  color: const Color(0xFF001F3F), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
