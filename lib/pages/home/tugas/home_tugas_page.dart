import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/api_service.dart';
import 'detail_tugas_page.dart';
import 'package:intl/intl.dart';

class HomeTugasPage extends StatefulWidget {
  const HomeTugasPage({super.key});

  @override
  State<HomeTugasPage> createState() => _HomeTugasPageState();
}

class _HomeTugasPageState extends State<HomeTugasPage> {
  final box = GetStorage();

  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> summary = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMonthlySummary();
  }

  // Future<void> loadMonthlySummary() async {
  //   final user = box.read("user");
  //   final userId = user["id"];
  //
  //   setState(() => isLoading = true);
  //
  //   final res = await ApiService.getDoListMonthSummary(
  //     userId,
  //     currentMonth.year,
  //     currentMonth.month,
  //   );
  //
  //   setState(() {
  //     summary = res["data"] ?? {};
  //     isLoading = false;
  //   });
  // }
  Future<void> loadMonthlySummary() async {
    final user = box.read("user");
    final userId = user["id"];

    setState(() => isLoading = true);

    final res = await ApiService.getDoListMonthSummary(
      userId,
      currentMonth.year,
      currentMonth.month,
    );

    // convert list menjadi map keyed by date
    final Map<String, bool> tempSummary = {};
    if (res["data"] != null) {
      for (var item in res["data"]) {
        final dateStr = item["tanggal"];
        final pending = int.tryParse(item["pending"].toString()) ?? 0;
        tempSummary[dateStr] = pending > 0; // true jika ada pending
      }
    }

    setState(() {
      summary = tempSummary; // ← summary sekarang map, bukan list
      isLoading = false;
    });
  }


  void prevMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
    loadMonthlySummary();
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
    loadMonthlySummary();
  }

  @override
  Widget build(BuildContext context) {
    final user = box.read("user");
    final userId = user["id"];

    final totalDays =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    final List<DateTime> days = [];

    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(0));
    }

    for (int day = 1; day <= totalDays; day++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, day));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tugas",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // ---------------- HEADER MONTH -----------------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(onPressed: prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(
                  DateFormat("MMMM yyyy", "id_ID").format(currentMonth),
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(onPressed: nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),

          // ---------------- DAY LABELS -----------------
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
                  .map((e) => Expanded(
                child: Center(
                  child: Text(
                    e,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),

          // ---------------- CALENDAR GRID -----------------
          Expanded(
            child: GridView.builder(
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final day = days[i];

                if (day.year == 0) {
                  return Container(); // kosong sebelum tanggal 1
                }

                final dateStr =
                    "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

                final hasPending = summary[dateStr] == true; // ← CEK PENDING

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailTugasPage(
                          userId: userId,
                          tanggal: dateStr,
                        ),
                      ),
                    ).then((_) => loadMonthlySummary());
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            day.day.toString(),
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),

                        // DOT HIJAU
                        if (hasPending) // ← HANYA TANGGAL DENGAN PENDING
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.circle,
                                size: 10, color: Colors.green), // ← warna hijau/biru
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
