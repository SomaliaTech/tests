// lib/features/chat/presentation/widgets/typing_indicator.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

class TypingIndicator extends StatefulWidget {
  final String? partnerImage;
  final String partnerName;

  const TypingIndicator({super.key, this.partnerImage, this.partnerName = ''});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                widget.partnerImage != null && widget.partnerImage!.isNotEmpty
                ? CachedNetworkImageProvider(widget.partnerImage!)
                : null,
            child: widget.partnerImage == null || widget.partnerImage!.isEmpty
                ? Text(
                    widget.partnerName.isNotEmpty
                        ? widget.partnerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF2ED573),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay).clamp(0.0, 1.0);
                    final opacity = (value * 2).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: value > 0.5
                          ? (1.0 - (value - 0.5) * 2).clamp(0.0, 1.0)
                          : opacity,
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ED573),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
