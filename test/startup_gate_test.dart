import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/features/splash/startup_gate.dart';

/// Remote Config's maintenance_mode and min_app_version stop the app at the
/// splash screen (02 C: they were never read).
void main() {
  group('isVersionBelow', () {
    test('no minimum set blocks nothing', () {
      expect(isVersionBelow('1.0.0', ''), isFalse);
      expect(isVersionBelow('1.0.0', '   '), isFalse);
    });
    test('an older version is below the minimum', () {
      expect(isVersionBelow('1.0.0', '1.0.1'), isTrue);
      expect(isVersionBelow('1.0.9', '1.1.0'), isTrue);
      expect(isVersionBelow('1.9.9', '2.0.0'), isTrue);
    });
    test('the same or a newer version is not', () {
      expect(isVersionBelow('1.0.0', '1.0.0'), isFalse);
      expect(isVersionBelow('1.2.10', '1.2.9'), isFalse);
      expect(isVersionBelow('2.0.0', '1.9.9'), isFalse);
    });
    test('missing parts count as 0, and a build number is ignored', () {
      expect(isVersionBelow('1.0', '1.0.0'), isFalse);
      expect(isVersionBelow('1.0.0', '1.0'), isFalse);
      expect(isVersionBelow('1.0.0+7', '1.0.0+9'), isFalse);
    });
    test('an unreadable minimum blocks nothing', () {
      expect(isVersionBelow('1.0.0', 'abc'), isFalse);
      expect(isVersionBelow('1.0.0', '1.x'), isFalse);
    });
  });

  group('startupBlockFor', () {
    test('starts normally by default', () {
      expect(startupBlockFor(maintenanceMode: false, minAppVersion: '', appVersion: '1.0.0'), isNull);
    });
    test('maintenance stops the app', () {
      expect(startupBlockFor(maintenanceMode: true, minAppVersion: '', appVersion: '1.0.0'),
          StartupBlock.maintenance);
    });
    test('a version below the minimum must update', () {
      expect(startupBlockFor(maintenanceMode: false, minAppVersion: '1.1.0', appVersion: '1.0.0'),
          StartupBlock.updateRequired);
    });
    test('maintenance comes before an update', () {
      expect(startupBlockFor(maintenanceMode: true, minAppVersion: '9.0.0', appVersion: '1.0.0'),
          StartupBlock.maintenance);
    });
  });

  test('AppConstants.appVersion is the version in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final version = line.substring('version:'.length).trim().split('+').first;
    expect(AppConstants.appVersion, version);
  });
}
