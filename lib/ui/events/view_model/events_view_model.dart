import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../utils/connectivity_service.dart';

import 'dart:async';

import 'events_state.dart';

class EventsViewModel implements EventsRepository {
  final ApiService _apiService;
  final LocalStorageService _localStorageService;
  final ConnectivityService _connectivityService;

  // Track already loaded event IDs for each search query to prevent duplicates
  final Map<String, Set<String>> _loadedEventIds = {};

  // State variables
  bool _isLoading = false;
  bool _isOffline = false;
  int _currentPage = 0;
  String _searchQuery = '';
  final List<EventModel> _events = [];
  late StreamSubscription<bool> _connectivitySubscription;

  // Stream controller for state updates
  final _stateController = StreamController<EventsState>.broadcast();
  Stream<EventsState> get stateStream => _stateController.stream;

  EventsViewModel({
    required ApiService apiService,
    required LocalStorageService localStorageService,
    required ConnectivityService connectivityService,
  })  : _apiService = apiService,
        _localStorageService = localStorageService,
        _connectivityService = connectivityService {
    _setupConnectivityListener();
  }

  // Initialize connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isConnected) {
      _isOffline = !isConnected;
      _emitCurrentState();
    });
  }

  // Emit the current state to listeners
  void _emitCurrentState() {
    _stateController.add(EventsState(
      events: List.from(_events),
      isLoading: _isLoading,
      isOffline: _isOffline,
      currentPage: _currentPage,
      currentQuery: _searchQuery,
    ));
  }

  // Fetch events from API or cache
  Future<void> fetchEvents({String query = '', bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _events.clear();
        _currentPage = 0;
        _searchQuery = query;
      }
    });

    try {
      final newEvents = await getEvents(
        keyword: _searchQuery,
        page: _currentPage,
        forceRefresh: refresh,
      );

      _events.addAll(newEvents);
      _isLoading = false;
    } catch (e) {
      _isLoading = false;

      // Fallback to cached data
      final cachedEvents =
          await _localStorageService.getCachedEvents(keyword: _searchQuery);
      _events.addAll(cachedEvents);
    }

    _emitCurrentState();
  }

  // Helper method to generate a cache key based on search parameters
  String _getCacheKey(String keyword) {
    return keyword.isEmpty ? 'all_events' : 'search_$keyword';
  }

  // Helper method to filter out duplicate events
  List<EventModel> _filterDuplicates(List<EventModel> events, String cacheKey) {
    // Initialize tracking set if it doesn't exist for this query
    _loadedEventIds[cacheKey] ??= {};

    final uniqueEvents = events.where((event) {
      final isUnique = !_loadedEventIds[cacheKey]!.contains(event.id);
      if (isUnique) {
        _loadedEventIds[cacheKey]!.add(event.id);
      }
      return isUnique;
    }).toList();

    return uniqueEvents;
  }

  // Clear loaded IDs when refreshing data
  void _resetTracking(String cacheKey) {
    _loadedEventIds[cacheKey] = {};
  }

  @override
  Future<List<EventModel>> getEvents({
    String keyword = '',
    int page = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(keyword);

    // Reset tracking when forcing a refresh or when on page 0
    if (forceRefresh || page == 0) {
      _resetTracking(cacheKey);
    }

    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final events = await _apiService.fetchEvents(
          keyword: keyword,
          page: page,
        );

        // Filter out duplicates before caching or returning
        final uniqueEvents = _filterDuplicates(events, cacheKey);

        // Only update cache on first page or refresh
        if (page == 0 || forceRefresh) {
          await _localStorageService.cacheEvents(events, keyword: keyword);
        } else if (uniqueEvents.isNotEmpty) {
          // For subsequent pages, append to cache
          await _localStorageService.appendToCachedEvents(uniqueEvents,
              keyword: keyword);
        }

        return uniqueEvents;
      } catch (e) {
        // On error, fall back to cached data
        final cachedEvents =
            await _localStorageService.getCachedEvents(keyword: keyword);
        return _filterDuplicates(cachedEvents, cacheKey);
      }
    } else {
      // When offline, get cached events and filter duplicates
      final cachedEvents =
          await _localStorageService.getCachedEvents(keyword: keyword);
      return _filterDuplicates(cachedEvents, cacheKey);
    }
  }

  // Method to clear all cached data when needed
  Future<void> clearCache() async {
    await _localStorageService.clearCache();
    _loadedEventIds.clear();
    _events.clear();
    _currentPage = 0;
    _searchQuery = '';
    _emitCurrentState();
  }

  // Load more events for pagination
  Future<void> loadMoreEvents() async {
    if (_isLoading) return;

    _currentPage++;
    await fetchEvents(query: _searchQuery);
  }

  // Update internal state
  void setState(void Function() fn) {
    fn();
    _emitCurrentState();
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _stateController.close();
  }
}
