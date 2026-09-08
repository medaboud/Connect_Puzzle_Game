import 'package:flutter/foundation.dart';

@immutable
class UserPreferences {
  final bool hapticsEnabled;
  final bool tapToExtend;
  final bool reducedMotion;
  final bool? isDarkMode; // null = system default

  const UserPreferences({
    this.hapticsEnabled = true,
    this.tapToExtend = true,
    this.reducedMotion = false,
    this.isDarkMode,
  });

  UserPreferences copyWith({
    bool? hapticsEnabled,
    bool? tapToExtend,
    bool? reducedMotion,
    bool? isDarkMode,
    bool clearDarkMode = false,
  }) {
    return UserPreferences(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      tapToExtend: tapToExtend ?? this.tapToExtend,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      isDarkMode: clearDarkMode ? null : (isDarkMode ?? this.isDarkMode),
    );
  }

  Map<String, dynamic> toJson() => {
    'hapticsEnabled': hapticsEnabled,
    'tapToExtend': tapToExtend,
    'reducedMotion': reducedMotion,
    'isDarkMode': isDarkMode,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      tapToExtend: json['tapToExtend'] as bool? ?? true,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      isDarkMode: json['isDarkMode'] as bool?,
    );
  }
}
