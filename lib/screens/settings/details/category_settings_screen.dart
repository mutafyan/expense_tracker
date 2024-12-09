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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await dbHelper.getAllCategories(includeHidden: true);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVisibility(Category category) async {
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

    try {
      await dbHelper.updateCategory(updatedCategory);
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category: $e')),
      );
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      // Prevent deletion of default categories
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete a default category.')),
      );
      return;
    }

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

    try {
      await dbHelper.deleteCategory(category.id);
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Category "${category.name}" deleted successfully.')),
      );
    } catch (e) {
      // Display the error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: $e')),
      );
    }
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
    // Determine the number of active categories (isVisible = true)
    final activeCategoriesCount =
        _categories.where((cat) => cat.isVisible).length;
    final isLimitReached = activeCategoriesCount >= 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    // Category List
                    Expanded(
                      child: _categories.isEmpty
                          ? const Center(
                              child: Text("No categories available."),
                            )
                          : ListView.builder(
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return ListTile(
                                  leading: Icon(
                                    IconData(
                                      category.iconCodePoint,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: category.isVisible
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : Colors.grey,
                                  ),
                                  title: Text(category.name),
                                  subtitle: category.isDefault
                                      ? const Text('Default Category')
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Delete Button for non-default categories
                                      if (!category.isDefault)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteCategory(category),
                                        ),
                                      // Visibility Toggle
                                      Switch(
                                        value: category.isVisible,
                                        onChanged: (value) =>
                                            _toggleVisibility(category),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: [
                          isLimitReached
                              ? Text(
                                  'You have reached the maximum of 10 active categories.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  'Maximum 10 active categories allowed',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed:
                                isLimitReached ? null : _openAddCategoryModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Category'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
