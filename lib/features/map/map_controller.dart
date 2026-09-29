import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/map_feature.dart';
import '../../data/models/place_details.dart';
import '../../data/services/mapid_service.dart';
import '../../data/services/place_details_service.dart';

class TourismMapController extends ChangeNotifier {
  TourismMapController({
    MapidService? service,
    PlaceDetailsService? enrichmentService,
  }) : _service = service ?? MapidService(),
       _enrichmentService = enrichmentService ?? PlaceDetailsService();

  final MapidService _service;
  final PlaceDetailsService _enrichmentService;

  MapLibreMapController? _map;

  List<MapFeature> _features = [];
  MapFeature? _selectedFeature;

  Map<String, PlaceDetails> _enrichmentsById = {};

  bool _isLoading = false;
  bool _isLocating = false;
  bool _isLoadingEnrichment = false;
  bool _enrichmentLoaded = false;
  bool _isShowingUserLocation = false;
  bool _isDisposed = false;

  String? _errorMessage;

  bool get isLoading => _isLoading;

  bool get isLocating => _isLocating;

  bool get isLoadingEnrichment => _isLoadingEnrichment;

  bool get isShowingUserLocation => _isShowingUserLocation;

  String? get errorMessage => _errorMessage;

  MapFeature? get selectedFeature => _selectedFeature;

  int get featureCount => _features.length;

  PlaceDetails? get selectedEnrichment {
    final feature = _selectedFeature;

    if (feature == null) return null;

    return _enrichmentsById[feature.id];
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void attachMap(MapLibreMapController controller) {
    if (_isDisposed) return;

    _map = controller;
  }

  Future<void> onStyleLoaded() async {
    if (_isDisposed) return;
    unawaited(loadEnrichments());

    await loadTourismLayer();

    if (_isDisposed) return;
    await showCurrentLocation(moveCamera: false);
  }

  Future<void> loadEnrichments() async {
    if (_isDisposed || _enrichmentLoaded || _isLoadingEnrichment) {
      return;
    }

    _isLoadingEnrichment = true;
    _notify();

    try {
      final result = await _enrichmentService.getEnrichments();

      if (_isDisposed) return;

      _enrichmentsById = result;
      _enrichmentLoaded = true;

      _notify();
    } catch (error) {
      debugPrint('Gagal memuat enrichment: $error');
    } finally {
      _isLoadingEnrichment = false;
      _notify();
    }
  }

  Future<void> loadTourismLayer() async {
    final map = _map;

    if (_isDisposed || map == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final features = await _service.getTourismFeatures();

      if (_isDisposed || _map != map) {
        return;
      }

      final geoJson = {
        'type': 'FeatureCollection',
        'features': features.map((feature) => feature.toGeoJson()).toList(),
      };

      final sourceIds = await map.getSourceIds();

      if (sourceIds.contains(MapConstants.tourismSourceId)) {
        await map.setGeoJsonSource(MapConstants.tourismSourceId, geoJson);
      } else {
        await map.addGeoJsonSource(MapConstants.tourismSourceId, geoJson);

        final pinBytes = await _iconToPng(Icons.location_on, Colors.red);

        if (_isDisposed || _map != map) {
          return;
        }

        await map.addImage('tourism-pin-image', pinBytes);

        await map.addSymbolLayer(
          MapConstants.tourismSourceId,
          MapConstants.tourismLayerId,
          const SymbolLayerProperties(
            iconImage: 'tourism-pin-image',
            iconSize: 1,
            iconAnchor: 'bottom',
            iconAllowOverlap: true,
          ),
          enableInteraction: true,
        );
      }

      if (_isDisposed || _map != map) {
        return;
      }

      _features = features;
      _errorMessage = null;
      _notify();
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = 'Gagal memuat layer: $error';
      _notify();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> onMapClick(Point<double> point, LatLng coordinates) async {
    final map = _map;

    if (_isDisposed || map == null) {
      return;
    }

    try {
      final renderedFeatures = await map.queryRenderedFeatures(point, [
        MapConstants.tourismLayerId,
      ], null);

      if (_isDisposed || _map != map) {
        return;
      }

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

      MapFeature? selectedFeature;

      if (tappedId != null) {
        for (final feature in _features) {
          if (feature.id == tappedId) {
            selectedFeature = feature;
            break;
          }
        }
      }

      selectedFeature ??= MapFeature.fromGeoJson(featureJson);

      _selectedFeature = selectedFeature;
      _isShowingUserLocation = false;
      _notify();

      await map.animateCamera(
        CameraUpdate.newLatLngZoom(selectedFeature.position, 15),
      );
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = 'Gagal membaca titik: $error';
      _notify();
    }
  }

  void clearSelection() {
    if (_selectedFeature == null) {
      return;
    }

    _selectedFeature = null;
    _notify();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    _notify();
  }

  Future<void> showCurrentLocation({bool moveCamera = true}) async {
    final map = _map;

    if (_isDisposed || map == null || _isLocating) {
      return;
    }

    _isLocating = true;
    _notify();

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

      final position = await Geolocator.getCurrentPosition();

      if (_isDisposed || _map != map) {
        return;
      }

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

        final pinBytes = await _iconToPng(Icons.location_on, Colors.blue);

        if (_isDisposed || _map != map) {
          return;
        }

        await map.addImage('user-location-pin-image', pinBytes);

        await map.addSymbolLayer(
          MapConstants.userSourceId,
          MapConstants.userLayerId,
          const SymbolLayerProperties(
            iconImage: 'user-location-pin-image',
            iconSize: 1,
            iconAnchor: 'bottom',
            iconAllowOverlap: true,
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

        if (_isDisposed || _map != map) {
          return;
        }

        _isShowingUserLocation = true;
        _notify();
      }

      if (_isDisposed) return;

      _errorMessage = null;
      _notify();
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = 'Lokasi tidak tersedia: $error';
      _notify();
    } finally {
      _isLocating = false;
      _notify();
    }
  }

  Future<void> moveToInitialPosition() async {
    final map = _map;

    if (_isDisposed || map == null) {
      return;
    }

    try {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(
          MapConstants.initialPosition,
          MapConstants.initialZoom,
        ),
      );

      if (_isDisposed || _map != map) {
        return;
      }

      _isShowingUserLocation = false;
      _notify();
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = 'Gagal kembali ke Jogja: $error';
      _notify();
    }
  }

  Future<void> toggleLocationCamera() async {
    if (_isDisposed || _isLocating) {
      return;
    }

    if (_isShowingUserLocation) {
      await moveToInitialPosition();
    } else {
      await showCurrentLocation(moveCamera: true);
    }
  }

  Future<Uint8List> _iconToPng(IconData icon, Color color) async {
    const canvasSize = 96.0;
    const iconSize = 88.0;

    final recorder = ui.PictureRecorder();

    final canvas = Canvas(recorder);

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          package: icon.fontPackage,
          fontSize: iconSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    try {
      painter.layout();

      painter.paint(
        canvas,
        Offset(
          (canvasSize - painter.width) / 2,
          (canvasSize - painter.height) / 2,
        ),
      );

      final picture = recorder.endRecording();

      try {
        final image = await picture.toImage(
          canvasSize.toInt(),
          canvasSize.toInt(),
        );

        try {
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          if (byteData == null) {
            throw StateError('Gagal membuat gambar pin.');
          }

          return byteData.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      } finally {
        picture.dispose();
      }
    } finally {
      painter.dispose();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _map = null;
    super.dispose();
  }
}
