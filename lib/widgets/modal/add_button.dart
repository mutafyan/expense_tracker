import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  const AddButton({required this.onPress, super.key});
  final void Function() onPress;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70.0,
      width: 70.0,
      child: FloatingActionButton(
        onPressed: onPress,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.add,
          size: 36.0,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
