import 'package:flutter/material.dart';

/// A styled placeholder for tabs not yet built (Discover, Stats, You).
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 72,
                          color: scheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('Coming soon',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
