// State class to represent the current state of events fetching
import '../../../data/models/event_model.dart';

class EventsState {
  final List<EventModel> events;
  final bool isLoading;
  final bool isOffline;
  final int currentPage;
  final String currentQuery;

  EventsState({
    required this.events,
    required this.isLoading,
    required this.isOffline,
    required this.currentPage,
    required this.currentQuery,
  });
}
