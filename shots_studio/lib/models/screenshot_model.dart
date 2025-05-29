import 'dart:typed_data';
import 'dart:convert';
import 'package:shots_studio/models/gemini_model.dart';
import 'package:shots_studio/models/collection_model.dart';

class Screenshot {
  String id;
  String? path; // For mobile (file path)
  Uint8List? bytes; // For web (image bytes)
  String? title;
  String? description;
  List<String> tags;
  List<String> collectionIds;
  bool aiProcessed;
  DateTime addedOn;
  AiMetaData? aiMetadata;
  int? fileSize;
  bool isDeleted;

  Screenshot({
    required this.id,
    this.path,
    this.bytes,
    this.title,
    this.description,
    required this.tags,
    List<String>? collectionIds,
    required this.aiProcessed,
    required this.addedOn,
    this.aiMetadata,
    this.fileSize,
    this.isDeleted = false,
  }) : collectionIds = collectionIds ?? [];

  void addToCollections(List<String> collections) {
    collectionIds.addAll(
      collections.where((id) => !collectionIds.contains(id)),
    );
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
      'collectionIds': collectionIds,
      'aiProcessed': aiProcessed,
      'addedOn': addedOn.toIso8601String(),
      'aiMetadata': aiMetadata?.toJson(),
      'fileSize': fileSize,
      'isDeleted': isDeleted,
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
      collectionIds: List<String>.from(json['collectionIds'] as List<dynamic>),
      aiProcessed: json['aiProcessed'] as bool,
      addedOn: DateTime.parse(json['addedOn'] as String),
      aiMetadata:
          json['aiMetadata'] != null
              ? AiMetaData.fromJson(json['aiMetadata'] as Map<String, dynamic>)
              : null,
      fileSize: json['fileSize'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
