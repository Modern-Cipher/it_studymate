import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../models/resource.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';
import 'app_card.dart';

class ResourceTile extends StatelessWidget {
  const ResourceTile({
    super.key,
    required this.resource,
    this.onTap,
    this.onDelete,
  });

  final Resource resource;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  IconData get _icon {
    switch (resource.kind) {
      case ResourceKind.image:
        return Icons.image_outlined;
      case ResourceKind.audio:
        return Icons.headphones_outlined;
      case ResourceKind.link:
        return Icons.link;
      case ResourceKind.video:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasThumb =
        resource.hasThumbnail && File(resource.thumbnailPath).existsSync();
    final bool imageIsPreview =
        resource.isImage && File(resource.localPath).existsSync();
    final String previewPath = hasThumb
        ? resource.thumbnailPath
        : imageIsPreview
        ? resource.localPath
        : '';
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: previewPath.isNotEmpty
                  ? Image.file(File(previewPath), fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(_icon, color: AppColors.primary, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  resource.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    if (resource.subjectCode != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hexColor(resource.subjectColor ?? '#2563EB')
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resource.subjectCode!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: hexColor(
                              resource.subjectColor ?? '#2563EB',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      resource.isLink ? Icons.open_in_new : _icon,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resource.kind.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
