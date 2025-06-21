import 'package:flutter/material.dart';

class ModeControls extends StatelessWidget {
  const ModeControls({
    super.key,
    required this.modes,
    required this.currentMode,
  });

  final List modes;
  final String currentMode;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: modes.map((mode) {
              final isActive = mode == currentMode;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  mode.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.yellow : Colors.white70,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: isActive ? 18 : 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
