// lib/features/notebook/presentation/widgets/color_picker_widget.dart
import 'package:flutter/material.dart';

class ColorOption {
  final String name;
  final Color color;
  final int? value;

  const ColorOption({required this.name, required this.color, this.value});
}

class ColorPickerWidget extends StatelessWidget {
  final List<ColorOption> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final String title;
  final bool showLabels;

  const ColorPickerWidget({
    Key? key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.title = 'Background Color',
    this.showLabels = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((option) {
            final isSelected = selectedColor == option.color;
            return GestureDetector(
              onTap: () => onColorSelected(option.color),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.blue, size: 20)
                        : null,
                  ),
                  if (showLabels)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
