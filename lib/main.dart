import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/places_provider.dart';
import 'screens/places_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlacesProvider()..loadPlaces(),
      child: const FavoritePlacesApp(),
    ),
  );
}

class FavoritePlacesApp extends StatelessWidget {
  const FavoritePlacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Favorite Places',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const PlacesListScreen(),
    );
  }
}