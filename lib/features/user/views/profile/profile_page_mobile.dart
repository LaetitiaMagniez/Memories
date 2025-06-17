import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/core/services/account_service.dart';
import 'package:memories_project/core/services/media_service.dart';
import 'package:memories_project/core/widgets/loading/loading_screen.dart';
import 'package:memories_project/core/models/stats/stat_card.dart';
import 'package:memories_project/features/user/services/user_service.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../memories/views/all_memories_list.dart';
import '../friends_page.dart';


class ProfilePageMobile extends ConsumerStatefulWidget {
  const ProfilePageMobile({super.key});

  @override
  ConsumerState<ProfilePageMobile> createState() => _ProfilePageMobileState();
}

class _ProfilePageMobileState extends ConsumerState<ProfilePageMobile> {
  final AccountService accountService = AccountService();
  final MediaService mediaService = MediaService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance
  );  final UserService userService = UserService();
  final TextEditingController _usernameController = TextEditingController();

  File? _selectedImage;
  String? _currentImageUrl;
  bool isLoading = false;
  bool _isEditing = false;
  int _albumCount = 0;
  int _memoriesCount = 0;
  int _sharedAlbumCount = 0;
  int _sharedMemoriesCount = 0;


  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = await userService.loadUserData();
    setState(() {
      _usernameController.text = data['username'] ?? '';
      _currentImageUrl = data['profilePicture'];
    });

    final counts = await userService.loadCounts();
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
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                setState(() => isLoading = true);

                final bool updateSuccess = await userService.updateProfile(
                  _usernameController.text,
                  _selectedImage,
                  imageUrl: _currentImageUrl,
                );

                setState(() {
                  isLoading = false;
                  _isEditing = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(updateSuccess ? 'Profil mis à jour!' : 'Erreur de mise à jour'),
                ));
              } else {
                setState(() => _isEditing = true);
              }
            },
          )
        ],
      ),
      body: isLoading
          ? const LoadingScreen(message: 'Chargement...')
          : _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final profileImageUrl = userData?['profilePicture'] as String?;
              return GestureDetector(
                onTap: _isEditing
                    ? () async {
                  setState(() => isLoading = true);
                  final imageResult =
                  await mediaService.pickAndUploadProfileImage(_currentImageUrl);
                  setState(() {
                    isLoading = false;
                    _currentImageUrl = imageResult.imageUrl;
                    _selectedImage = imageResult.selectedImage;
                  });
                }
                    : null,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                  profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildUserInfo(),
          const SizedBox(height: 24),
          if (_isEditing) _buildThemeSelector(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 32),
          _buildActionLinks(context),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8),
            _isEditing
                ? Expanded(
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                ),
              ),
            )
                : Text(_usernameController.text),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email),
            const SizedBox(width: 8),
            Text(FirebaseAuth.instance.currentUser?.email ?? 'Non disponible'),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final themeMode = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Thème'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.light_mode,
                color: themeMode == ThemeMode.light ? Colors.amber : Colors.grey,
              ),
              onPressed: () => themeNotifier.setThemeMode(ThemeMode.light),
            ),
            IconButton(
              icon: Icon(
                Icons.dark_mode,
                color: themeMode == ThemeMode.dark ? Colors.deepPurple : Colors.grey,
              ),
              onPressed: () => themeNotifier.setThemeMode(ThemeMode.dark),
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: themeMode == ThemeMode.system ? Colors.blueGrey : Colors.grey,
              ),
              onPressed: () => themeNotifier.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        StatCard(title: 'Mes albums', count: _albumCount, color: Colors.purple),
        StatCard(title: 'Albums collaboratifs', count: _sharedAlbumCount, color: Colors.purpleAccent),

        // 👉 Version avec InkWell + ripple effect
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AllMemoriesPage()),
            );
          },
          borderRadius: BorderRadius.circular(12), // optionnel pour arrondir le ripple
          child: StatCard(title: 'Mes souvenirs', count: _memoriesCount, color: Colors.deepPurple),
        ),

        StatCard(title: 'Souvenirs partagés', count: _sharedMemoriesCount, color: Colors.deepPurpleAccent),
      ],
    );
  }

  Widget _buildActionLinks(BuildContext context) {
    return Column(
      children: [
        _buildActionCard('Mes amis', Icons.people, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage()));
        }),
        _buildActionCard('Déconnexion', Icons.logout, () {
          userService.signOut(context);
        }),
        _buildActionCard('Supprimer mon compte', Icons.delete, () {
          accountService.showDeleteConfirmation(context, () async {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const LoadingScreen(message: 'Suppression...'),
            ));
            await accountService.deleteAccount(context, _currentImageUrl);
          });
        }, color: Colors.orange),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap,
      {Color color = Colors.purple}) {
    return Card(
      color: color,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}