import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/places_provider.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(place.latitude, place.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(place.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (place.hasImage)
            Image.file(
              File(place.imagePath!),
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(
              height: 180,
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.photo, size: 64, color: Colors.white54),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (place.address != null)
                  Text(
                    place.address!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                Text(
                  '${place.latitude.toStringAsFixed(6)}, '
                      '${place.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Map
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.favorite_places',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text('Remove "${place.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<PlacesProvider>().deletePlace(place.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}