import 'package:flutter/material.dart';

class OriginalIconButton extends StatelessWidget {
  final Widget text;
  final bool isRow;
  final Function()? onPressed;
  final IconData icon;

  OriginalIconButton({
    required this.icon,
    required this.onPressed,
    required this.text,
    required this.isRow,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> _children = [
      ElevatedButton(
        onPressed: onPressed,
        child: Icon(icon, color: Colors.orange),
        style: ElevatedButton.styleFrom(
          elevation: 4,
        ),
      ),
      text,
    ];

    return isRow
      ? Row(children: _children,)
      : Column(children: _children,);
  }
}