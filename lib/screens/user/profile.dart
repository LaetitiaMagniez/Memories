import 'package:flutter/material.dart';
import 'package:memories_project/screens/user/friendsPage.dart';
import 'package:memories_project/service/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:memories_project/transition/loadingScreen.dart';

import '../../class/statCard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isEditing = false;
  int _albumCount = 0;
  int _memoriesCount = 0;
  int _sharedAlbumCount = 0;
  int _sharedMemoriesCount = 0;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = await _profileService.loadUserData();
    setState(() {
      _usernameController.text = data['username'] ?? '';
      _currentImageUrl = data['profilePicture'];
    });

    final counts = await _profileService.loadCounts();
    setState(() {
      _albumCount = counts['albumCount'] ?? 0;
      _memoriesCount = counts['memoriesCount'] ?? 0;
      _sharedAlbumCount = counts['sharedAlbumCount'] ?? 0;
      _sharedMemoriesCount = counts['sharedMemoriesCount'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                setState(() {
                  _isLoading = true;
                });
                final result = await _profileService.updateProfile(
                    _usernameController.text, _currentImageUrl);
                setState(() {
                  _isLoading = false;
                  _isEditing = false;
                });
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil mis à jour!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erreur lors de la mise à jour du profil')),
                  );
                }
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final profileImageUrl =
                          userData?['profilePicture'] as String?;

                      return GestureDetector(
                        onTap: _isEditing
                            ? () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                final imageResult = await _profileService
                                    .pickAndUploadProfileImage(
                                        _currentImageUrl);
                                setState(() {
                                  _isLoading = false;
                                  _currentImageUrl = imageResult['imageUrl'];
                                  _selectedImage = imageResult['selectedImage'];
                                });
                                if (_currentImageUrl != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Image de profil mise à jour avec succès')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Erreur lors de la mise à jour de l\'image de profil')),
                                  );
                                }
                              }
                            : null,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      );
                    }
                    return const CircleAvatar(
                      radius: 60,
                      child: Icon(Icons.person, size: 60),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                if (_isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _usernameController.text,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Email: ${FirebaseAuth.instance.currentUser?.email ?? 'Non disponible'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                // Ajout des cartes statistiques
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      title: 'Mes albums',
                      count: _albumCount,
                      color: const Color.fromARGB(255, 138, 87, 220),
                    ),
                    StatCard(
                      title: 'Albums collaboratifs',
                      count: _sharedAlbumCount,
                      color: const Color.fromARGB(255, 190, 149, 255),
                    ),
                    StatCard(
                      title: 'Mes souvenirs',
                      count: _memoriesCount,
                      color: const Color.fromARGB(255, 190, 149, 255),
                    ),
                    StatCard(
                      title: 'Souvenirs partagés',
                      count: _sharedMemoriesCount,
                      color: const Color.fromARGB(255, 138, 87, 220),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Card(
                  color: const Color.fromARGB(255, 138, 87, 220),
                  elevation: 4,
                  child: InkWell(
                    onTap: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FriendsPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Mes amis', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color.fromARGB(255, 138, 87, 220),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _profileService.signOut(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        children: [
                          const Icon(Icons.power_settings_new, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Déconnexion', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color.fromARGB(255, 220, 158, 87),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _profileService.showDeleteConfirmation(
                        context, () async {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => LoadingScreen(
                            message: 'Suppression du compte en cours'),
                      ));

                      await _profileService.deleteAccount(
                          context, _currentImageUrl);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Supprimer mon compte', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
