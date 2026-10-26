import 'dart:convert';
import 'dart:io';

class Place {
  final String id;
  final String title;
  final String? imagePath; // local file path
  final double latitude;
  final double longitude;
  final String? address; // human-readable (optional)

  Place({
    required this.id,
    required this.title,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imagePath': imagePath,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    title: json['title'] as String,
    imagePath: json['imagePath'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String?,
  );

  static String encodeList(List<Place> places) =>
      jsonEncode(places.map((p) => p.toJson()).toList());

  static List<Place> decodeList(String source) {
    final List<dynamic> data = jsonDecode(source) as List<dynamic>;
    return data.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  bool get hasImage => imagePath != null && File(imagePath!).existsSync();
}