import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/places_provider.dart';
import '../services/osm_service.dart';
import 'location_picker_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  File? _image;
  LatLng? _location;
  bool _isLocating = false;
  bool _isSaving = false;

  final _osm = OsmService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final picked = await _picker.pickImage(
      source: choice,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await _osm.getCurrentPosition();
      final addr = await _osm.reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _location = LatLng(pos.latitude, pos.longitude);
        if (addr != null) _addressCtrl.text = addr;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location acquired')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result == null) return;
    final addr = await _osm.reverseGeocode(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _location = result;
      if (addr != null) _addressCtrl.text = addr;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a location first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Сохраняем место и получаем созданный объект Place
      final savedPlace = await context.read<PlacesProvider>().addPlace(
        title: _titleCtrl.text.trim(),
        imagePath: _image?.path,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
      );
      // Возвращаем этот объект обратно (исправляет ошибку с типами)
      if (mounted) Navigator.of(context).pop(savedPlace);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Place')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, size: 42),
                        SizedBox(height: 8),
                        Text('Tap to add photo'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. My Office',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.my_location),
                    label: const Text('Current'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLocationOnMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Pick on map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _location == null
                  ? 'Location: not set'
                  : 'Location: ${_location!.latitude.toStringAsFixed(5)}, '
                  '${_location!.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: const Text('Save Place'),
            ),
          ],
        ),
      ),
    );
  }
}