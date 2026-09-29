import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapid_case_study/data/models/map_feature.dart';

void main() {
  testWidgets('Menampilkan nama tempat wisata dari GeoJSON', (
    WidgetTester tester,
  ) async {
    final feature = MapFeature.fromGeoJson({
      'id': 'taman-vredeburg',
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [110.3652949, -7.8006346],
      },
      'properties': {
        'NAMA': 'TAMAN VREDEBURG',
        'ALAMAT': 'JL. MARGO MULYO NO.6',
        'KECAMATAN': 'GONDOMANAN',
        'WAKTU': 'Q2 2024',
      },
    });

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Text(feature.name))),
    );

    expect(find.text('TAMAN VREDEBURG'), findsOneWidget);

    expect(feature.position.latitude, closeTo(-7.8006346, 0.0000001));

    expect(feature.position.longitude, closeTo(110.3652949, 0.0000001));
  });
}
