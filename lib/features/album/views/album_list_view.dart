import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_provider.dart';
import '../models/album.dart';
import '../models/album_list_view_model.dart';
import '../services/album_options_menu.dart';
import '../widget/album/album_management_bar.dart';
import '../widget/grid/album_grid.dart';

class AlbumListView extends ConsumerStatefulWidget {
  const AlbumListView({super.key});

  @override
  ConsumerState<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends ConsumerState<AlbumListView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(albumListViewModelProvider).init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(albumListViewModelProvider);

    if (vm.isLoading || vm.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: vm.isManaging
          ? AlbumManagementBar(
        albumDialog: vm.albumDialogs,
        onExitManaging: vm.exitManaging,
        onSelectionCleared: vm.clearSelection,
        onUpdate: vm.refresh,
        selectedAlbums: vm.albumSelectionNotifier.selectedItems,
        albumSelectionNotifier: vm.albumSelectionNotifier,
      )
          : AppBar(
        title: const Text("Albums"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes albums'),
            Tab(text: 'Albums partagés'),
          ],
        ),
      ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAlbumStream(vm.myAlbumsStream, "Pas encore d'albums souvenirs, rajoutez-en !", vm),
            _buildAlbumStream(vm.sharedAlbumsStream, "Pas encore d'albums partagés avec vous", vm),
          ],
        ),
        floatingActionButton: vm.isManaging
            ? null
            :
        FloatingActionButton(
          onPressed: () async {
            final albumOptionsMenu = AlbumOptionsMenu();
            await albumOptionsMenu.showOptions(
              context,
              ref,
              vm.albumSelectionNotifier.selectedItems.toList(),
              vm.OnManageMode,
              onManageAlbums: vm.enterManaging,
              onAlbumsDeleted: vm.exitManaging,
              onAlbumRenamed: vm.refresh,
              refreshUI: vm.refresh,
            );
          },
          child: const Icon(Icons.add),
        ),
    );
  }

  Widget _buildAlbumStream(Stream<List<Album>> stream, String emptyMessage, AlbumListViewModel vm) {
    return StreamBuilder<List<Album>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Pas encore de souvenirs partagés avec vous'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "Pas encore d'albums souvenirs, rajoutez en !",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        }
        return AlbumGrid(
          albums: snapshot.data!,
          isManaging: vm.isManaging,
        );
      },
    );
  }
}
