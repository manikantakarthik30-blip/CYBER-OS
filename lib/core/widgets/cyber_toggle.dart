import 'package:flutter/material.dart';
import '../animations/animation_constants.dart';
import '../theme/app_colors.dart';

class CyberToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CyberToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: AnimDuration.fast,
          curve: AnimCurve.sharp,
          width: 44,
          height: 22,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? AppColors.signal_dim : AppColors.surface,
            border: Border.all(
              color: value ? AppColors.signal : AppColors.text_ghost,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: AppColors.signal.withOpacity(0.25),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: AnimatedAlign(
            duration: AnimDuration.fast,
            curve: AnimCurve.sharp,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? AppColors.signal : AppColors.text_secondary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
