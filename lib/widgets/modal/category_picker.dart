import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:flutter/material.dart';

class CategoryPicker extends StatefulWidget {
  const CategoryPicker({
    required this.selectedCategory,
    required this.onChange,
    super.key,
  });

  final Category? selectedCategory;
  final void Function(Category?) onChange;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture =
        DatabaseHelper.instance.getAllCategories(includeHidden: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading categories: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No categories available');
        } else {
          final categories = snapshot.data!;
          return DropdownButtonFormField<Category>(
            hint: const Text("Select Category"),
            value: widget.selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Category",
            ),
            items: categories.map((Category category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      IconData(
                        category.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category.name[0].toUpperCase() +
                          category.name.substring(1),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.onChange,
          );
        }
      },
    );
  }
}
