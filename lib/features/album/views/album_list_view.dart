import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../album/models/album_list_view_model.dart';
import '../widget/album/album_management_bar.dart';
import '../widget/album/grid/album_grid.dart';

class AlbumListView extends StatefulWidget {
  const AlbumListView({super.key});

  @override
  State<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends State<AlbumListView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Init ViewModel after widgets are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<AlbumListViewModel>(context, listen: false);
      vm.init(); // sans tabController, on a retiré cela du VM
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AlbumListViewModel>(context);

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = vm.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }

    return Scaffold(
      appBar: vm.isManaging
          ? AlbumManagementBar(
        albumService: vm.albumService,
        onExitManaging: vm.exitManaging,
        onSelectionCleared: vm.clearSelection,
        onUpdate: vm.refresh,
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
          StreamBuilder(
            stream: vm.myAlbumsStream,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(child: Text("Pas encore d'albums souvenirs, rajoutez en !"));
              }
              return AlbumGrid(
                albums: snapshot.data!,
                isManaging: vm.isManaging,
                albumService: vm.albumService,
                onSelectionChanged: vm.refresh,
              );
            },
          ),
          StreamBuilder(
            stream: vm.sharedAlbumsStream,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(child: Text("Pas encore d'albums partagés avec vous"));
              }
              return AlbumGrid(
                albums: snapshot.data!,
                isManaging: vm.isManaging,
                albumService: vm.albumService,
                onSelectionChanged: vm.refresh,
              );
            },
          ),
        ],
      ),
      floatingActionButton: vm.isManaging
          ? null
          : FloatingActionButton(
        onPressed: () => vm.onAddAlbum(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
