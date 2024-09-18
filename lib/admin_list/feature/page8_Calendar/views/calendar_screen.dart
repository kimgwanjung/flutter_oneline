import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/view_models/calendar_bloc.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/models/event_model.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/view_models/calendar_event.dart'; // EventBloc으로 변경
import 'package:oneline2/admin_list/feature/page8_Calendar/view_models/calendar_state.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/views/add_event_page.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/views/edit_event_page.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<DateTime> _eventDays = {}; // 이벤트가 있는 날짜를 저장할 Set

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Load all events initially
    context.read<EventBloc>().add(LoadEvents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: EventSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              context.read<EventBloc>().add(LoadEventsForDay(selectedDay));
            },
            onFormatChanged: (format) {
              setState(() {
                calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, _) {
                final eventBlocState = context.watch<EventBloc>().state;

                if (eventBlocState is EventLoadSuccess) {
                  final dayEvents = eventBlocState.events.where((event) {
                    final startDate = event.startTime;
                    final endDate = event.endTime.isBefore(startDate)
                        ? startDate
                        : event.endTime;
                    return day.isAfter(startDate.subtract(Duration(days: 1))) &&
                        day.isBefore(endDate);
                  }).toList();

                  if (dayEvents.isNotEmpty) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                }

                return null;
              },
            ),
            eventLoader: (day) {
              final state = context.watch<EventBloc>().state;
              if (state is EventLoadSuccess) {
                return state.events.where((event) {
                  final startDate = event.startTime;
                  final endDate = event.endTime.isBefore(startDate)
                      ? startDate
                      : event.endTime;
                  return day.isAfter(startDate.subtract(Duration(days: 1))) &&
                      day.isBefore(endDate);
                }).toList();
              }
              return [];
            },
          ),
          const SizedBox(height: 8.0),
          BlocBuilder<EventBloc, EventState>(
            builder: (context, state) {
              if (state is EventLoadSuccess) {
                final events = state.events
                    .where((event) =>
                        event.startTime
                            .isBefore(_selectedDay.add(Duration(days: 1))) &&
                        event.endTime
                            .isAfter(_selectedDay.subtract(Duration(days: 1))))
                    .where((event) =>
                        _searchQuery.isEmpty ||
                        event.title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();
                print(
                    'Selected Day: $_selectedDay, Events for the day: $events');
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(_selectedDay);
                return Container(
                  color: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Day: $formattedDate',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16.0),
                      ),
                      Text(
                        'Tasks: ${events.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16.0),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: BlocBuilder<EventBloc, EventState>(
              builder: (context, state) {
                if (state is EventLoadSuccess) {
                  final events = state.events
                      .where((event) =>
                          event.startTime
                              .isBefore(_selectedDay.add(Duration(days: 1))) &&
                          event.endTime.isAfter(
                              _selectedDay.subtract(Duration(days: 1))))
                      .where((event) =>
                          _searchQuery.isEmpty ||
                          event.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 5,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context
                                    .read<EventBloc>()
                                    .add(RemoveEvent(event));
                              },
                            ),
                            onTap: () async {
                              final updatedEvent = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditEventPage(event: event),
                                ),
                              );

                              if (updatedEvent != null) {
                                context
                                    .read<EventBloc>()
                                    .add(UpdateEvent(updatedEvent));
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EventSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final eventBloc = context.read<EventBloc>();
    final state = eventBloc.state;
    List<Event> results = [];

    if (state is EventLoadSuccess) {
      results = state.events.where((event) {
        return event.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final event = results[index];
        return ListTile(
          title: Text(event.title),
          subtitle: Text(
            '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditEventPage(event: event),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final eventBloc = context.read<EventBloc>();
    final state = eventBloc.state;
    List<Event> suggestions = [];

    if (state is EventLoadSuccess) {
      suggestions = state.events.where((event) {
        return event.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final event = suggestions[index];
        return ListTile(
          title: Text(event.title),
          onTap: () {
            close(context, event.title);
          },
        );
      },
    );
  }
}
