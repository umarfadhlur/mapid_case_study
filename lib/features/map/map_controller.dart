import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/map_feature.dart';
import '../../data/services/mapid_service.dart';

class TourismMapController extends ChangeNotifier {
  TourismMapController({MapidService? service})
    : _service = service ?? MapidService();

  final MapidService _service;

  MapLibreMapController? _map;

  List<MapFeature> _features = [];
  MapFeature? _selectedFeature;

  bool _isLoading = false;
  bool _isLocating = false;

  String? _errorMessage;

  bool get isLoading => _isLoading;

  bool get isLocating => _isLocating;

  String? get errorMessage => _errorMessage;

  MapFeature? get selectedFeature => _selectedFeature;

  int get featureCount => _features.length;

  void attachMap(MapLibreMapController controller) {
    _map = controller;
  }

  Future<void> onStyleLoaded() async {
    await loadTourismLayer();

    // GPS tetap dicoba walaupun request
    // layer wisata mengalami error.
    await showCurrentLocation(moveCamera: false);
  }

  Future<void> loadTourismLayer() async {
    final map = _map;
    if (map == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final features = await _service.getTourismFeatures();

      if (_map != map) return;

      final geoJson = {
        'type': 'FeatureCollection',
        'features': features.map((feature) => feature.toGeoJson()).toList(),
      };

      final sourceIds = await map.getSourceIds();

      if (sourceIds.contains(MapConstants.tourismSourceId)) {
        await map.setGeoJsonSource(MapConstants.tourismSourceId, geoJson);
      } else {
        await map.addGeoJsonSource(MapConstants.tourismSourceId, geoJson);

        await map.addCircleLayer(
          MapConstants.tourismSourceId,
          MapConstants.tourismLayerId,
          const CircleLayerProperties(
            circleColor: '#E65100',
            circleRadius: 9,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        );
      }

      _features = features;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Gagal memuat layer: $error';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onMapClick(Point<double> point, LatLng coordinates) async {
    final map = _map;
    if (map == null) return;

    try {
      final renderedFeatures = await map.queryRenderedFeatures(point, [
        MapConstants.tourismLayerId,
      ], null);

      if (renderedFeatures.isEmpty) {
        clearSelection();
        return;
      }

      final rawFeature = renderedFeatures.first;

      if (rawFeature is! Map) {
        clearSelection();
        return;
      }

      final featureJson = Map<String, dynamic>.from(rawFeature);

      final tappedId = featureJson['id']?.toString();

      if (tappedId != null) {
        for (final feature in _features) {
          if (feature.id == tappedId) {
            _selectedFeature = feature;
            notifyListeners();
            return;
          }
        }
      }

      // Fallback: jika platform tidak
      // menyertakan feature ID, parse
      // feature hasil hit test.
      _selectedFeature = MapFeature.fromGeoJson(featureJson);

      notifyListeners();
    } catch (error) {
      _errorMessage = 'Gagal membaca titik: $error';
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedFeature == null) {
      return;
    }

    _selectedFeature = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> showCurrentLocation({bool moveCamera = true}) async {
    final map = _map;
    if (map == null || _isLocating) {
      return;
    }

    _isLocating = true;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw StateError('GPS perangkat belum aktif.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Izin lokasi belum diberikan.');
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 20),
      );

      if (_map != map) return;

      final geoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            },
            'properties': {'type': 'user-location'},
          },
        ],
      };

      final sourceIds = await map.getSourceIds();

      if (sourceIds.contains(MapConstants.userSourceId)) {
        await map.setGeoJsonSource(MapConstants.userSourceId, geoJson);
      } else {
        await map.addGeoJsonSource(MapConstants.userSourceId, geoJson);

        await map.addCircleLayer(
          MapConstants.userSourceId,
          MapConstants.userLayerId,
          const CircleLayerProperties(
            circleColor: '#1976D2',
            circleRadius: 10,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 3,
          ),
          enableInteraction: false,
        );
      }

      if (moveCamera) {
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage =
          'Lokasi tidak tersedia: '
          '$error';
      notifyListeners();
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _map = null;
    super.dispose();
  }
}
