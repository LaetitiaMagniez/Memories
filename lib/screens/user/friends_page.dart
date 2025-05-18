import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/contact_service.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<AppUser> _friends = [];
  final ContactService contactService = ContactService();
  int totalInvitationsSent = 0;

  @override
  void initState() {
    super.initState();
    contactService.loadCurrentUser();
    contactService.loadFriends().then((_) {
      setState(() {
        _friends = contactService.friends;
        totalInvitationsSent = contactService.getInvitationsSent();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalInvitationsSent > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Vous avez envoyé $totalInvitationsSent invitation(s)'),
            ),
          Expanded(
            child: _friends.isEmpty
                ? Center(
              child: Text('Pas encore d\'amis'),
            )
                : ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(friend.photoURL ?? ''),
                  ),
                  title: Text(friend.displayName ?? ''),
                  subtitle: Text('Role: ${friend.role ?? 'Reader'}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => contactService.removeFriend(friend),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          contactService.sendInvite();
        },
        child: Icon(Icons.person_add),
      ),
    );
  }
}
