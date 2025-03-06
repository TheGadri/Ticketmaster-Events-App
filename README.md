# savannah_tech_ticketmaster_example

# Ticketmaster Events App

## Setup Instructions
1. Clone the repository
2. Run `flutter pub get`
3. Replace `AppConfig.apiKey` in `lib/core/config.dart` with your Ticketmaster API key
4. Run the app with `flutter run`

## Architectural Overview
- Model-View-ViewModel architectural pattern (MVVM) to ensure separation of concerns, scalability, maintainability, and testability.
- Repository pattern for data management
- Offline support with local caching
- Dependency injection (Provider) for services 


## Key Dependencies
- dio: API requests
- hive: Local storage
- connectivity_plus: Network connectivity
