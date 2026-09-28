import 'package:maplibre_gl/maplibre_gl.dart';

abstract final class MapConstants {
  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const layerTitle = 'Pariwisata Jogja';

  static const initialPosition = LatLng(-7.800, 110.378);

  static const initialZoom = 13.0;

  static const tourismSourceId = 'mapid-tourism-source';

  static const tourismLayerId = 'mapid-tourism-points';

  static const userSourceId = 'user-location-source';

  static const userLayerId = 'user-location-point';
}
