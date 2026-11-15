enum ResourceKind { video, image, audio, link }

ResourceKind resourceKindFromValue(int? value) {
  if (value == null) return ResourceKind.video;
  if (value < 0 || value >= ResourceKind.values.length) return ResourceKind.video;
  return ResourceKind.values[value];
}

extension ResourceKindLabel on ResourceKind {
  String get label => switch (this) {
    ResourceKind.video => 'Video',
    ResourceKind.image => 'Photo',
    ResourceKind.audio => 'Audio',
    ResourceKind.link => 'Link',
  };
}

class Resource {
  Resource({
    this.id,
    required this.userId,
    this.subjectId,
    required this.kind,
    required this.title,
    this.url = '',
    this.localPath = '',
    this.thumbnailPath = '',
    this.subjectCode,
    this.subjectColor,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final int? subjectId;
  final ResourceKind kind;
  final String title;
  final String url;
  final String localPath;
  final String thumbnailPath;
  final String? subjectCode;
  final String? subjectColor;
  final DateTime createdAt;

  factory Resource.fromMap(Map<String, Object?> map) => Resource(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    subjectId: map['subject_id'] as int?,
    kind: resourceKindFromValue(map['kind'] as int?),
    title: map['title'] as String,
    url: (map['url'] as String?) ?? '',
    localPath: (map['local_path'] as String?) ?? '',
    thumbnailPath: (map['thumbnail_path'] as String?) ?? '',
    subjectCode: map['subject_code'] as String?,
    subjectColor: map['subject_color'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, Object?> toInsertMap() => <String, Object?>{
    'user_id': userId,
    'subject_id': subjectId,
    'kind': kind.index,
    'title': title,
    'url': url,
    'local_path': localPath,
    'thumbnail_path': thumbnailPath,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isLink => kind == ResourceKind.link;

  bool get isImage => kind == ResourceKind.image;

  bool get isAudio => kind == ResourceKind.audio;

  bool get isVideo => kind == ResourceKind.video;

  bool get hasThumbnail => thumbnailPath.isNotEmpty;

  String get subtitle {
    if (subjectCode != null) return subjectCode!;
    return isLink ? 'External link' : kind.label;
  }
}
