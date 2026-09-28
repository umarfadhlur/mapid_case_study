import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/map_feature.dart';
import 'map_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final TourismMapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TourismMapController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(MapConstants.layerTitle)),
      body: ListenableBuilder(
        listenable: _controller,

        // Map tidak perlu dibuat ulang setiap loading,
        // error, atau selected feature berubah.
        child: MapLibreMap(
          styleString: MapConstants.styleUrl,
          initialCameraPosition: const CameraPosition(
            target: MapConstants.initialPosition,
            zoom: MapConstants.initialZoom,
          ),
          featureTapsTriggersMapClick: true,
          onMapCreated: _controller.attachMap,
          onStyleLoadedCallback: _controller.onStyleLoaded,
          onMapClick: _controller.onMapClick,
        ),

        builder: (context, mapWidget) {
          return Stack(
            children: [
              Positioned.fill(child: mapWidget!),

              if (_controller.isLoading)
                const Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Memuat titik wisata...'),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_controller.errorMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: const Color(0xFFFFE8E8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: Text(_controller.errorMessage!)),
                          IconButton(
                            onPressed: _controller.clearError,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_controller.selectedFeature != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildFeaturePopup(_controller.selectedFeature!),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLocating
            ? null
            : () {
                _controller.showCurrentLocation();
              },
        icon: _controller.isLocating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: const Text('Lokasi saya'),
      ),
    );
  }

  Widget _buildFeaturePopup(MapFeature feature) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feature.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _controller.clearSelection,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Alamat: ${feature.address}'),
            const SizedBox(height: 6),
            Text('Kecamatan: ${feature.district}'),
            const SizedBox(height: 6),
            Text('Waktu: ${feature.period}'),
          ],
        ),
      ),
    );
  }
}
