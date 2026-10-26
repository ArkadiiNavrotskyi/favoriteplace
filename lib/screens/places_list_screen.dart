import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/places_provider.dart';
import 'add_place_screen.dart';
import 'place_detail_screen.dart';

class PlacesListScreen extends StatelessWidget {
  const PlacesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlacesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddScreen(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.places.isEmpty
          ? const _EmptyState()
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.places.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = provider.places[index];
          return _PlaceTile(place: place);
        },
      ),
    );
  }

  Future<void> _openAddScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${result.title}"')),
      );
    }
  }
}

class _PlaceTile extends StatelessWidget {
  final Place place;
  const _PlaceTile({required this.place});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _thumbnail(),
      title: Text(place.title),
      subtitle: Text(
        place.address ?? '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
        );
      },
    );
  }

  Widget _thumbnail() {
    if (place.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(place.imagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.place, color: Colors.white70),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 72, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No places yet.\nTap + to add your first place.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}