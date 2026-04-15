part of 'extension_module.dart';

extension ColorUtil on Color {
  String get hex {
    String color;
    String a = (this.a * 255.0).round().clamp(0, 255).toRadixString(16);
    String r = (this.r * 255.0).round().clamp(0, 255).toRadixString(16);
    String g = (this.g * 255.0).round().clamp(0, 255).toRadixString(16);
    String b = (this.b * 255.0).round().clamp(0, 255).toRadixString(16);
    color = '#$a$r$g$b';
    return color;
  }
}