// lib/features/product/presentation/widgets/home/flash_sale_badge.dart

import 'dart:async';
import 'package:flutter/material.dart';

class FlashSaleBadge extends StatefulWidget {
  final DateTime endTime;

  const FlashSaleBadge({super.key, required this.endTime});

  @override
  State<FlashSaleBadge> createState() => _FlashSaleBadgeState();
}

class _FlashSaleBadgeState extends State<FlashSaleBadge> {
  Timer? _timer;
  Duration? _remaining;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    print('🟢 FlashSaleBadge INIT #${_tickCount}');
    _calculateAndStart();
  }

  @override
  void dispose() {
    print('🔴 FlashSaleBadge DISPOSE - Ticks: $_tickCount');
    _timer?.cancel();
    super.dispose();
  }

  void _calculateAndStart() {
    // Calculate initial remaining time
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);

    print(
      '⏰ FlashSaleBadge: EndTime=${widget.endTime}, Now=$now, Remaining=${remaining.inSeconds}s',
    );

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      _remaining = Duration.zero;
      return; // Don't start timer if already expired
    }

    _remaining = remaining;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickCount++;

      if (!mounted) {
        print('❌ Timer tick #$_tickCount - NOT MOUNTED');
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final remaining = widget.endTime.difference(now);

      print('⏱️ Timer tick #$_tickCount - Remaining: ${remaining.inSeconds}s');

      if (remaining.isNegative || remaining.inSeconds <= 0) {
        print('⏰ EXPIRED! Cancelling timer');
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'ENDED';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) return '${days}d ${hours}h ${minutes}m ${seconds}s';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _remaining != null && _remaining!.inSeconds > 0
        ? _formatDuration(_remaining!)
        : 'ENDED';

    print('🏗️ BUILD: $displayText');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _remaining != null && _remaining!.inSeconds > 0
            ? Colors.orange.withOpacity(0.95)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _remaining != null && _remaining!.inSeconds > 0
                ? Icons.flash_on
                : Icons.timer_off,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
