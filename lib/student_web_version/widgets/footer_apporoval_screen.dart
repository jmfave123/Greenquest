import 'package:flutter/material.dart';

Text footerText(String text, TextStyle? style) {
  return Text(
    text,
    style: style ?? const TextStyle(fontSize: 16, color: Colors.black54),
    textAlign: TextAlign.center,
  );
}
