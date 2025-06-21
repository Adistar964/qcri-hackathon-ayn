import 'package:flutter/material.dart';

class MicStatus extends StatelessWidget {
  const MicStatus({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Icon(Icons.mic, color: Colors.white, size: 32),
      ),
    );
  }
}
