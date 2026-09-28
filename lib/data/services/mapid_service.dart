import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../models/map_feature.dart';

class MapidService {
  MapidService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<MapFeature>> getTourismFeatures() async {
    if (Env.mapidApiKey.isEmpty ||
        Env.mapidLayerId.isEmpty ||
        Env.mapidProjectId.isEmpty) {
      throw StateError('Konfigurasi MAPID di .env belum lengkap.');
    }

    final response = await _dio.get<dynamic>(
      'https://geoserver.mapid.io/'
      'layers_new/get_layer',
      queryParameters: {
        'api_key': Env.mapidApiKey,
        'layer_id': Env.mapidLayerId,
        'project_id': Env.mapidProjectId,
      },
    );

    final rawBody = response.data;

    if (rawBody is! Map) {
      throw const FormatException('Respons GEO MAPID bukan objek JSON.');
    }

    final body = Map<String, dynamic>.from(rawBody);

    final rawFeatures = body['features'];

    if (body['type'] != 'FeatureCollection' || rawFeatures is! List) {
      throw const FormatException(
        'Respons GEO MAPID bukan '
        'FeatureCollection.',
      );
    }

    final features = <MapFeature>[];

    for (final item in rawFeatures) {
      if (item is! Map) continue;

      try {
        features.add(MapFeature.fromGeoJson(Map<String, dynamic>.from(item)));
      } on FormatException {
        // Lewati feature yang geometry-nya
        // kosong/tidak valid.
        continue;
      }
    }

    if (features.isEmpty) {
      throw const FormatException(
        'Tidak ditemukan titik wisata '
        'yang valid.',
      );
    }

    return features;
  }
}
