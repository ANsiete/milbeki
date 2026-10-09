import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/money.dart';

// Shows a Money value. Every screen uses this, so amounts always look the same.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.alwaysShowDecimals = false,
    this.colorNegative = true,
  });

  final Money amount;
  final TextStyle? style;
  final bool alwaysShowDecimals;

  /// Negative amounts turn red when true.
  final bool colorNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyLarge;
    final color =
        (colorNegative && amount.isNegative) ? theme.colorScheme.error : base?.color;

    return Text(
      amount.format(alwaysShowDecimals: alwaysShowDecimals),
      style: base?.copyWith(color: color),
    );
  }
}