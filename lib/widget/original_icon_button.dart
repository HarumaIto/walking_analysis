import 'package:flutter/material.dart';

class OriginalIconButton extends StatelessWidget {
  final Widget text;
  final Function()? onPressed;
  final IconData icon;

  OriginalIconButton({
    required this.icon,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> _children = [
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 4,
        ),
        child: Icon(icon, color: Colors.orange),
      ),
      text,
    ];

    return Column(children: _children,);
  }
}