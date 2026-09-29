import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../popup/feature_popup.dart';
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
                  child: FeaturePopup(
                    feature: _controller.selectedFeature!,
                    onClose: _controller.clearSelection,
                  ),
                ),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _controller.isLocating
      //       ? null
      //       : () {
      //           _controller.showCurrentLocation();
      //         },
      //   icon: _controller.isLocating
      //       ? const SizedBox(
      //           width: 18,
      //           height: 18,
      //           child: CircularProgressIndicator(strokeWidth: 2),
      //         )
      //       : const Icon(Icons.my_location),
      //   label: const Text('Lokasi saya'),
      // ),
    );
  }
}
