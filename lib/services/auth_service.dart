import 'package:get_storage/get_storage.dart';

class AuthService {
  final box = GetStorage();

  void loginSuccess({required Map<String, dynamic> user}) {
    // user should contain token and other fields
    box.write('isLoggedIn', true);
    box.write('user', user);
    if (user.containsKey('token')) {
      box.write('token', user['token']);
    }
  }

  void logout() {
    box.remove('isLoggedIn');
    box.remove('user');
    box.remove('token');
  }

  bool isLoggedIn() {
    return box.read('isLoggedIn') ?? false;
  }

  Map<String, dynamic>? currentUser() {
    return box.read('user');
  }

  String? token() {
    return box.read('token');
  }
}



// import 'package:get_storage/get_storage.dart';
//
// class AuthService {
//   final box = GetStorage();
//
//   void loginSuccess() {
//     box.write('isLoggedIn', true);
//   }
//
//   void logout() {
//     box.remove('isLoggedIn');
//   }
//
//   bool isLoggedIn() {
//     return box.read('isLoggedIn') ?? false;
//   }
// }
