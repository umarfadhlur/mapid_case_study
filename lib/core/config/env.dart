import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String get mapidApiKey => dotenv.env['MAPID_API_KEY'] ?? '';

  static String get mapidLayerId => dotenv.env['MAPID_LAYER_ID'] ?? '';

  static String get mapidProjectId => dotenv.env['MAPID_PROJECT_ID'] ?? '';
}
