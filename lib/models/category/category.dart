// lib/models/category.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final bool isDefault;
  final bool isVisible;

  Category({
    String? id,
    required this.name,
    required this.iconCodePoint,
    this.isDefault = false,
    this.isVisible = true,
  }) : id = id ?? uuid.v4();

  // Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'isDefault': isDefault ? 1 : 0,
      'isVisible': isVisible ? 1 : 0,
    };
  }

  // Deserialize from Map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      isDefault: map['isDefault'] == 1,
      isVisible: map['isVisible'] == 1,
    );
  }
}
