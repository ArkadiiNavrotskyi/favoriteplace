import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/osm_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final _osm = OsmService();

  LatLng _center = const LatLng(37.4219999, -122.0840575); // Mountain View
  LatLng? _selected;
  List<GeocodeResult> _results = [];
  bool _searching = false;

  void _onTap(LatLng point) {
    setState(() => _selected = point);
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _searching = true);
    final results = await _osm.search(_searchCtrl.text.trim());
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _selectResult(GeocodeResult r) {
    final point = LatLng(r.latitude, r.longitude);
    setState(() {
      _selected = point;
      _results = [];
      _searchCtrl.text = r.displayName;
    });
    _mapCtrl.move(point, 15);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (_, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.favorite_places',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          hintText: 'Search a place…',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _searching
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.search),
                      onPressed: _search,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search results
          if (_results.isNotEmpty)
            Positioned(
              top: 72,
              left: 12,
              right: 12,
              child: Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        r.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectResult(r),
                    );
                  },
                ),
              ),
            ),

          // Hint
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _selected == null
                      ? 'Tap on the map to place the marker.'
                      : 'Selected: '
                      '${_selected!.latitude.toStringAsFixed(5)}, '
                      '${_selected!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}