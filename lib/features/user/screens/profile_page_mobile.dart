import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/core/widgets/loading_screen.dart';
import 'package:memories_project/core/widgets/stat_card.dart';
import 'package:memories_project/features/user/screens/friends_page.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../logic/profile_service.dart';

class ProfilePageMobile extends StatefulWidget {
  const ProfilePageMobile({super.key});

  @override
  State<ProfilePageMobile> createState() => _ProfilePageMobileState();
}

class _ProfilePageMobileState extends State<ProfilePageMobile> {
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  String? _currentImageUrl;
  bool isLoading = false;
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
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                setState(() => isLoading = true);
                final result = await _profileService.updateProfile(
                    _usernameController.text, _currentImageUrl);
                setState(() {
                  isLoading = false;
                  _isEditing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result ? 'Profil mis à jour!' : 'Erreur de mise à jour'),
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
                  await _profileService.pickAndUploadProfileImage(_currentImageUrl);
                  setState(() {
                    isLoading = false;
                    _currentImageUrl = imageResult['imageUrl'];
                    _selectedImage = imageResult['selectedImage'];
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thème'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.light_mode,
                    color: themeProvider.themeMode == ThemeMode.light
                        ? Colors.amber
                        : Colors.grey),
                onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              IconButton(
                icon: Icon(Icons.dark_mode,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.deepPurple
                        : Colors.grey),
                onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
              IconButton(
                icon: Icon(Icons.settings,
                    color: themeProvider.themeMode == ThemeMode.system
                        ? Colors.blueGrey
                        : Colors.grey),
                onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
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
        StatCard(title: 'Mes souvenirs', count: _memoriesCount, color: Colors.deepPurple),
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
          _profileService.signOut(context);
        }),
        _buildActionCard('Supprimer mon compte', Icons.delete, () {
          _profileService.showDeleteConfirmation(context, () async {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const LoadingScreen(message: 'Suppression...'),
            ));
            await _profileService.deleteAccount(context, _currentImageUrl);
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