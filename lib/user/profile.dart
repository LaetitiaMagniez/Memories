import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:memories_project/home.dart';
import 'package:memories_project/transition/loadingScreen.dart';

import '../authentification/auth_gate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  String? _currentImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Naviguez vers l'écran de connexion après la déconnexion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        setState(() {
          _usernameController.text = userData.data()?['username'] ?? '';
          _currentImageUrl = userData.data()?['profilePicture'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        maxWidth: 700,
        maxHeight: 700,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          )
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Supprimer l'ancienne image
            if (_currentImageUrl != null) {
              final oldImageRef = FirebaseStorage.instance.refFromURL(_currentImageUrl!);
              await oldImageRef.delete();
            }

            final File imageFile = File(croppedFile.path);
            final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final Reference storageRef = FirebaseStorage.instance.ref().child('user_images/$fileName');

            final UploadTask uploadTask = storageRef.putFile(imageFile);
            final TaskSnapshot taskSnapshot = await uploadTask;
            final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

            setState(() {
              _currentImageUrl = downloadUrl;
              _selectedImage = imageFile;
            });

            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'profilePicture': downloadUrl,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image de profil mise à jour avec succès')),
            );
          }
        } catch (e) {
          print('Erreur lors du téléchargement de l\'image : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour de l\'image de profil')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user != null) {
        String? imageUrl = _currentImageUrl;

        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images/${user.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        await _firestore.collection('users').doc(user.uid).set({
          'username': _usernameController.text,
          'profilePicture': imageUrl,
        }, SetOptions(merge: true));

        await user.updateDisplayName(_usernameController.text);
        if (imageUrl != null) {
          await user.updatePhotoURL(imageUrl);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour!')),
        );

        setState(() {
          _isEditing = false;
          _currentImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour le profil, réessayez.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text(
          "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteAccount();
            },
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}


  Future<void> _deleteAccount() async {
  
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => LoadingScreen(message:'Suppression du compte en cours'),
  ));
  
  try {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    // Supprimer l'image de profil de Firebase Storage
    if (_currentImageUrl != null) {
      final ref = FirebaseStorage.instance.refFromURL(_currentImageUrl!);
      await ref.delete();
    }

    // Supprimer les données Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // Supprimer le compte Firebase
    await user.delete();

    // Déconnexion et redirection
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
  } catch (e) {
    print("Erreur lors de la suppression du compte : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de la suppression du compte')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  )
                ,
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
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
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final profileImageUrl = userData?['profilePicture'] as String?;
                  
                  return GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
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
          if (_isEditing)
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
              textAlign: TextAlign.center,
            )
          else
            Text(
              _usernameController.text,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          if (_isEditing)
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Mettre à jour mes infos'),
            )
          else
            Text(
              'Email: ${_auth.currentUser?.email ?? 'Non disponible'}',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _signOut(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 138, 87, 220),
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
          ElevatedButton(
            onPressed: _showDeleteConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 220, 158, 87),
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer mon compte'),
          ),
        ],
      ),
    ),
  ),
)
    );

  }
}
