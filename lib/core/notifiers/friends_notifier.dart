import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/user/models/app_user.dart';
import '../../features/user/services/contact_service.dart';

class FriendsState {
  final List<AppUser> friends;
  final int totalInvitationsSent;
  final bool isLoading;
  final String? error;

  FriendsState({
    this.friends = const [],
    this.totalInvitationsSent = 0,
    this.isLoading = false,
    this.error,
  });

  FriendsState copyWith({
    List<AppUser>? friends,
    int? totalInvitationsSent,
    bool? isLoading,
    String? error,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      totalInvitationsSent: totalInvitationsSent ?? this.totalInvitationsSent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final ContactService contactService;

  FriendsNotifier(this.contactService) : super(FriendsState()) {
    loadFriendsData();
  }

  Future<void> loadFriendsData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await contactService.loadCurrentUser();
      await contactService.loadFriends();
      final friends = contactService.friends;
      final invitations = await contactService.getInvitationsSent();

      state = state.copyWith(
        friends: friends,
        totalInvitationsSent: invitations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeFriend(AppUser friend) async {
    await contactService.removeFriend(friend);
    final updatedFriends = List<AppUser>.from(state.friends)..remove(friend);
    state = state.copyWith(friends: updatedFriends);
  }

  Future<void> sendInvite() async {
    await contactService.sendInvite();
    final invitations = await contactService.getInvitationsSent();
    state = state.copyWith(totalInvitationsSent: invitations);
  }
}
