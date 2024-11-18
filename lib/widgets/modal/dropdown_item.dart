import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';

class DropdownItem extends StatelessWidget {
  const DropdownItem({
    required this.selectedCategory,
    required this.onChange,
    super.key,
  });
  final void Function(dynamic) onChange;
  final Category? selectedCategory;
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      hint: const Text("Category"),
      value: selectedCategory,
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
