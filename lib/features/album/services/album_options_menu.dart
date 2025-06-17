import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_provider.dart';
import '../../user/services/contact_service.dart';
import '../models/album.dart';
import '../services/album_dialogs.dart';
import '../services/album_utils.dart';
import '../views/album_details.dart';

class AlbumOptionsMenu  {

   Future<void> showOptions(
       BuildContext context,
       WidgetRef ref,
       List<Album> selectedAlbums,
      VoidCallback onManageMode, {
         required VoidCallback refreshUI,
         required VoidCallback onManageAlbums,
         required VoidCallback onAlbumsDeleted,
         required VoidCallback onAlbumRenamed})
   async {
     final selectionNotifier = ref.read(selectedAlbumsProvider.notifier);

     final theme = Theme.of(context);
    final albumDialogs = AlbumDialogs();
    final albumUtils = AlbumUtils();
    final contactService = ref.watch(contactServiceProvider);
    final firebaseUser = ref.watch(firebaseUserProvider).asData?.value;
    final userId = firebaseUser?.uid;

    if (userId == null) return;

    final bool singleSelection = selectedAlbums.length == 1;
    final Album? singleAlbum = singleSelection ? selectedAlbums.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                children: [
                  _buildDragHandle(theme),
                  _buildOptionTile(context, Icons.photo_album, "Créer un album", () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));

                    final Album? newAlbum = await albumDialogs.showCreateAlbumDialog(
                      context,
                      onAlbumCreated: refreshUI,
                    );

                    if (newAlbum != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailsPage(
                            albumId: newAlbum.id,
                            albumName: newAlbum.name,
                          ),
                        ),
                      );
                    }
                  }),
                  _buildOptionTile(context, Icons.settings, "Gérer les albums", () {
                    Navigator.pop(context);
                    onManageAlbums();
                  }),
                  _buildOptionTile(context, Icons.person_add, "Inviter des amis", () {
                    Navigator.pop(context);
                    contactService.sendInvite();
                  }),
                  _buildOptionTile(context, Icons.share, "Partager un album", () async {
                    Navigator.pop(context);
                    await _handleShare(context, ref, selectedAlbums, userId, albumUtils, albumDialogs, contactService);
                  }),
                  const Divider(),
                  if (singleSelection)
                    _buildOptionTile(context, Icons.edit, "Renommer l'album", () async {
                      Navigator.pop(context);
                      await albumDialogs.renameAlbum(context, singleAlbum!);
                      onAlbumRenamed();
                    }),
                  _buildOptionTile(
                    context,
                    Icons.delete,
                    singleSelection ? "Supprimer l'album" : "Supprimer les albums sélectionnés",
                        () async {
                      Navigator.pop(context);
                      await albumDialogs.confirmDeleteSelectedAlbums(context, selectionNotifier, refreshUI);
                      onAlbumsDeleted();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showSingleAlbumOptions(
      BuildContext context,
      WidgetRef ref, Album album,
   VoidCallback onManageMode, {
   required VoidCallback refreshUI,
   required VoidCallback onManageAlbums,
   required VoidCallback onAlbumsDeleted,
   required VoidCallback onAlbumRenamed}      ) {
    final theme = Theme.of(context);
    final albumDialogs = AlbumDialogs();
    final albumUtils = AlbumUtils();
    final contactService = ref.watch(contactServiceProvider);
    final firebaseUser = ref.watch(firebaseUserProvider).asData?.value;
    final userId = firebaseUser?.uid;

    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                children: [
                  _buildDragHandle(theme),
                  _buildOptionTile(context, Icons.share, "Partager l'album", () async {
                    Navigator.pop(context);
                    await _handleShareSingle(context, ref, album, userId, albumUtils, albumDialogs, contactService);
                  }),
                  _buildOptionTile(context, Icons.edit, "Renommer l'album", () async {
                    Navigator.pop(context);
                    await albumDialogs.renameAlbum(context, album);
                    onAlbumRenamed();
                  }),
                  _buildOptionTile(context, Icons.delete, "Supprimer l'album", () async {
                    Navigator.pop(context);
                    await albumDialogs.confirmDeleteAlbum(context, album, refreshUI);
                    onAlbumsDeleted();
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  ListTile _buildOptionTile(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      onTap: onTap,
    );
  }

  Future<void> _handleShare(
      BuildContext context,
      WidgetRef ref,
      List<Album> selectedAlbums,
      String userId,
      AlbumUtils albumUtils,
      AlbumDialogs albumDialogs,
      ContactService contactService,
      ) async {
    if (selectedAlbums.isEmpty) {
      albumUtils.showSnackBar(context, "Aucun album sélectionné.");
      return;
    }

    final Album albumToShare = selectedAlbums.length == 1
        ? selectedAlbums.first
        : (await albumDialogs.showAlbumPickerDialog(context, selectedAlbums)) ?? selectedAlbums.first;

    final friendUid = await albumDialogs.showShareDialog(context);
    if (friendUid != null && friendUid.isNotEmpty) {
      await contactService.shareAlbumWithUser(albumToShare.id, userId, friendUid);
      albumUtils.showSnackBar(context, "Album partagé avec succès.");
    }
  }

  Future<void> _handleShareSingle(
      BuildContext context,
      WidgetRef ref,
      Album album,
      String userId,
      AlbumUtils albumUtils,
      AlbumDialogs albumDialogs,
      ContactService contactService,
      ) async {
    final friendUid = await albumDialogs.showShareDialog(context);
    if (friendUid != null && friendUid.isNotEmpty) {
      await contactService.shareAlbumWithUser(album.id, userId, friendUid);
      albumUtils.showSnackBar(context, "Album partagé avec succès.");
    }
  }
}
