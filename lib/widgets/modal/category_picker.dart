import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.selectedCategory,
    required this.onChange,
    super.key,
  });
  final void Function(dynamic) onChange;
  final Category? selectedCategory;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Category>(
      hint: const Text("Select Category"),
      value: selectedCategory,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Category",
      ),
      items: Category.values
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(categoryIcons[category]),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    category.name[0].toUpperCase() + category.name.substring(1),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChange,
    );
  }
}
