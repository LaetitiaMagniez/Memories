import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memories_project/album/album_list.dart';
import 'package:memories_project/calendar.dart';
import 'package:memories_project/map.dart';
import 'package:memories_project/user/updateProfile.dart';
import 'package:memories_project/user/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            actions: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final profileImageUrl = userData?['profilePicture'] as String?;
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ),
                    );
                  }
                  return IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            automaticallyImplyLeading: false,
          ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Image.asset('assets/dash.png'),
              ),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                  );
                },
                child: const Text('Mettre à jour le profil'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () { Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlbumListPage()),
                  );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 138, 87, 220),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mes albums'),
              ),
               const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () { Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapPage()),
                  );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 138, 87, 220),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Carte de mes souvenirs'),
              ),
              ElevatedButton(
                onPressed: () { Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarPage()),
                  );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 138, 87, 220),
                  foregroundColor: Colors.white,
                ),
                child: Text('Calendrier des souvenirs'),
                )

            ],
          ),
        ),
      ),
    );
  }
}
