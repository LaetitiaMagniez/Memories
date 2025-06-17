import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/core/services/account_service.dart';
import 'package:memories_project/core/widgets/loading/loading_screen.dart';
import 'package:memories_project/core/models/stats/stat_card.dart';
import '../../../../core/models/action_card_web.dart';
import '../../../../core/models/stats/hoverable_stat_card_web.dart';
import '../../../../core/models/stats/stat_card_web.dart';
import '../../../../core/models/uploaded_image_result.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../core/services/media_service.dart';
import '../../../memories/views/all_memories_list.dart';
import '../../services/user_service.dart';
import '../friends_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePageWeb extends ConsumerStatefulWidget  {
  const ProfilePageWeb({super.key});

  @override
  ConsumerState<ProfilePageWeb> createState() => _ProfilePageWebState();
}

class _ProfilePageWebState extends ConsumerState<ProfilePageWeb> {
  final AccountService accountService = AccountService();
  final MediaService mediaService = MediaService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance
  );  final UserService userService = UserService();

  final TextEditingController _usernameController = TextEditingController();
  String? _currentImageUrl;
  File? _selectedImage;

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
        title: const Text('Profil (Web)'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                setState(() => isLoading = true);

                final UploadedImageResult imageResult =
                await mediaService.pickAndUploadProfileImage(_currentImageUrl);

                setState(() {
                  _currentImageUrl = imageResult.imageUrl;
                  _selectedImage = imageResult.selectedImage;
                });

                final success = await userService.updateProfile(
                  _usernameController.text,
                  _selectedImage,
                  imageUrl: _currentImageUrl,
                );

                setState(() {
                  isLoading = false;
                  _isEditing = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Profil mis à jour!' : 'Erreur de mise à jour'),
                ));
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => userService.signOut(context),
          ),
        ],
      ),
      body: isLoading
          ? const LoadingScreen(message: 'Chargement...')
          : Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(24),
          child: _buildProfileContent(context),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage:
          _currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null,
          child: _currentImageUrl == null ? const Icon(Icons.person, size: 60) : null,
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
                ? SizedBox(
              width: 300,
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
    final isWeb = kIsWeb;

    if (isWeb) {
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
          StatCardWeb(title: 'Mes albums', count: _albumCount, color: Colors.purple),
          StatCardWeb(title: 'Albums collaboratifs', count: _sharedAlbumCount, color: Colors.purpleAccent),

          HoverableStatCardWeb(
            title: 'Mes souvenirs',
            count: _memoriesCount,
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AllMemoriesPage()));
            },
          ),

          StatCardWeb(title: 'Souvenirs partagés', count: _sharedMemoriesCount, color: Colors.deepPurpleAccent),
        ],
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          StatCard(title: 'Mes albums', count: _albumCount, color: Colors.purple),
          StatCard(title: 'Albums collaboratifs', count: _sharedAlbumCount, color: Colors.purpleAccent),
          StatCard(title: 'Mes souvenirs', count: _memoriesCount, color: Colors.deepPurple),
          StatCard(title: 'Souvenirs partagés', count: _sharedMemoriesCount, color: Colors.deepPurpleAccent),
        ],
      );
    }
  }


  Widget _buildActionLinks(BuildContext context) {
    final isWeb = kIsWeb;

    if (isWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ActionCardWeb(
            title: 'Mes amis',
            icon: Icons.people,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage()));
            },
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          ActionCardWeb(
            title: 'Supprimer mon compte',
            icon: Icons.delete,
            onTap: () {
              accountService.showDeleteConfirmationWeb(context, () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const LoadingScreen(message: 'Suppression...'),
                ));
                await accountService.deleteAccount(context, _currentImageUrl);
              });
            },
            color: Colors.orange,
          ),
        ],
      );
    } else {
      // Ancienne version mobile/tablette avec des cards classiques
      return Column(
        children: [
          _buildActionCard('Mes amis', Icons.people, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage()));
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
            mainAxisAlignment: MainAxisAlignment.center,
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