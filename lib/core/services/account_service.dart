import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_gate.dart';
import '../widgets/loading/loading_screen.dart';

class AccountService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  AccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  Future<void> deleteAccount(BuildContext context, String? currentImageUrl) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoadingScreen(message: 'Suppression du compte en cours'),
      ),
    );

    try {
      final user = auth.currentUser;
      if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'Utilisateur introuvable');

      if (currentImageUrl != null) {
        try {
          await storage.refFromURL(currentImageUrl).delete();
        } catch (_) {
          // Ignore if already deleted or not found
        }
      }

      await firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      await auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
              (_) => false,
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de la suppression du compte : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression du compte')),
        );
      }
    }
  }

  void showDeleteConfirmation(BuildContext context, Future<void> Function() deleteCallback) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              deleteCallback();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> showDeleteConfirmationWeb(BuildContext context, VoidCallback onConfirmed) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirmed();
            },
            child: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

}
