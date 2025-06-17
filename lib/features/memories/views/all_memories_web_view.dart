import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memories_project/core/utils/date_picker.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/features/memories/services/memories_crud_service.dart';
import 'package:memories_project/features/memories/services/memories_options_menu.dart';
import '../../../core/notifiers/selected_items_notifier.dart';
import '../../../core/utils/cached_image.dart';
import '../widget/memory/full_screen_image_view.dart';
import '../widget/video/video_viewer.dart';

class AllMemoriesWebView extends StatefulWidget {
  const AllMemoriesWebView({super.key});

  @override
  State<AllMemoriesWebView> createState() => _AllMemoriesWebViewState();
}

class _AllMemoriesWebViewState extends State<AllMemoriesWebView> {
  final SelectedItemsNotifier<Memory> selectionNotifier = SelectedItemsNotifier<Memory>();

  late final MemoriesCrudService memoriesCrudService = MemoriesCrudService(
    memoriesSelectionNotifier: selectionNotifier,
  );

  final MemoriesOptionsMenu memoriesOptionsMenu = MemoriesOptionsMenu();
  final DatePicker datePicker = DatePicker();

  final ScrollController _scrollController = ScrollController();

  List<Memory> _memories = [];
  bool _isLoading = false;
  bool _hasMore = true;

  String? _selectedVille;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadInitialMemories();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchNextMemoriesPage();
      }
    });
  }

  Future<void> _loadInitialMemories() async {
    setState(() {
      _isLoading = true;
      _memories = [];
      _hasMore = true;
    });
    memoriesCrudService.resetPagination();

    try {
      final memories =
      await memoriesCrudService.fetchNextMemoriesPage(albumLimit: 20);
      setState(() {
        _memories = memories;
        _isLoading = false;
        _hasMore = memories.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _fetchNextMemoriesPage() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newMemories =
      await memoriesCrudService.fetchNextMemoriesPage(albumLimit: 20);
      setState(() {
        _memories.addAll(newMemories);
        _isLoading = false;
        _hasMore = newMemories.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $message')),
    );
  }

  Map<String, List<Memory>> _groupMemories(List<Memory> memories) {
    Map<String, List<Memory>> grouped = {};

    for (final memory in memories) {
      final ville = memory.ville ?? 'Inconnue';
      final dateKey = DateFormat('yyyy-MM').format(memory.date);
      final groupKey = '$ville - $dateKey';

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(memory);
    }

    return grouped;
  }

  List<Memory> _applyFilters() {
    return _memories.where((memory) {
      final matchesVille = _selectedVille == null ||
          (memory.ville != null &&
              memory.ville!.toLowerCase() == _selectedVille!.toLowerCase());

      final matchesDate = _selectedDate == null ||
          (memory.date.year == _selectedDate!.year &&
              memory.date.month == _selectedDate!.month);

      return matchesVille && matchesDate;
    }).toList();
  }

  void _onMemoryTap(Memory memory) {
    if (memory.type == 'image') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImageView(url: memory.url),
        ),
      );
    } else if (memory.type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoViewer(memory.url),
        ),
      );
    }
  }

  Future<void> _openDatePicker() async {
    final picked =
    await datePicker.selectDate(context, initialDate: _selectedDate);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMemories = _applyFilters();
    final groupedMemories = _groupMemories(filteredMemories);
    final groupKeys = groupedMemories.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.photo_album), label: Text("Tous")),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _isLoading && _memories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadInitialMemories,
              child: filteredMemories.isEmpty
                  ? Center(
                child: Text(
                  'Aucun souvenir trouvé pour la date sélectionnée.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: groupKeys.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == groupKeys.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final groupKey = groupKeys[index];
                  final memoriesInGroup = groupedMemories[groupKey]!;

                  final parts = groupKey.split(' - ');
                  final ville = parts[0];
                  final yearMonth = parts[1];
                  final year = int.parse(yearMonth.split('-')[0]);
                  final month = int.parse(yearMonth.split('-')[1]);
                  final monthName = DateFormat.MMMM('fr').format(DateTime(year, month));

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$ville — $monthName $year',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: memoriesInGroup.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, idx) {
                            final memory = memoriesInGroup[idx];
                            return GestureDetector(
                              onTap: () => _onMemoryTap(memory),
                              onLongPress: () {
                                memoriesOptionsMenu.showOptionsForMemory(
                                  context: context,
                                  memory: memory,
                                  currentAlbumId: 'all_memories',
                                  deleteMemory: memoriesCrudService.deleteMemory,
                                  refreshUI: _loadInitialMemories,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedImage(
                                      url: memory.url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                    ),
                                    if (memory.type == 'video')
                                      const Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Icon(
                                          Icons.videocam,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _selectedVille,
            hint: const Text("Filtrer par ville"),
            items: _memories
                .map((m) => m.ville ?? 'Inconnue')
                .toSet()
                .map((ville) => DropdownMenuItem(
              value: ville,
              child: Text(ville),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedVille = value;
              });
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _openDatePicker,
            icon: const Icon(Icons.date_range),
            label: Text(_selectedDate != null
                ? DateFormat.yMMMM().format(_selectedDate!)
                : 'Filtrer par date'),
          ),
          if (_selectedVille != null || _selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedVille = null;
                  _selectedDate = null;
                });
              },
            ),
        ],
      ),
    );
  }
}
