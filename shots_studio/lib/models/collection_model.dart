class Collection {
  final String id;
  final String? name;
  final String? description;
  final List<String> screenshotIds;
  final DateTime lastModified;
  final int screenshotCount;
  final bool isAutoAddEnabled;
  final DateTime? lastAutoCategorized;
  final int autoCategorizedCount;
  final Map<String, dynamic> categorizationMetadata;
  final Set<String> scannedSet;
  final int displayOrder;

  Collection({
    required this.id,
    this.name,
    this.description,
    required this.screenshotIds,
    required this.lastModified,
    required this.screenshotCount,
    this.isAutoAddEnabled = false,
    this.lastAutoCategorized,
    this.autoCategorizedCount = 0,
    this.categorizationMetadata = const {},
    this.scannedSet = const {},
    this.displayOrder = 0,
  });

  Collection addScreenshot(
    String screenshotId, {
    bool isAutoCategorized = false,
  }) {
    if (!screenshotIds.contains(screenshotId)) {
      final newIds = List<String>.from(screenshotIds)..add(screenshotId);
      return copyWith(
        screenshotIds: newIds,
        screenshotCount: newIds.length,
        lastModified: DateTime.now(),
        autoCategorizedCount:
            isAutoCategorized ? autoCategorizedCount + 1 : autoCategorizedCount,
        lastAutoCategorized:
            isAutoCategorized ? DateTime.now() : lastAutoCategorized,
      );
    }
    return this;
  }

  Collection addMultipleScreenshots(
    List<String> screenshotIds, {
    bool isAutoCategorized = false,
  }) {
    final newIds = List<String>.from(this.screenshotIds);
    int addedCount = 0;

    for (String id in screenshotIds) {
      if (!newIds.contains(id)) {
        newIds.add(id);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      return copyWith(
        screenshotIds: newIds,
        screenshotCount: newIds.length,
        lastModified: DateTime.now(),
        autoCategorizedCount:
            isAutoCategorized
                ? autoCategorizedCount + addedCount
                : autoCategorizedCount,
        lastAutoCategorized:
            isAutoCategorized ? DateTime.now() : lastAutoCategorized,
      );
    }
    return this;
  }

  Collection addScannedScreenshots(List<String> screenshotIds) {
    final newScannedSet = Set<String>.from(scannedSet);
    newScannedSet.addAll(screenshotIds);

    return copyWith(scannedSet: newScannedSet, lastModified: DateTime.now());
  }

  Collection removeScreenshot(String screenshotId) {
    if (screenshotIds.contains(screenshotId)) {
      final newIds = List<String>.from(screenshotIds)..remove(screenshotId);
      return copyWith(
        screenshotIds: newIds,
        screenshotCount: newIds.length,
        lastModified: DateTime.now(),
      );
    }
    return this;
  }

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? screenshotIds,
    DateTime? lastModified,
    int? screenshotCount,
    bool? isAutoAddEnabled,
    DateTime? lastAutoCategorized,
    int? autoCategorizedCount,
    Map<String, dynamic>? categorizationMetadata,
    Set<String>? scannedSet,
    int? displayOrder,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      screenshotIds: screenshotIds ?? this.screenshotIds,
      lastModified: lastModified ?? this.lastModified,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      isAutoAddEnabled: isAutoAddEnabled ?? this.isAutoAddEnabled,
      lastAutoCategorized: lastAutoCategorized ?? this.lastAutoCategorized,
      autoCategorizedCount: autoCategorizedCount ?? this.autoCategorizedCount,
      categorizationMetadata:
          categorizationMetadata ?? this.categorizationMetadata,
      scannedSet: scannedSet ?? this.scannedSet,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  // Method to convert a Collection instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'screenshotIds': screenshotIds,
      'lastModified': lastModified.toIso8601String(),
      'screenshotCount': screenshotCount,
      'isAutoAddEnabled': isAutoAddEnabled,
      'lastAutoCategorized': lastAutoCategorized?.toIso8601String(),
      'autoCategorizedCount': autoCategorizedCount,
      'categorizationMetadata': categorizationMetadata,
      'scannedSet': scannedSet.toList(),
      'displayOrder': displayOrder,
    };
  }

  // Factory constructor to create a Collection instance from a Map (JSON)
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      screenshotIds: List<String>.from(json['screenshotIds'] as List<dynamic>),
      lastModified: DateTime.parse(json['lastModified'] as String),
      screenshotCount: json['screenshotCount'] as int,
      isAutoAddEnabled: json['isAutoAddEnabled'] as bool? ?? false,
      lastAutoCategorized:
          json['lastAutoCategorized'] != null
              ? DateTime.parse(json['lastAutoCategorized'] as String)
              : null,
      autoCategorizedCount: json['autoCategorizedCount'] as int? ?? 0,
      categorizationMetadata:
          json['categorizationMetadata'] as Map<String, dynamic>? ?? {},
      scannedSet:
          json['scannedSet'] != null
              ? Set<String>.from(json['scannedSet'] as List<dynamic>)
              : {},
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
