import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/features/memories/logic/memories_service.dart';
import 'package:memories_project/features/memories/widget/full_screen_image_view.dart';
import 'package:memories_project/features/memories/widget/video_thumbnail_widget.dart';
import 'package:memories_project/features/memories/widget/video_viewer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';



class CalendarPage extends StatefulWidget {
  CalendarPage({super.key});


  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<String, List<Memory>> memories = {};
  late final ValueNotifier<List<Memory>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadMemories();
  }

  void _loadMemories() {
    final MemoriesService memoriesService = MemoriesService();
    memoriesService.getAllMemoriesForUser().listen((newMemories) {
      setState(() {
        memories = _groupMemoriesByDate(newMemories);
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    });
  }

  Map<String, List<Memory>> _groupMemoriesByDate(List<Memory> allMemories) {
    Map<String, List<Memory>> grouped = {};
    for (var memory in allMemories) {
      String formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(memory.date);
      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(memory);
    }
    return grouped;
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Memory> _getEventsForDay(DateTime day) {
    String formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(day);
    return memories[formattedDate] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar<Memory>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: const Color.fromARGB(255, 138, 87, 220),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color.fromARGB(255, 138, 87, 220).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color.fromARGB(255, 138, 87, 220),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            locale: 'fr_FR',
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mois',
              CalendarFormat.twoWeeks: '2 semaines',
              CalendarFormat.week: 'Semaine',
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Memory>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => _showSouvenirDetails(value[index]),
                        title: Text('Souvenir à ${value[index].ville}'),
                        leading: value[index].type == 'image'
                          ? Image.network(value[index].url, width: 50, height: 50, fit: BoxFit.cover)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: VideoThumbnailWidget(value[index].url),
                              ),
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSouvenirDetails(Memory memory) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: memory.type == 'video' ? 400 : 300, // Plus large pour les vidéos
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Ferme le dialogue actuel
                    if (memory.type == 'image') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageView(url: memory.url),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoViewer(memory.url),
                        ),
                      );
                    }
                  },
                  child: memory.type == 'image'
                    ? Image.network(memory.url)
                    : AspectRatio(
                        aspectRatio: 16 / 9, // Ratio d'aspect pour les vidéos
                        child: SizedBox(
                          height: 250, // Hauteur plus grande pour les vidéos
                          child: VideoThumbnailWidget(memory.url),
                        ),
                      ),
                ),
                SizedBox(height: 16),
                Text('Ville: ${memory.ville}'),
                Text('Date: ${DateFormat('d MMMM yyyy', 'fr_FR').format(memory.date)}'),
                SizedBox(height: 16),
                TextButton(
                  child: Text('Fermer'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
