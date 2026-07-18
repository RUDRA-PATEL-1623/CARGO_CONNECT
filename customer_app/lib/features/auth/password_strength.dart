import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength.level;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 6,
                margin: EdgeInsets.only(right: index == 3 ? 0 : AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isActive ? strength.color : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(strength.icon, size: 16, color: strength.color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              strength.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: strength.color),
            ),
          ],
        ),
      ],
    );
  }
}

class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRule.evaluate(password);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password rules', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final rule in rules) ...[
            _PasswordRuleRow(rule: rule),
            if (rule != rules.last) const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _PasswordRuleRow extends StatelessWidget {
  const _PasswordRuleRow({required this.rule});

  final PasswordRule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.isMet ? AppColors.success : AppColors.textSecondary;

    return Row(
      children: [
        Icon(
          rule.isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: color,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            rule.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: rule.isMet ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordRule {
  const PasswordRule({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  static List<PasswordRule> evaluate(String password) {
    return [
      PasswordRule(label: 'At least 8 characters', isMet: password.length >= 8),
      PasswordRule(
        label: 'One uppercase letter',
        isMet: RegExp(r'[A-Z]').hasMatch(password),
      ),
      PasswordRule(
        label: 'One lowercase letter',
        isMet: RegExp(r'[a-z]').hasMatch(password),
      ),
      PasswordRule(
        label: 'One number',
        isMet: RegExp(r'[0-9]').hasMatch(password),
      ),
      PasswordRule(
        label: 'One symbol',
        isMet: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
      ),
    ];
  }
}

class PasswordStrength {
  const PasswordStrength({
    required this.level,
    required this.label,
    required this.color,
    required this.icon,
    required this.isValid,
  });

  final int level;
  final String label;
  final Color color;
  final IconData icon;
  final bool isValid;

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        level: 0,
        label: 'Use 8+ chars with upper, lower, number, and symbol',
        color: AppColors.textSecondary,
        icon: Icons.info_outline_rounded,
        isValid: false,
      );
    }

    final rules = PasswordRule.evaluate(password);
    final passed = rules.where((rule) => rule.isMet).length;
    final allPassed = passed == rules.length;

    if (passed <= 2) {
      return const PasswordStrength(
        level: 1,
        label: 'Weak password',
        color: AppColors.danger,
        icon: Icons.warning_amber_rounded,
        isValid: false,
      );
    }
    if (!allPassed) {
      return const PasswordStrength(
        level: 3,
        label: 'Complete the remaining requirements',
        color: AppColors.warning,
        icon: Icons.shield_outlined,
        isValid: false,
      );
    }
    return const PasswordStrength(
      level: 4,
      label: 'Strong password',
      color: AppColors.success,
      icon: Icons.verified_user_outlined,
      isValid: true,
    );
  }
}
