import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/api_service.dart';
import 'package:intl/intl.dart';

class DetailTugasPage extends StatefulWidget {
  final int userId;
  final String tanggal;

  const DetailTugasPage({
    super.key,
    required this.userId,
    required this.tanggal,
  });

  @override
  State<DetailTugasPage> createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage> {

  final box = GetStorage();
  bool isLoading = false;
  List doList = [];

  // controller dialog
  final TextEditingController namaC = TextEditingController();
  final TextEditingController ketC = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadTugas();
  }

  Future<void> loadTugas() async {
    setState(() => isLoading = true);

    final res = await ApiService.getDoListByDate(
      widget.userId,
      widget.tanggal,
    );

    setState(() {
      doList = res["data"] ?? [];
      isLoading = false;
    });
  }

  void showTambahTugasDialog() {
    namaC.clear();
    ketC.clear();
    selectedDate = DateTime.parse(widget.tanggal); // default dari calendar

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Tambah Tugas",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: namaC,
                      decoration: InputDecoration(
                        labelText: "Judul do list",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: ketC,
                      decoration: InputDecoration(
                        labelText: "Keterangan",
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 15),

                    // pilih tanggal
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? "Belum pilih tanggal"
                                : "Tanggal: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pick = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (pick != null) {
                              setStateDialog(() {
                                selectedDate = pick;
                              });
                            }
                          },
                          child: const Text("Pilih"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                          ElevatedButton(
                            onPressed: () async {
                              final res = await ApiService.createDoListWithDate(
                                userId: widget.userId,
                                nama: namaC.text,
                                ket: ketC.text,
                                tanggal: DateFormat("yyyy-MM-dd").format(selectedDate!),
                              );
                              print('Response: $res');
                              Navigator.pop(context);
                              loadTugas();
                            },
                            child: const Text("Simpan"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Tugas",
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF001F3F),
        onPressed: showTambahTugasDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // ----------- CARD INFORMASI TANGGAL -----------
          Card(
            color: const Color(0xFF001F3F),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Center(
                child: Text(
                  "${DateFormat.EEEE('id_ID').format(DateTime.parse(widget.tanggal))} - ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(widget.tanggal))}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // biar kontras dengan background biru
                  ),
                ),
              ),
            ),
          ),


          // ----------- LIST DO LIST -----------
          ...doList.map((d) {
            final int id = d["id"];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () async {
                    await ApiService.toggleDone(id);
                    loadTugas();
                  },
                  child: Icon(
                    d["done"] == 1
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: d["done"] == 1 ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(
                  d["nama_dolist"] ?? "-",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.justify,
                ),
                subtitle: Text(
                  d["keterangan_dolist"] ?? "-",
                  style: GoogleFonts.poppins(fontSize: 12),
                  textAlign: TextAlign.justify,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await ApiService.toggleFavorite(id);
                        loadTugas();
                      },
                      child: Icon(
                        Icons.star,
                        color: d["favorite"] == 1 ? Colors.amber : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final ok = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Hapus"),
                            content: const Text("Hapus tugas ini?"),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Batal")),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.red),
                                  )),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await ApiService.deleteDoList(id);
                          loadTugas();
                        }
                      },
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),

    );
  }
}
