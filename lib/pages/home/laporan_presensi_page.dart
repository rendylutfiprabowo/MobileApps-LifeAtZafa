import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '/services/api_service.dart';
import 'package:intl/intl.dart';

class LaporanPresensiPage extends StatefulWidget {
  const LaporanPresensiPage({super.key});

  @override
  State<LaporanPresensiPage> createState() => _LaporanPresensiPageState();
}

class _LaporanPresensiPageState extends State<LaporanPresensiPage> {
  List presensiList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPresensi();

    final box = GetStorage();
    final userId = box.read('user')?['id'];
  }

  Future<void> fetchPresensi() async {
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final userId = user['id'];

    final res = await ApiService.getPresensiByUser(userId);

    if (res['status'] == "success") {
      setState(() {
        presensiList = res['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String formatJam(String? value) {
    if (value == null) return "-";

    try {
      final dt = DateTime.parse(value).toLocal(); // konversi WIB
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return "-";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Laporan Presensi",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : presensiList.isEmpty
          ? const Center(child: Text("Tidak ada data presensi"))
          : ListView.builder(
        itemCount: presensiList.length,
        itemBuilder: (context, index) {
          final p = presensiList[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),

            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ====== KOLOM TANGGAL (LEFT) ======
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM').format(DateTime.parse(p['tanggal'])),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F3F),
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(DateTime.parse(p['tanggal'])),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F3F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ====== GARIS TENGAH (SELALU CENTER) ======
                  Container(
                    width: 2,
                    height: 50,              // FIXED HEIGHT → tidak ikut geser
                    color: const Color(0xFF001F3F),
                  ),

                  const SizedBox(width: 15),

                  // ====== KOLOM JAM (RIGHT) ======
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("Masuk: ",
                                style: TextStyle(color: Color(0xFF001F3F))),
                            Text(
                              "${formatJam(p['jam_masuk'])} WIB",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F3F),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text("Keluar: ",
                                style: TextStyle(color: Color(0xFF001F3F))),
                            Text(
                              "${formatJam(p['jam_keluar'])} WIB",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F3F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          );
        },
      ),
    );
  }
}
