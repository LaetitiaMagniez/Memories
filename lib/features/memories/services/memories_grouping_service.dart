import 'package:memories_project/features/memories/models/memory.dart';
import 'package:intl/intl.dart';

class MemoriesGroupingService {
  Map<String, List<Memory>> groupMemoriesByCity(List<Memory> memories) {
    final Map<String, List<Memory>> memoriesByCity = {};
    for (final memory in memories) {
      if (memory.ville != null && memory.ville!.isNotEmpty) {
        memoriesByCity.putIfAbsent(memory.ville!, () => []).add(memory);
      }
    }
    return memoriesByCity;
  }

  List<Memory> getEventsForDay(DateTime day, Map<String, List<Memory>> memories) {
    final formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(day);
    return memories[formattedDate] ?? [];
  }
}
