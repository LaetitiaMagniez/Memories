import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memories_project/core/utils/date_picker.dart';
import '../../../core/widgets/dialogs/dialogs.dart';
import '../../../core/widgets/loading/upload_progress_bubble.dart';
import '../models/album.dart';
import '../views/album_details.dart';
import 'album_repository.dart';
import 'album_utils.dart';
import '../../../core/notifiers/selected_items_notifier.dart';

class AlbumDialogs {
  final albumUtils = AlbumUtils();
  final albumRepository = AlbumRepository();
  final DatePicker datePicker = DatePicker();

  Future<Album?> showCreateAlbumDialog(BuildContext context, {VoidCallback? onAlbumCreated}) async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    DateTime? selectedDate;
    bool noCity = false;
    bool isCreating = false;
    double progress = 0.0;

    final completer = Completer<Album?>();

    showDialog(
      context: context,
      barrierDismissible: !isCreating,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> createAlbum() async {
              if (nameController.text.isEmpty) {
                albumUtils.showSnackBar(context, 'Le nom de l\'album ne peut pas être vide.');
                return;
              }
              if (selectedDate == null) {
                albumUtils.showSnackBar(context, 'Veuillez sélectionner une date.');
                return;
              }
              if (selectedDate!.isAfter(DateTime.now())) {
                albumUtils.showSnackBar(context, 'La date ne peut pas être dans le futur.');
                return;
              }

              setState(() {
                isCreating = true;
                progress = 0.1;
              });

              final albumData = {
                'name': nameController.text,
                'date': selectedDate!.toIso8601String(),
                'city': noCity ? null : cityController.text,
                'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
              };

              try {
                final docRef = await FirebaseFirestore.instance.collection('albums').add(albumData);

                setState(() {
                  progress = 1.0;
                });

                await Future.delayed(const Duration(milliseconds: 500));

                final albumId = docRef.id;
                final albumName = albumData['name']!;

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Fermer le dialog proprement
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailsPage(
                        albumId: albumId,
                        albumName: albumName,
                      ),
                    ),
                  );
                }

                if (onAlbumCreated != null) {
                  onAlbumCreated();
                }

                completer.complete(
                  Album(
                    id: albumId,
                    userId: albumData['createdBy']!,
                    name: albumName,
                    thumbnailUrl: '',
                    thumbnailType: '',
                    itemCount: 0,
                  ),
                );
              } catch (e, stackTrace) {
                print('[ERROR] Erreur création album: $e\n$stackTrace');
                setState(() {
                  isCreating = false;
                });
                albumUtils.showSnackBar(
                  context,
                  'Erreur lors de la création de l\'album.',
                  backgroundColor: theme.colorScheme.error,
                );
                completer.complete(null);
              }
            }

            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: const Text('Créer un nouvel album'),
              titleTextStyle: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              content: isCreating
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  UploadProgressBubble(progress: progress),
                  const SizedBox(height: 16),
                  Text(
                    progress >= 1.0 ? "Album créé" : "Création de l'album...",
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                ],
              )
                  : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Nom de l'album",
                        hintStyle: TextStyle(color: theme.hintColor),
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final picked = await datePicker.selectDate(context);
                            if (picked != null) setState(() => selectedDate = picked);
                          },
                          child: Text(
                            selectedDate == null
                                ? 'Choisir une date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!noCity)
                      TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          hintText: "Ville (optionnelle)",
                          hintStyle: TextStyle(color: theme.hintColor),
                        ),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      ),
                    Row(
                      children: [
                        Checkbox(
                          value: noCity,
                          onChanged: (bool? value) =>
                              setState(() => noCity = value ?? false),
                        ),
                        const Text('Pas de ville'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: isCreating
                  ? null
                  : <Widget>[
                TextButton(
                  child: Text('Annuler', style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: () {
                    if (!isCreating) {
                      Navigator.pop(dialogContext);
                      completer.complete(null);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text('Créer'),
                  onPressed: () => createAlbum(),
                ),
              ],
            );
          },
        );
      },
    );

    return completer.future;
  }


  Future<void> renameAlbum(BuildContext context, Album album) async {
    final controller = TextEditingController(text: album.name);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          'Renommer l\'album',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Nouveau nom de l'album",
            hintStyle: TextStyle(color: theme.hintColor),
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Renommer'),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('albums')
                    .doc(album.id)
                    .update({'name': controller.text});
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> confirmDeleteSelectedAlbums(
      BuildContext context,
      SelectedItemsNotifier<Album> albumSelectionNotifier,
      VoidCallback refreshUI,
      ) async {
    CoreDialogs.confirmDeleteSelected<Album>(
      context: context,
      selectedItems: albumSelectionNotifier.selectedItems,
      itemNameSingular: 'cet album',
      itemNamePlural: 'ces albums',
      onDelete: (album) async {
        await albumRepository.deleteAlbum(album.id);
      },
      onSuccess: refreshUI,
    );
  }

  Future<void> confirmDeleteAlbum(
      BuildContext context,
      Album album,
      VoidCallback refreshUI,
      ) async {
    CoreDialogs.confirmDeleteSingle<Album>(
      context: context,
      item: album,
      itemName: 'cet album',
      onDelete: (album) async {
        await albumRepository.deleteAlbum(album.id);
      },
      onSuccess: refreshUI,
    );
  }

  Future<Album?> showAlbumPickerDialog(BuildContext context, List<Album> albums) {
    return showDialog<Album>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir un album à partager'),
        children: albums
            .map(
              (album) => SimpleDialogOption(
            child: Text(album.name),
            onPressed: () => Navigator.pop(context, album),
          ),
        )
            .toList(),
      ),
    );
  }

  Future<String?> showShareDialog(BuildContext context) async {
    String friendUid = '';
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Partager l'album"),
        content: TextField(
          onChanged: (value) => friendUid = value,
          decoration: const InputDecoration(hintText: "UID de l'ami"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, friendUid),
            child: const Text("Partager"),
          ),
        ],
      ),
    );
  }
}
