import 'package:flutter/material.dart';

enum OptionType { color, size }

class SelectionOptions extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String) onOptionSelected;
  final OptionType optionType;

  const SelectionOptions({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
    required this.optionType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selectedOption == option;

              if (optionType == OptionType.color) {
                return _buildColorOption(option, isSelected);
              } else {
                return _buildSizeOption(option, isSelected);
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(String color, bool isSelected) {
    // Map color names to actual colors
    final colorMap = {
      "PINK": Colors.pink[300],
      "YELLOW": Colors.yellow[600],
      "GREEN": Colors.green,
      "RED": Colors.red,
      "BLUE": Colors.blue,
      "BLACK": Colors.black,
    };

    final actualColor = colorMap[color] ?? Colors.grey;

    return GestureDetector(
      onTap: () => onOptionSelected(color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: actualColor?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF2ED573) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: actualColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              color,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2ED573) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String size, bool isSelected) {
    return GestureDetector(
      onTap: () => onOptionSelected(size),
      child: Container(
        width: 55,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2ED573) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ED573)
                : const Color(0xFFDDDDDD),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
