import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/services/memories_dialogs.dart';
import '../../../core/services/media_service.dart';
import '../models/memory.dart';

class MemoriesOptionsMenu {

  final MediaService mediaService =  MediaService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
  final MemoriesDialogs memoriesDialogs = MemoriesDialogs();

  void showMemoriesOptions(
      BuildContext context,
      String albumId,
      VoidCallback onManageMode, {
        required VoidCallback onUploadStart,
        required void Function(double progress) onUploadProgress,
        required void Function(String uploadedUrl) onUploadFinish,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Wrap(
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.deepPurple),
                title: const Text('Ajouter une photo'),
                onTap: () async {
                  Navigator.pop(context);
                  onUploadStart.call();
                  mediaService.pickAndUploadMedia(
                    context: context,
                    albumId: albumId,
                    type: 'image',
                    onUploadProgress: onUploadProgress,
                  ).then((uploadedUrl) {
                    if (uploadedUrl != null) {
                      onUploadFinish(uploadedUrl);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                title: const Text('Ajouter une vidéo'),
                onTap: () async {
                  Navigator.pop(context);
                  onUploadStart.call();
                  mediaService.pickAndUploadMedia(
                    context: context,
                    albumId: albumId,
                    type: 'video',
                    onUploadProgress: onUploadProgress,
                  ).then((uploadedUrl) {
                    if (uploadedUrl != null) {
                      onUploadFinish(uploadedUrl);
                    }
                  });                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Gérer les souvenirs'),
                onTap: () {
                  Navigator.pop(context);
                  onManageMode();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> showOptionsForMemory({
    required BuildContext context,
    required Memory memory,
    required String currentAlbumId,
    required Future<void> Function(String albumId, String memoryId) deleteMemory,
    required VoidCallback refreshUI,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Supprimer"),
              onTap: () {
                Navigator.pop(context);
                memoriesDialogs.confirmDeleteSingleMemory(
                  context: context,
                  albumId: currentAlbumId,
                  memory: memory,
                  deleteMemory: deleteMemory,
                  refreshUI: refreshUI,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text("Déplacer vers un autre album"),
              onTap: () {
                Navigator.pop(context);
                memoriesDialogs.moveSingleMemory(
                  context: context,
                  currentAlbumId: currentAlbumId,
                  memory: memory,
                  deleteMemory: deleteMemory,
                  refreshUI: refreshUI,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

