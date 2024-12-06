import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:flutter/material.dart';

class AddCategoryModal extends StatefulWidget {
  final VoidCallback onCategoryAdded;

  const AddCategoryModal({super.key, required this.onCategoryAdded});

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  IconData _selectedIcon = Icons.category;
  final dbHelper = DatabaseHelper.instance;

  // Define a list of icons for selection
  final List<IconData> _availableIcons = [
    Icons.fastfood,
    Icons.directions_car,
    Icons.health_and_safety,
    Icons.movie,
    Icons.shopping_cart,
    Icons.pets,
    Icons.book,
    Icons.music_note,
    Icons.fitness_center,
    Icons.sports_soccer,
    // Add more icons as needed
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newCategory = Category(
      name: _name,
      iconCodePoint: _selectedIcon.codePoint,
      isDefault: false,
      isVisible: true,
    );

    await dbHelper.insertCategory(newCategory);
    widget.onCategoryAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Add New Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Category Name
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Category Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Icon Selection
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Icon',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableIcons.map((iconData) {
                        return ChoiceChip(
                          label: Icon(iconData),
                          selected: _selectedIcon == iconData,
                          onSelected: (selected) {
                            setState(() {
                              _selectedIcon = iconData;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Category'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
