import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/resource.dart';
import '../../models/subject.dart';
import '../../services/resource_service.dart';
import '../../state/auth_provider.dart';
import '../../state/resource_provider.dart';
import '../../state/subject_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

Future<void> showResourceFormSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: const _ResourceFormSheet(),
    ),
  );
}

class _ResourceFormSheet extends StatefulWidget {
  const _ResourceFormSheet();

  @override
  State<_ResourceFormSheet> createState() => _ResourceFormSheetState();
}

class _ResourceFormSheetState extends State<_ResourceFormSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _url = TextEditingController();

  ResourceKind _kind = ResourceKind.video;
  int? _subjectId;
  String _path = '';
  String _fileName = '';
  String _thumbPath = '';
  String? _error;
  bool _saving = false;
  bool _picking = false;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  void _selectKind(ResourceKind kind) {
    setState(() {
      _kind = kind;
      _error = null;
      _path = '';
      _fileName = '';
    });
  }

  void _applyPick(StoredPick? pick) {
    if (!mounted) return;
    final String pickedPath = pick?.path ?? '';
    final String pickedName = pick?.name ?? '';
    setState(() {
      _picking = false;
      if (pickedPath.isNotEmpty) {
        _path = pickedPath;
        _fileName = pickedName;
      }
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _picking = false;
      _error = message;
    });
  }

  Future<void> _pickFromDevice() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      StoredPick? pick;
      if (_kind == ResourceKind.video) {
        pick = await ResourceService.instance.pickVideo();
      } else if (_kind == ResourceKind.image) {
        pick = await ResourceService.instance.pickImage();
      } else if (_kind == ResourceKind.audio) {
        pick = await ResourceService.instance.pickAudio();
      }
      _applyPick(pick);
    } on MediaPermissionException catch (error) {
      _fail(error.message);
    } catch (error) {
      _fail('Could not open the picker: $error');
    }
  }

  Future<void> _capture() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      StoredPick? pick;
      if (_kind == ResourceKind.video) {
        pick = await ResourceService.instance.captureVideo();
      } else if (_kind == ResourceKind.image) {
        pick = await ResourceService.instance.capturePhoto();
      }
      _applyPick(pick);
    } on MediaPermissionException catch (error) {
      _fail(error.message);
    } catch (error) {
      _fail('Camera is not available: $error');
    }
  }

  Future<void> _pickThumb() async {
    try {
      final StoredPick? pick = await ResourceService.instance.pickImage();
      if (pick == null || !mounted) return;
      setState(() => _thumbPath = pick.path);
    } catch (error) {
      _fail('Could not pick an image: $error');
    }
  }

  Future<void> _save() async {
    final int? userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    if (_kind == ResourceKind.link) {
      final String link = _url.text.trim();
      if (!link.startsWith('http://') && !link.startsWith('https://')) {
        setState(() => _error = 'Link must start with http:// or https://');
        return;
      }
    } else if (_path.isEmpty) {
      setState(() => _error = 'Choose or capture a file first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ResourceProvider resources = context.read<ResourceProvider>();
    await resources.add(
      Resource(
        userId: userId,
        subjectId: _subjectId,
        kind: _kind,
        title: title,
        url: _kind == ResourceKind.link ? _url.text.trim() : '',
        localPath: _kind == ResourceKind.link ? '' : _path,
        thumbnailPath: _thumbPath,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = context.watch<SubjectProvider>().subjects;
    final bool isMedia = _kind != ResourceKind.link;
    final bool canCapture =
        _kind == ResourceKind.video || _kind == ResourceKind.image;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
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
              'New learning material',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ResourceKind.values.map((ResourceKind kind) {
                final bool selected = _kind == kind;
                return GestureDetector(
                  onTap: () => _selectKind(kind),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          _kindIcon(kind),
                          size: 15,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          kind.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Title',
              controller: _title,
              hint: _kind == ResourceKind.audio
                  ? 'Subnetting lecture recording'
                  : 'Linked list explained',
              prefixIcon: Icons.title,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _Chip(
                  label: 'General',
                  color: AppColors.textMuted,
                  selected: _subjectId == null,
                  onTap: () => setState(() => _subjectId = null),
                ),
                ...subjects.map(
                  (Subject subject) => _Chip(
                    label: subject.code,
                    color: hexColor(subject.color),
                    selected: _subjectId == subject.id,
                    onTap: () => setState(() => _subjectId = subject.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (isMedia) ...<Widget>[
              AppCard(
                onTap: _picking ? null : _pickFromDevice,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.upload_file,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _picking
                            ? 'Opening...'
                            : _fileName.isEmpty
                            ? 'Choose ${_kind.label.toLowerCase()} from this device'
                            : _fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _fileName.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canCapture) ...<Widget>[
                const SizedBox(height: 10),
                AppCard(
                  onTap: _picking ? null : _capture,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _kind == ResourceKind.video
                            ? Icons.videocam_outlined
                            : Icons.photo_camera_outlined,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _kind == ResourceKind.video
                              ? 'Record a video with the camera'
                              : 'Take a photo with the camera',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (_kind == ResourceKind.link) ...<Widget>[
              AppTextField(
                label: 'Video URL',
                controller: _url,
                hint: 'https://youtube.com/watch?v=...',
                prefixIcon: Icons.link,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (String value) => _save(),
              ),
            ],
            const SizedBox(height: 12),
            if (_kind != ResourceKind.audio)
              AppCard(
                onTap: _pickThumb,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _thumbPath.isEmpty
                            ? 'Choose a thumbnail image (optional)'
                            : 'Thumbnail selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _thumbPath.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    size: 17,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            AppButton(label: 'Save material', onPressed: _save, loading: _saving),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
