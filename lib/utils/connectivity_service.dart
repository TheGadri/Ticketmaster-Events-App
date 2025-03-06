import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
class ConnectivityService {
  // Instance of Connectivity package
  final Connectivity _connectivity = Connectivity();

  // Stream controller to broadcast connectivity changes
  final _connectivityStreamController = StreamController<bool>.broadcast();

  // Public stream that UI components can listen to
  Stream<bool> get onConnectivityChanged =>
      _connectivityStreamController.stream;

  ConnectivityService() {
    // Initialize the connectivity listener
    _initConnectivityListener();
  }

  // Check current connectivity status
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Initialize the connectivity stream
  void _initConnectivityListener() {
    // Listen to connectivity changes from the package
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      // Convert connectivity result to a boolean and add to our stream
      final isConnected = result != ConnectivityResult.none;
      _connectivityStreamController.add(isConnected);
    });

    // Initial check to broadcast current state
    isConnected.then((connected) {
      _connectivityStreamController.add(connected);
    });
  }

  // Clean up resources
  void dispose() {
    _connectivityStreamController.close();
  }
}



/*import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> get isConnected async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}*/