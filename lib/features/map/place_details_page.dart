import 'package:flutter/material.dart';

import '../../data/models/map_feature.dart';
import '../../data/models/place_details.dart';

class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage({super.key, required this.feature, this.enrichment});

  final MapFeature feature;
  final PlaceDetails? enrichment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = enrichment?.imageUrl?.trim();

    return Scaffold(
      appBar: AppBar(
        title: feature.name.isNotEmpty ? Text(feature.name) : null,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _PlaceImage(imageUrl: imageUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.location_city, size: 18),
                        label: Text(feature.city),
                      ),
                      Chip(
                        avatar: const Icon(Icons.calendar_month, size: 18),
                        label: Text(feature.period),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  if (enrichment?.description.trim().isNotEmpty == true) ...[
                    Text(
                      'Tentang tempat ini',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildParagraphs(context, enrichment!.description),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    'Informasi lokasi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat',
                    value: feature.address,
                  ),
                  _DetailItem(
                    icon: Icons.map_outlined,
                    title: 'Kecamatan',
                    value: feature.district,
                  ),
                  _DetailItem(
                    icon: Icons.place_outlined,
                    title: 'Desa/Kelurahan',
                    value: feature.village,
                  ),
                  _DetailItem(
                    icon: Icons.calendar_month,
                    title: 'Periode data',
                    value: feature.period,
                  ),

                  if (enrichment?.imageSourceUrl != null) ...[
                    const SizedBox(height: 24),
                    Text('Sumber gambar', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    SelectableText(
                      enrichment!.imageSourceUrl!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs(BuildContext context, String description) {
    final paragraphs = description
        .split(RegExp(r'\n\s*\n'))
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty);

    return [
      for (final paragraph in paragraphs)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            paragraph,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
    ];
  }
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _placeholder(context);
    }

    return SizedBox(
      width: double.infinity,
      height: 240,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return _placeholder(context, isLoading: true);
        },
        errorBuilder: (context, error, stackTrace) {
          return _placeholder(context);
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context, {bool isLoading = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 240,
      color: colorScheme.primaryContainer,
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Icon(
                Icons.landscape_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
