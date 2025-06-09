import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/services/media_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockReference extends Mock implements Reference {}
class MockUploadTask extends Mock implements UploadTask {}
class MockTaskSnapshot extends Mock implements TaskSnapshot {}

void main() {
  late MediaService mediaService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;
  late MockUser mockUser;
  late MockReference mockRef;
  late MockUploadTask mockUploadTask;
  late MockTaskSnapshot mockSnapshot;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    mockSnapshot = MockTaskSnapshot();
    mockUploadTask = MockUploadTask();
    mockSnapshot = MockTaskSnapshot();

    // Configuration FirebaseAuth & User
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('testUser');

    // Configuration FirebaseStorage
    when(() => mockStorage.ref()).thenReturn(mockRef);
    when(() => mockRef.child(any())).thenReturn(mockRef);
    when(() => mockRef.putFile(any())).thenReturn(mockUploadTask);
    when(() => mockUploadTask.then(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) {
      final onValue = invocation.positionalArguments[0] as dynamic;
      return Future.value(onValue(mockSnapshot));
    });

    mediaService = MediaService(
      auth: mockAuth,
      firestore: mockFirestore,
      storage: mockStorage,
    );
  });

  test('uploadUserImage uploads file and returns download URL', () async {
    final file = File('dummy.jpg'); // Fichier fictif
    final url = await mediaService.uploadUserImage(file);

    expect(url, 'https://fakeurl.com/image.jpg');
    verify(() => mockStorage.ref()).called(1);
    verify(() => mockRef.putFile(file)).called(1);
    verify(() => mockRef.getDownloadURL()).called(1);
  });

  test('uploadUserImage deletes old image if URL provided', () async {
    final mockOldRef = MockReference();
    when(() => mockStorage.refFromURL(any())).thenReturn(mockOldRef);
    when(() => mockOldRef.delete()).thenAnswer((_) async {});

    final file = File('dummy.jpg');
    final url = await mediaService.uploadUserImage(file, oldImageUrl: 'https://oldurl.com/image.jpg');

    verify(() => mockStorage.refFromURL('https://oldurl.com/image.jpg')).called(1);
    verify(() => mockOldRef.delete()).called(1);
    expect(url, isNotNull);
  });
}
