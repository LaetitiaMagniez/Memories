import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:memories_project/core/services/authentification_service.dart';

import 'authentification_service_test.mocks.dart';
import 'authentification_service_test_wrapper.dart';

@GenerateMocks([
  FirebaseAuth,
  SharedPreferences,
  FlutterSecureStorage,
  LocalAuthentication,
  UserCredential,
  User,
])
void main() {
  late AuthentificationService service;
  late MockFirebaseAuth mockAuth;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();

    service = AuthentificationServiceTestWrapper(
      auth: mockAuth,
      secureStorage: mockSecureStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('Biometric methods', () {
    test('canCheckBiometrics returns true when available', () async {
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await service.canCheckBiometrics();
      expect(result, true);
    });

    test('authenticateWithBiometrics returns false when not available', () async {
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.authenticateWithBiometrics();
      expect(result, false);
    });
  });

  group('Remember Me', () {
    test('save and load rememberMe state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await service.saveRememberMeState(true, 'test@example.com', '1234');
      expect(prefs.getBool('rememberMe'), true);
      expect(prefs.getString('email'), 'test@example.com');
    });

    test('clearSavedCredentials clears data', () async {
      SharedPreferences.setMockInitialValues({'rememberMe': true, 'email': 'test@example.com'});

      final prefs = await SharedPreferences.getInstance();
      await service.clearSavedCredentials();

      expect(prefs.getBool('rememberMe'), null);
      expect(prefs.getString('email'), null);
      verify(mockSecureStorage.delete(key: 'password')).called(1);
    });
  });

  group('Password strength', () {
    test('calculates weak password', () {
      final strength = service.calculatePasswordStrength('abc');
      expect(strength, lessThan(0.5));
      expect(service.getPasswordStrengthText(strength), 'Mot de passe faible');
    });

    test('calculates strong password', () {
      final strength = service.calculatePasswordStrength('abc123!@#');
      expect(strength, equals(1.0));
      expect(service.getPasswordStrengthText(strength), 'Mot de passe fort');
    });
  });

  group('biometricLogin', () {
    test('returns false when credentials are empty', () async {
      when(mockSecureStorage.read(key: 'password')).thenAnswer((_) async => '');
      SharedPreferences.setMockInitialValues({'email': ''});

      final result = await service.biometricLogin();
      expect(result, false);
    });

    test('returns true when login succeeds', () async {
      when(mockSecureStorage.read(key: 'password')).thenAnswer((_) async => 'password123');
      SharedPreferences.setMockInitialValues({'email': 'test@example.com'});
      when(mockAuth.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => MockUserCredential());

      final result = await service.biometricLogin();
      expect(result, true);
    });
  });

  test('isUserLoggedIn returns true if currentUser is not null', () {
    final mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);

    final result = service.isUserLoggedIn();
    expect(result, true);
  });
}
