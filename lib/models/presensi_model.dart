class PresensiModel {
  final int id;
  final String tanggal;
  final String jamMasuk;
  final String jamKeluar;
  final String status;
  final String? fotoMasuk;
  final String? fotoKeluar;

  PresensiModel({
    required this.id,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamKeluar,
    required this.status,
    this.fotoMasuk,
    this.fotoKeluar,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'],
      tanggal: json['tanggal'] ?? '',
      jamMasuk: json['jam_masuk'] ?? '',
      jamKeluar: json['jam_keluar'] ?? '',
      status: json['status'] ?? '',
      fotoMasuk: json['foto_masuk'],
      fotoKeluar: json['foto_keluar'],
    );
  }
}
