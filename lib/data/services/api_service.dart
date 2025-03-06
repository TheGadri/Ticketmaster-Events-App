import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../models/event_model.dart';
import '../../core/config.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<List<EventModel>> fetchEvents({
    String keyword = '',
    int page = 0,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConfig.ticketmasterApiBaseUrl}/events',
        queryParameters: {
          'apikey': AppConfig.apiKey,
          'keyword': keyword,
          'page': page,
          'size': AppConstants.eventsPerPage,
        },
      );

      // Parse response and convert to EventModel list
      return (response.data['_embedded']['events'] as List)
          .map((eventJson) => EventModel.fromJson(eventJson))
          .toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }
}
