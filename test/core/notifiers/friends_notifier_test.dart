import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/notifiers/friends_notifier.dart';
import 'package:memories_project/features/user/models/app_user.dart';
import 'package:mockito/mockito.dart';
import '../../services/contact_service_test.mocks.dart';

void main() {
  late MockContactService mockContactService;
  late FriendsNotifier friendsNotifier;

  final testUser1 = AppUser(uid: '1', username: 'Alice', email: 'a@mail.com', photoURL: 'dd.com', role: 'Lecteur', friends: ['toto','Bob']);
  final testUser2 = AppUser(uid: '2', username: 'Bob', email: 'bob@mail.com', photoURL: 'bb.com', role: 'Lecteur', friends: ['toto','Alice']);

  setUp(() {
    mockContactService = MockContactService();

    // Setup par défaut pour loadCurrentUser & loadFriends
    when(mockContactService.loadCurrentUser()).thenAnswer((_) async {
      return null;
    });
    when(mockContactService.loadFriends()).thenAnswer((_) async {});
    when(mockContactService.friends).thenReturn([testUser1, testUser2]);
    when(mockContactService.getInvitationsSent()).thenAnswer((_) async => 5);
    when(mockContactService.removeFriend(any)).thenAnswer((_) async {});
    when(mockContactService.sendInvite()).thenAnswer((_) async {});

    friendsNotifier = FriendsNotifier(mockContactService);
  });

  test('initial loadFriendsData loads friends and invitations', () async {

    // Attendre la fin des futures
    await Future.delayed(Duration.zero);

    expect(friendsNotifier.state.isLoading, false);
    expect(friendsNotifier.state.friends, containsAll([testUser1, testUser2]));
    expect(friendsNotifier.state.totalInvitationsSent, 5);
    expect(friendsNotifier.state.error, isNull);
  });

  test('loadFriendsData sets error on failure', () async {
    when(mockContactService.loadFriends()).thenThrow(Exception('Failed to load'));

    final notifier = FriendsNotifier(mockContactService);
    await Future.delayed(Duration.zero);

    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, contains('Failed to load'));
  });

  test('removeFriend updates state and calls contactService', () async {
    await friendsNotifier.removeFriend(testUser1);

    verify(mockContactService.removeFriend(testUser1)).called(1);
    expect(friendsNotifier.state.friends, isNot(contains(testUser1)));
  });

  test('sendInvite updates totalInvitationsSent', () async {
    when(mockContactService.getInvitationsSent()).thenAnswer((_) async => 7);

    await friendsNotifier.sendInvite();

    verify(mockContactService.sendInvite()).called(1);
    expect(friendsNotifier.state.totalInvitationsSent, 7);
  });
}
