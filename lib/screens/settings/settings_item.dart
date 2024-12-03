import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    required this.settingName,
    required this.icon,
    required this.onPress,
    this.subtitle = '',
  });

  final String settingName, subtitle;
  final IconData icon;
  final Function(BuildContext) onPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onPress(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border.all(
        color: Colors.black45,
        width: 1,
        style: BorderStyle.solid,
      ),
      subtitle: Text(subtitle),
      leading: Icon(icon),
      title: Text(
        settingName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded),
    );
  }
}
