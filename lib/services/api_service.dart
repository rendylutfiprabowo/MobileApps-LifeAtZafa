import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/presensi_model.dart';

class ApiService {
  static const baseUrl = 'http://192.168.100.71:3000/api';

  static const _timeout = Duration(seconds: 10);
  //login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      )
          .timeout(_timeout);

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      // Lebih deskriptif: network / timeout / format
      return {
        'statusCode': 500,
        'data': {'message': 'Koneksi gagal: ${e.toString()}'}
      };
    }
  }
  //logout
  static Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      // Ambil token dari GetStorage jika ada
      final box = GetStorage();
      final token = box.read('user')?['token'];

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse('$baseUrl/users/$id'), headers: headers)
          .timeout(_timeout);

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 500, 'data': {'message': 'Error: ${e.toString()}'}};
    }
  }
  //user detail
  static Future<Map<String, dynamic>> getUserDetailById(int id) async {
    try {
      final box = GetStorage();
      final token = box.read('user')?['token'];

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse('$baseUrl/user-details/$id'), headers: headers)
          .timeout(_timeout);

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 500, 'data': {'message': 'Error: ${e.toString()}'}};
    }
  }
  //presensi
  static Future getPresensiByUser(int userId) async {
    final box = GetStorage();
    final token = box.read('user')?['token'];

    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse("$baseUrl/presensi/$userId"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }
  // lokasi kantor user
  static Future<Map<String, dynamic>> getLokasiByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lokasis/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': false,
        'message': e.toString(),
      };
    }
  }
  //absen masuk (tombol)
  static Future<Map<String, dynamic>> absenMasuk(int userId, int shiftId) async {
    try {
      final box = GetStorage();
      final token = box.read('user')?['token'];
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('$baseUrl/presensi/masuk'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'shiftId': shiftId}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 500, 'data': {'message': e.toString()}};
    }
  }
  //absen keluar (tombol)
  static Future<Map<String, dynamic>> absenKeluar(int presensiId) async {
    try {
      final box = GetStorage();
      final token = box.read('user')?['token'];
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('$baseUrl/presensi/keluar'),
        headers: headers,
        body: jsonEncode({'presensiId': presensiId}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 500, 'data': {'message': e.toString()}};
    }
  }
  //istirahat (tombol)
  static Future<Map<String, dynamic>> toggleIstirahat(int presensiId) async {
    try {
      final box = GetStorage();
      final token = box.read('user')?['token'];
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('$baseUrl/presensi/istirahat'),
        headers: headers,
        body: jsonEncode({'presensiId': presensiId}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 500, 'data': {'message': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> getDoListMonthSummary(
      int userId, int year, int month) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/do-list/$userId/month/$year/$month"),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }


  static Future<Map<String, dynamic>> getDoListByDate(int userId, String tanggal) async {
    final box = GetStorage();
    final token = box.read("user")?["token"];

    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse("$baseUrl/do-list/$userId/date/$tanggal"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // GET all todo list by userId
  static Future<Map<String, dynamic>> getDoList(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/do-list/$userId"),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  // CREATE new todo list
  static Future<Map<String, dynamic>> createDoListWithDate({
    required int userId,
    required String nama,
    required String ket,
    required String tanggal,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/do-list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'nama_dolist': nama,
        'keterangan_dolist': ket,
        'tanggal': tanggal,
      }),
    );

    return jsonDecode(response.body);
  }


  static Future tambahDoList({
    required int userId,
    required String namaDolist,
    required String keteranganDolist,
    required String tanggal,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/dolist/"),
      body: {
        "user_id": userId.toString(),
        "nama_dolist": namaDolist,
        "keterangan_dolist": keteranganDolist,
        "tanggal": tanggal,
      },
    );

    return jsonDecode(res.body);
  }




  // TOGGLE done
  static Future<Map<String, dynamic>> toggleDone(int id) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/do-list/done/$id"),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  // TOGGLE favorite
  static Future<Map<String, dynamic>> toggleFavorite(int id) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/do-list/fav/$id"),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  // DELETE
  static Future<Map<String, dynamic>> deleteDoList(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/do-list/$id"),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

}

