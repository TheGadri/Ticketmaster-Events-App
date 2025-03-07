import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/event_model.dart';

class LocalStorageService {
  static const String _eventsCacheboxName = 'events_cache';

  Future<void> cacheEvents(List<EventModel> events,
      {String keyword = ''}) async {
    final box = await Hive.openBox<EventModel>(_eventsCacheboxName);
    await box.addAll(events);
    await box.close();
  }

  Future<void> appendToCachedEvents(List<EventModel> events,
      {String keyword = ''}) async {
    final box = await Hive.openBox<EventModel>(_eventsCacheboxName);

    // Add only events that don't already exist in the box
    final existingIds = box.values.map((event) => event.id).toSet();
    final newEvents =
        events.where((event) => !existingIds.contains(event.id)).toList();

    await box.addAll(newEvents);
    await box.close();
  }

  Future<List<EventModel>> getCachedEvents({String keyword = ''}) async {
    final box = await Hive.openBox<EventModel>(_eventsCacheboxName);
    try {
      if (box.isEmpty) {
        return []; // No cached data available
      }

      if (keyword.isEmpty) {
        return box.values.toList();
      }

      // Filter events by keyword (case-insensitive)
      final keywordLower = keyword.toLowerCase();
      return box.values
          .where((event) => event.name.toLowerCase().contains(keywordLower))
          .toList();
    } catch (e) {
      // Handle any errors that occur during the process
      debugPrint('Error fetching cached events: $e');
      return [];
    } finally {
      // Ensure the box is always closed
      await box.close();
    }
  }

  Future<void> clearCache() async {
    Hive.deleteFromDisk();
  }
}
