import 'package:flutter/foundation.dart';

class AuthState extends ValueNotifier<bool> {
  AuthState() : super(false);

  bool get isLoggedIn => value;

  void login() {
    value = true;
  }

  void logout() {
    value = false;
  }
}
