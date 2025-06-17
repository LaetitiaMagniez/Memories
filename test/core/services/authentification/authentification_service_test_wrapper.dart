import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:memories_project/core/services/authentification_service.dart';

class AuthentificationServiceTestWrapper extends AuthentificationService {
  final FirebaseAuth auth;
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;

  AuthentificationServiceTestWrapper({
    required this.auth,
    required this.secureStorage,
    required this.localAuth,
  });

  @override
  FirebaseAuth get _auth => auth;

  @override
  FlutterSecureStorage get _secureStorage => secureStorage;

  @override
  LocalAuthentication get _localAuth => localAuth;
}
