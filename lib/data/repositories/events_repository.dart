import '../models/event_model.dart';

abstract class EventsRepository {
  /// Get activities by [Destination] ref.
  Future<List<EventModel>> getEvents({
    String keyword = '',
    int page = 0,
    bool forceRefresh = false,
  });
}
