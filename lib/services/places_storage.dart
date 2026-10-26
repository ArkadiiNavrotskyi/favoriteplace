import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/place.dart';

class PlacesStorage {
  static const _fileName = 'favorite_places.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<Place>> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      return Place.decodeList(content);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Place> places) async {
    final file = await _getFile();
    await file.writeAsString(Place.encodeList(places));
  }

  /// Copies a picked image into the app's documents dir so it survives restarts.
  Future<String> persistImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
    final target = p.join(imagesDir.path, fileName);
    await File(sourcePath).copy(target);
    return target;
  }
}