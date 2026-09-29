import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/place_details.dart';

class PlaceDetailsService {
  PlaceDetailsService({Dio? dio}) : _dio = dio ?? Dio();

  static const url =
      'https://umarfadhlur.my.id/'
      'assets/img/profile/'
      'jogja_description.json';

  final Dio _dio;

  Future<Map<String, PlaceDetails>> getEnrichments() async {
    final response = await _dio.get<dynamic>(
      url,
      options: Options(receiveTimeout: const Duration(seconds: 12)),
    );

    final Object? raw = response.data;

    // Bila hosting mengirim text/plain, Dio mungkin
    // memberikan String, bukan Map.
    final Object? decoded = raw is String ? jsonDecode(raw) : raw;

    if (decoded is! Map) {
      throw const FormatException('Root JSON enrichment harus berupa object.');
    }

    final root = Map<String, dynamic>.from(decoded);

    final rawPlaces = root['places'];

    if (rawPlaces is! List) {
      throw const FormatException('Field "places" harus berupa array.');
    }

    final result = <String, PlaceDetails>{};

    for (final rawPlace in rawPlaces) {
      if (rawPlace is! Map) continue;

      try {
        final place = PlaceDetails.fromJson(
          Map<String, dynamic>.from(rawPlace),
        );

        result[place.featureId] = place;
      } on FormatException {
        // Lewati satu entri rusak tanpa membuat
        // seluruh katalog gagal dimuat.
        continue;
      }
    }

    return result;
  }
}
