import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:shots_studio/services/ai_service.dart';

class Screenshot {
  String id;
  String? path; // For mobile (file path)
  Uint8List? bytes; // For web (image bytes)
  String? title;
  String? description;
  List<String> tags;
  List<String> links; // Clickable information like phone numbers, URLs, etc.
  List<String> collectionIds;
  bool aiProcessed;
  DateTime addedOn;
  AiMetaData? aiMetadata;
  int? fileSize;
  bool isDeleted;
  DateTime? reminderTime;
  String? reminderText;
  String? notes; // Personal notes added by user

  Screenshot({
    required this.id,
    this.path,
    this.bytes,
    this.title,
    this.description,
    required this.tags,
    List<String>? links,
    List<String>? collectionIds,
    required this.aiProcessed,
    required this.addedOn,
    this.aiMetadata,
    this.fileSize,
    this.isDeleted = false,
    this.reminderTime,
    this.reminderText,
    this.notes,
  }) : links = links ?? [],
       collectionIds = collectionIds ?? [];

  void addToCollections(List<String> collections) {
    collectionIds.addAll(
      collections.where((id) => !collectionIds.contains(id)),
    );
  }

  List<String> get uniqueCollectionIds {
    return collectionIds.toSet().toList();
  }

  void addToCollection(String collectionId) {
    if (!collectionIds.contains(collectionId)) {
      collectionIds.add(collectionId);
    }
  }

  void deduplicateCollections() {
    final uniqueIds = collectionIds.toSet().toList();
    collectionIds.clear();
    collectionIds.addAll(uniqueIds);
  }

  // Method to convert a Screenshot instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'bytes': bytes != null ? base64Encode(bytes!) : null,
      'title': title,
      'description': description,
      'tags': tags,
      'links': links,
      'collectionIds': collectionIds,
      'aiProcessed': aiProcessed,
      'addedOn': addedOn.toIso8601String(),
      'aiMetadata': aiMetadata?.toJson(),
      'fileSize': fileSize,
      'isDeleted': isDeleted,
      'reminderTime': reminderTime?.toIso8601String(),
      'reminderText': reminderText,
      'notes': notes,
    };
  }

  // Factory constructor to create a Screenshot instance from a Map (JSON)
  factory Screenshot.fromJson(Map<String, dynamic> json) {
    return Screenshot(
      id: json['id'] as String,
      path: json['path'] as String?,
      bytes:
          json['bytes'] != null ? base64Decode(json['bytes'] as String) : null,
      title: json['title'] as String?,
      description: json['description'] as String?,
      tags: List<String>.from(json['tags'] as List<dynamic>),
      links:
          json['links'] != null
              ? List<String>.from(json['links'] as List<dynamic>)
              : [],
      collectionIds:
          List<String>.from(
            json['collectionIds'] as List<dynamic>,
          ).toSet().toList(), // Deduplicate on load
      aiProcessed: json['aiProcessed'] as bool,
      addedOn: DateTime.parse(json['addedOn'] as String),
      aiMetadata:
          json['aiMetadata'] != null
              ? AiMetaData.fromJson(json['aiMetadata'] as Map<String, dynamic>)
              : null,
      fileSize: json['fileSize'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      reminderTime:
          json['reminderTime'] != null
              ? DateTime.parse(json['reminderTime'] as String)
              : null,
      reminderText: json['reminderText'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Factory method to create a Screenshot from a file path
  /// This centralizes screenshot creation logic to ensure consistency
  static Future<Screenshot> fromFilePath({
    required String id,
    required String filePath,
    String? customTitle,
    List<String>? initialTags,
    bool aiProcessed = false,
    DateTime? customAddedOn,
    int? knownFileSize,
  }) async {
    final file = File(filePath);

    // Get file metadata
    final fileSize = knownFileSize ?? await file.length();
    final lastModified = customAddedOn ?? await file.lastModified();
    final fileName = filePath.split('/').last;

    return Screenshot(
      id: id,
      path: filePath,
      title: customTitle ?? fileName,
      tags: initialTags ?? [],
      aiProcessed: aiProcessed,
      addedOn: lastModified,
      fileSize: fileSize,
    );
  }

  /// Factory method to create a Screenshot from image bytes (for web or picked images)
  /// This centralizes screenshot creation logic to ensure consistency
  static Screenshot fromBytes({
    required String id,
    required Uint8List bytes,
    required String fileName,
    String? filePath,
    List<String>? initialTags,
    bool aiProcessed = false,
    DateTime? customAddedOn,
  }) {
    return Screenshot(
      id: id,
      path: filePath,
      bytes: bytes,
      title: fileName,
      tags: initialTags ?? [],
      aiProcessed: aiProcessed,
      addedOn: customAddedOn ?? DateTime.now(),
      fileSize: bytes.length,
    );
  }

  /// Factory method to create an updated copy of an existing screenshot
  /// This centralizes screenshot update logic to ensure consistency
  Screenshot copyWith({
    String? title,
    String? description,
    List<String>? tags,
    List<String>? links,
    bool? aiProcessed,
    AiMetaData? aiMetadata,
    List<String>? collectionIds,
    bool? isDeleted,
    DateTime? reminderTime,
    String? reminderText,
    String? notes,
  }) {
    return Screenshot(
      id: id,
      path: path,
      bytes: bytes,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      links: links ?? this.links,
      collectionIds: collectionIds ?? this.collectionIds,
      aiProcessed: aiProcessed ?? this.aiProcessed,
      addedOn: addedOn,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      fileSize: fileSize,
      isDeleted: isDeleted ?? this.isDeleted,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderText: reminderText ?? this.reminderText,
      notes: notes ?? this.notes,
    );
  }

  void removeReminder() {
    reminderTime = null;
    reminderText = null;
  }

  void setReminder(DateTime time, {String? text}) {
    reminderTime = time;
    reminderText = text;
  }
}
