import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/events_state.dart';
import '../view_model/events_view_model.dart';
import '../widgets/event_list_item.dart';
import '../widgets/offline_banner.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer; // Timer for debouncing

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Fetch initial events
    Provider.of<EventsViewModel>(context, listen: false).fetchEvents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Cancel the timer
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      Provider.of<EventsViewModel>(context, listen: false).loadMoreEvents();
    }
  }

  void _searchEvents(String query) {
    // Cancel the previous timer if it's still active
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    // Start a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Perform the search after the debounce delay
      Provider.of<EventsViewModel>(context, listen: false)
          .fetchEvents(query: query, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticketmaster Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<EventsViewModel>(context, listen: false)
                    .fetchEvents(refresh: true),
          ),
        ],
      ),
      body: StreamBuilder<EventsState>(
        stream: Provider.of<EventsViewModel>(context).stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          return Column(
            children: [
              if (state.isOffline) const OfflineBanner(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchEvents('');
                      },
                    ),
                  ),
                  onSubmitted: _searchEvents,
                  onChanged: _searchEvents,
                ),
              ),
              Expanded(
                child: state.events.isEmpty && !state.isLoading
                    ? const Center(child: Text('No events found'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          await Provider.of<EventsViewModel>(context,
                                  listen: false)
                              .fetchEvents(refresh: true);
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              state.events.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.events.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final event = state.events[index];
                            return EventListItem(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventDetailScreen(event: event),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
