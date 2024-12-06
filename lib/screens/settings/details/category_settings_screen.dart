// lib/screens/settings/category_settings_screen.dart
import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/widgets/category_manager/add_category_modal.dart';
import 'package:flutter/material.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await dbHelper.getAllCategories(includeHidden: true);
    setState(() {
      _categories = categories;
    });
  }

  void _toggleVisibility(Category category) async {
    // Prevent hiding all default categories if necessary
    if (category.isDefault &&
        _categories.where((cat) => cat.isDefault && cat.isVisible).length ==
            1 &&
        category.isVisible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("At least one default category must be visible.")),
      );
      return;
    }

    final updatedCategory = Category(
      id: category.id,
      name: category.name,
      iconCodePoint: category.iconCodePoint,
      isDefault: category.isDefault,
      isVisible: !category.isVisible,
    );

    await dbHelper.updateCategory(updatedCategory);
    await _loadCategories();
  }

  void _deleteCategory(Category category) async {
    if (category.isDefault) return; // Prevent deletion of default categories

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}" Category?'),
        content: const Text(
            'Are you sure you want to delete this category? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await dbHelper.deleteCategory(category.id);
    await _loadCategories();
  }

  void _openAddCategoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddCategoryModal(
        onCategoryAdded: () async {
          await _loadCategories();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Manage Categories"),
        ),
        body: _categories.isEmpty
            ? const Center(child: Text("No categories available."))
            : ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    leading: Icon(
                      IconData(category.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(category.name),
                    subtitle: category.isDefault
                        ? const Text('Default Category')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Visibility Toggle
                        Switch(
                          value: category.isVisible,
                          onChanged: (value) => _toggleVisibility(category),
                        ),
                        // Delete Button for non-default categories
                        if (!category.isDefault)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(category),
                          ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddCategoryModal,
          child: const Icon(Icons.add),
          tooltip: 'Add Category',
        ));
  }
}
