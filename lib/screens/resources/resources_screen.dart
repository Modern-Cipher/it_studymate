import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/resource.dart';
import '../../state/resource_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/resource_tile.dart';
import 'player_screen.dart';
import 'resource_form_sheet.dart';

enum ResourceSort { newest, oldest, title }

extension ResourceSortLabel on ResourceSort {
  String get label => switch (this) {
    ResourceSort.newest => 'Newest first',
    ResourceSort.oldest => 'Oldest first',
    ResourceSort.title => 'Title A-Z',
  };

  IconData get icon => switch (this) {
    ResourceSort.newest => Icons.south,
    ResourceSort.oldest => Icons.north,
    ResourceSort.title => Icons.sort_by_alpha,
  };
}

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final TextEditingController _search = TextEditingController();
  ResourceKind? _filter;
  ResourceSort _sort = ResourceSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Resource> _visible(ResourceProvider provider) {
    final String query = _search.text.trim().toLowerCase();
    final List<Resource> items = provider.items.where((Resource resource) {
      if (_filter != null && resource.kind != _filter) return false;
      if (query.isEmpty) return true;
      final String haystack =
          '${resource.title} ${resource.subjectCode ?? ''} ${resource.kind.label}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
    switch (_sort) {
      case ResourceSort.newest:
        items.sort(
          (Resource a, Resource b) => b.createdAt.compareTo(a.createdAt),
        );
      case ResourceSort.oldest:
        items.sort(
          (Resource a, Resource b) => a.createdAt.compareTo(b.createdAt),
        );
      case ResourceSort.title:
        items.sort(
          (Resource a, Resource b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return items;
  }

  Future<void> _openSortSheet() async {
    final ResourceSort? picked = await showModalBottomSheet<ResourceSort>(
      context: context,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...ResourceSort.values.map(
              (ResourceSort option) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.icon,
                  size: 20,
                  color: _sort == option
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _sort == option
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sort == option
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: _sort == option
                    ? const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _sort = picked);
  }

  Future<void> _confirmDelete(Resource resource) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Delete material?'),
        content: Text(
          '"${resource.title}" will be removed from this device. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ResourceProvider>().remove(resource);
  }

  @override
  Widget build(BuildContext context) {
    final ResourceProvider provider = context.watch<ResourceProvider>();
    final List<Resource> visible = _visible(provider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Learning materials',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '${provider.items.length} saved · ${visible.length} shown',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _search,
                onChanged: (String value) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search title, subject, or type',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: <Widget>[
                _FilterChip(
                  label: 'All',
                  icon: Icons.apps,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...ResourceKind.values.map(
                  (ResourceKind kind) => _FilterChip(
                    label: kind.label,
                    icon: _kindIcon(kind),
                    selected: _filter == kind,
                    onTap: () => setState(() => _filter = kind),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _openSortSheet,
              child: Row(
                children: <Widget>[
                  Icon(_sort.icon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _sort.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  if (_filter != null || _search.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _filter = null);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.loading
                ? const AppLoading(label: 'Loading materials')
                : provider.items.isEmpty
                ? AppEmptyState(
                    icon: Icons.ondemand_video_outlined,
                    title: 'No materials yet',
                    message:
                        'Upload a video, photo, or audio file, capture one with the camera, or paste a link.',
                    actionLabel: 'Add material',
                    onAction: () => showResourceFormSheet(context),
                  )
                : visible.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message:
                        'No material matches that keyword or category. Try another search or clear the filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                    itemCount: visible.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Resource resource = visible[index];
                      return ResourceTile(
                        resource: resource,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext routeContext) =>
                                PlayerScreen(resource: resource),
                          ),
                        ),
                        onDelete: () => _confirmDelete(resource),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _kindIcon(ResourceKind kind) {
    switch (kind) {
      case ResourceKind.video:
        return Icons.videocam_outlined;
      case ResourceKind.image:
        return Icons.image_outlined;
      case ResourceKind.audio:
        return Icons.audiotrack;
      case ResourceKind.link:
        return Icons.link;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
