import 'package:flutter/material.dart';

import '../../../core/theme/ops_theme.dart';

class ChartCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isLive;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    this.isLive = false,
    required this.child,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 600;
    final veryCompact = width < 420;

    return Container(
      height: compact ? 250 : 300,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: OpsColors.primary,
                      size: compact ? 16 : 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w800,
                          color: OpsColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isLive && _pulseController != null) ...[
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: OpsColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: OpsColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: OpsColors.danger,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: OpsColors.danger.withValues(
                                      alpha:
                                          0.5 + _pulseController!.value * 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          if (!veryCompact) const SizedBox(width: 5),
                          if (!veryCompact)
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: OpsColors.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }
}
