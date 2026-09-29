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
    this.onTap,
  });

  final MapFeature feature;
  final PlaceDetails? enrichment;
  final bool isLoadingEnrichment;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Material(
              color: colorScheme.surface,
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildSummary(context)),
                      const SizedBox(width: 12),
                      _buildThumbnail(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(top: 0, right: -5, child: _buildCloseButton()),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final address = feature.address.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 17,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _SmallChip(icon: Icons.location_city, label: feature.city),
            _SmallChip(icon: Icons.calendar_month, label: feature.period),
          ],
        ),
        if (isLoadingEnrichment && enrichment == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    final imageUrl = enrichment?.imageUrl?.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 92,
            height: 92,
            child: imageUrl == null || imageUrl.isEmpty
                ? _placeholder(colorScheme)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return _placeholder(colorScheme, loading: true);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _placeholder(colorScheme);
                    },
                  ),
          ),
        ),
        const SizedBox(height: 6),
        _NextChip(icon: Icons.arrow_forward, label: 'Lihat detail'),
      ],
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.red,
        shape: const CircleBorder(),
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          tooltip: 'Tutup popup',
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 15, color: Colors.white),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, {bool loading = false}) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            : Icon(
                Icons.landscape_rounded,
                size: 34,
                color: colorScheme.primary,
              ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _NextChip extends StatelessWidget {
  const _NextChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 4),
          Icon(icon, size: 13),
        ],
      ),
    );
  }
}
