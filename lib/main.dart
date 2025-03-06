import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:savannah_tech_ticketmaster_example/data/models/event_model.dart';
import 'package:savannah_tech_ticketmaster_example/ui/events/view_model/events_view_model.dart';

import 'data/services/api_service.dart';
import 'data/services/local_storage_service.dart';
import 'ui/events/screens/events_list_screen.dart';
import 'utils/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(EventModelAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<LocalStorageService>(
          create: (_) => LocalStorageService(),
        ),
        Provider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
        ProxyProvider3<ApiService, LocalStorageService, ConnectivityService,
            EventsViewModel>(
          update:
              (_, apiService, localStorageService, connectivityService, __) =>
                  EventsViewModel(
            apiService: apiService,
            localStorageService: localStorageService,
            connectivityService: connectivityService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Ticketmaster Events',
        themeMode: ThemeMode.system,
        home: const EventListScreen(),
      ),
    );
  }
}
