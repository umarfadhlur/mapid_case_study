import 'package:maplibre_gl/maplibre_gl.dart';

class MapFeature {
  const MapFeature({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.properties,
  });

  final String id;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> properties;

  String get name {
    final rawName = _text('NAMA', fallback: 'Tempat wisata');
    final cleaned = rawName.replaceAllMapped(RegExp(r'\s*\([^)]*\)'), (match) {
      final part = match.group(0) ?? '';
      return RegExp(r'[ʦʧ�]').hasMatch(part) ? '' : part;
    });
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String get address => _text('ALAMAT');

  String get province => _text('PROVINSI');

  String get city => _text('KABKOT');

  String get district => _text('KECAMATAN');

  String get village => _text('DESA');

  String get period => _text('WAKTU');

  LatLng get position => LatLng(latitude, longitude);

  String _text(String key, {String fallback = '-'}) {
    final value = properties[key]?.toString().trim();

    return value == null || value.isEmpty ? fallback : value;
  }

  factory MapFeature.fromGeoJson(Map<String, dynamic> json) {
    final rawGeometry = json['geometry'];
    final rawProperties = json['properties'];

    if (rawGeometry is! Map || rawProperties is! Map) {
      throw const FormatException(
        'Feature tidak memiliki geometry atau properties.',
      );
    }

    final geometry = Map<String, dynamic>.from(rawGeometry);

    if (geometry['type'] != 'Point') {
      throw const FormatException('Feature bukan Point.');
    }

    final coordinates = geometry['coordinates'];

    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw const FormatException('Koordinat Point tidak valid.');
    }

    final longitude = (coordinates[0] as num).toDouble();

    final latitude = (coordinates[1] as num).toDouble();

    if (longitude < -180 ||
        longitude > 180 ||
        latitude < -90 ||
        latitude > 90) {
      throw const FormatException('Koordinat berada di luar batas.');
    }

    return MapFeature(
      id: json['id']?.toString() ?? '',
      longitude: longitude,
      latitude: latitude,
      properties: Map<String, dynamic>.from(rawProperties),
    );
  }

  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Feature',
      if (id.isNotEmpty) 'id': id,
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': properties,
    };
  }
}
