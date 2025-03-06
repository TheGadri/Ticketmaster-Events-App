import 'package:hive/hive.dart';
import '../models/event_model.dart';

class LocalStorageService {
  static const String _boxNamePrefix = 'events_cache';

  // Helper method to get box name based on query
  String _getBoxName(String keyword) {
    return keyword.isEmpty
        ? _boxNamePrefix
        : '${_boxNamePrefix}_${keyword.toLowerCase().replaceAll(' ', '_')}';
  }

  Future<void> cacheEvents(List<EventModel> events,
      {String keyword = ''}) async {
    final boxName = _getBoxName(keyword);
    final box = await Hive.openBox<EventModel>(boxName);
    await box.clear(); // Clear previous cache for this query
    await box.addAll(events);
    await box.close();
  }

  Future<void> appendToCachedEvents(List<EventModel> events,
      {String keyword = ''}) async {
    final boxName = _getBoxName(keyword);
    final box = await Hive.openBox<EventModel>(boxName);

    // Add only events that don't already exist in the box
    final existingIds = box.values.map((event) => event.id).toSet();
    final newEvents =
        events.where((event) => !existingIds.contains(event.id)).toList();

    await box.addAll(newEvents);
    await box.close();
  }

  Future<List<EventModel>> getCachedEvents({String keyword = ''}) async {
    final boxName = _getBoxName(keyword);

    // Check if box exists
    if (!Hive.isBoxOpen(boxName) && !await Hive.boxExists(boxName)) {
      // If no cached data exists for this query, try to return the general cache
      if (keyword.isNotEmpty && await Hive.boxExists(_boxNamePrefix)) {
        final generalBox = await Hive.openBox<EventModel>(_boxNamePrefix);
        final events = generalBox.values.toList();
        await generalBox.close();
        return events;
      }
      return []; // No cached data available
    }

    final box = await Hive.openBox<EventModel>(boxName);
    final events = box.values.where((event) => event.name == keyword).toList();
    await box.close();
    return events;
  }

  Future<void> clearCache() async {
    Hive.deleteFromDisk();
  }
}
