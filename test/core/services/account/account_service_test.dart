import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:memories_project/core/services/account_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockReference extends Mock implements Reference {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocRef;
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late AccountService accountService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user123');

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
    when(() => mockDocRef.delete()).thenAnswer((_) async {});
    when(() => mockUser.delete()).thenAnswer((_) async {});
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    when(() => mockStorage.refFromURL(any())).thenReturn(mockRef);
    when(() => mockRef.delete()).thenAnswer((_) async {});

    accountService = AccountService(
      auth: mockAuth,
      firestore: mockFirestore,
      storage: mockStorage,
    );
  });

  testWidgets('deleteAccount deletes user data and profile picture', (tester) async {
    final testWidget = Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () => accountService.deleteAccount(context, 'https://fakeurl.com/image.jpg'),
          child: const Text('Delete'),
        );
      },
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: testWidget)));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockStorage.refFromURL('https://fakeurl.com/image.jpg')).called(1);
    verify(() => mockRef.delete()).called(1);
    verify(() => mockFirestore.collection('users')).called(1);
    verify(() => mockDocRef.delete()).called(1);
    verify(() => mockUser.delete()).called(1);
    verify(() => mockAuth.signOut()).called(1);
  });
}
