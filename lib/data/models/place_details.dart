class PlaceDetails {
  const PlaceDetails({
    required this.featureId,
    required this.description,
    this.imageUrl,
    this.imageSourceUrl,
  });

  final String featureId;
  final String description;
  final String? imageUrl;
  final String? imageSourceUrl;

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final featureId = json['featureId']?.toString().trim() ?? '';

    if (featureId.isEmpty) {
      throw const FormatException('featureId enrichment kosong.');
    }

    return PlaceDetails(
      featureId: featureId,
      description: json['description']?.toString().trim() ?? '',
      imageUrl: _nullableText(json['imageUrl']),
      imageSourceUrl: _nullableText(json['imageSourceUrl']),
    );
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
