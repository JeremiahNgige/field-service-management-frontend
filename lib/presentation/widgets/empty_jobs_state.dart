import 'package:flutter/material.dart';

/// Slick animated empty/error state shown when no jobs are available.
class EmptyJobsState extends StatefulWidget {
  const EmptyJobsState({
    super.key,
    this.message = 'No jobs found',
    this.subtitle = 'Pull down to refresh or check back later.',
    this.icon = Icons.work_off_outlined,
    this.onRetry,
  });

  final String message;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  State<EmptyJobsState> createState() => _EmptyJobsStateState();
}

class _EmptyJobsStateState extends State<EmptyJobsState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounceAnim.value),
                child: child,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.grey.shade800
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  widget.icon,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
