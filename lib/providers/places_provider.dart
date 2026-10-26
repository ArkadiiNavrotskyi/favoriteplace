import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../services/places_storage.dart';

class PlacesProvider extends ChangeNotifier {
  final PlacesStorage _storage = PlacesStorage();
  final List<Place> _places = [];
  bool _isLoading = true;

  List<Place> get places => List.unmodifiable(_places);
  bool get isLoading => _isLoading;

  Future<void> loadPlaces() async {
    _isLoading = true;
    notifyListeners();
    final loaded = await _storage.load();
    _places
      ..clear()
      ..addAll(loaded);
    _isLoading = false;
    notifyListeners();
  }

  Future<Place> addPlace({
    required String title,
    String? imagePath,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    String? savedImage = imagePath;
    if (imagePath != null) {
      savedImage = await _storage.persistImage(imagePath);
    }
    final place = Place(
      id: const Uuid().v4(),
      title: title,
      imagePath: savedImage,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    _places.add(place);
    await _storage.save(_places);
    notifyListeners();
    return place;
  }

  Future<void> deletePlace(String id) async {
    _places.removeWhere((p) => p.id == id);
    await _storage.save(_places);
    notifyListeners();
  }
}