import 'package:flutter/material.dart';
import 'package:expense_tracker/models/category/category.dart';

final List<Category> defaultCategories = [
  Category(
    name: 'Food',
    iconCodePoint: Icons.lunch_dining.codePoint,
    isDefault: true,
  ),
  Category(
    name: 'Transport',
    iconCodePoint: Icons.emoji_transportation.codePoint,
    isDefault: true,
  ),
  Category(
    name: 'Health',
    iconCodePoint: Icons.medication.codePoint,
    isDefault: true,
  ),
  Category(
    name: 'Leisure',
    iconCodePoint: Icons.movie.codePoint,
    isDefault: true,
  ),
];
