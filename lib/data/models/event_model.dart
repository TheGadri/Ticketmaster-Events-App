import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 0)
class EventModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String time;

  @HiveField(4)
  final String venue;

  @HiveField(5)
  final String imageUrl;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final String ticketUrl;

  const EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.venue,
    required this.imageUrl,
    required this.description,
    required this.ticketUrl,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final dates = json['dates']['start'];
    final venue = json['_embedded'] == null
        ? json['place']['address']['line1']
        : json['_embedded']['venues'][0]['name'] ?? 'Unknown Venue';

    return EventModel(
      id: json['id'],
      name: json['name'],
      date: dates['localDate'] ?? 'TBA',
      time: dates['localTime'] ?? 'TBA',
      venue: venue,
      imageUrl: json['images'][0]['url'] ?? '',
      description:
          json['info'] ?? json['description'] ?? 'No description available',
      ticketUrl: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'time': time,
      'venue': venue,
      'imageUrl': imageUrl,
      'description': description,
      'ticketUrl': ticketUrl,
    };
  }
}
