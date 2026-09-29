import 'package:flutter/material.dart';

import '../../data/models/map_feature.dart';
import '../../data/models/place_details.dart';

class FeaturePopup extends StatelessWidget {
  const FeaturePopup({
    super.key,
    required this.feature,
    required this.onClose,
    this.enrichment,
    this.isLoadingEnrichment = false,
  });

  final MapFeature feature;
  final PlaceDetails? enrichment;
  final bool isLoadingEnrichment;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.60,
      ),
      child: Material(
        color: colorScheme.surface,
        elevation: 12,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildImage(colorScheme),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Tutup detail',
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.location_city,
                          label: feature.city,
                        ),
                        _InfoChip(
                          icon: Icons.calendar_month,
                          label: feature.period,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (isLoadingEnrichment && enrichment == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Memuat informasi '
                          'tambahan...',
                        ),
                      ),

                    if (enrichment?.description.isNotEmpty == true) ...[
                      Text(
                        'Tentang tempat ini',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._descriptionParagraphs(enrichment!.description),
                      const SizedBox(height: 10),
                    ],

                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat',
                      value: feature.address,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.map_outlined,
                      label: 'Kecamatan',
                      value: feature.district,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.place_outlined,
                      label: 'Desa/Kelurahan',
                      value: feature.village,
                    ),

                    if (enrichment?.imageSourceUrl != null) ...[
                      const SizedBox(height: 14),
                      SelectableText(
                        'Sumber gambar: '
                        '${enrichment!.imageSourceUrl}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _descriptionParagraphs(String description) {
    final paragraphs = description
        .split(RegExp(r'\n\s*\n'))
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty);

    return [
      for (final paragraph in paragraphs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(paragraph),
        ),
    ];
  }

  Widget _buildImage(ColorScheme colorScheme) {
    final url = enrichment?.imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return _imagePlaceholder(colorScheme);
    }

    return SizedBox(
      width: double.infinity,
      height: 170,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return _imagePlaceholder(colorScheme, showLoading: true);
        },
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder(colorScheme);
        },
      ),
    );
  }

  Widget _imagePlaceholder(
    ColorScheme colorScheme, {
    bool showLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: showLoading
            ? const CircularProgressIndicator()
            : Icon(
                Icons.landscape_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
