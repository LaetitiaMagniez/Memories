import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifiers/friends_notifier.dart';
import '../../../core/providers/app_providers.dart';

class FriendsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsNotifierProvider);
    final friendsNotifier = ref.read(friendsNotifierProvider.notifier);

    // Charge les données au premier build
    ref.listen<FriendsState>(friendsNotifierProvider, (previous, next) {
      if (previous == null && !next.isLoading && next.friends.isEmpty && next.error == null) {
        friendsNotifier.loadFriendsData();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: friendsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendsState.error != null
          ? Center(child: Text('Erreur: ${friendsState.error}'))
          : friendsState.friends.isEmpty
          ? const Center(child: Text('Pas encore d\'amis'))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (friendsState.totalInvitationsSent > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Vous avez envoyé ${friendsState.totalInvitationsSent} invitation(s)'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: friendsState.friends.length,
              itemBuilder: (context, index) {
                final friend = friendsState.friends[index];
                return ListTile(
                  leading: friend.photoURL.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(friend.photoURL))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(friend.username),
                  subtitle: Text('Role: ${friend.role}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => friendsNotifier.removeFriend(friend),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => friendsNotifier.sendInvite(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
