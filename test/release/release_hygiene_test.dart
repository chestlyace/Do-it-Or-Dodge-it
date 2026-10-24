import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/model_recommender.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/services/notification_gateway.dart';

String read(String path) => File(path).readAsStringSync();

/// Names of the packages listed under `dependencies:` and `dev_dependencies:`.
List<String> pubspecPackages() {
  final names = <String>[];
  var inSection = false;
  for (final line in read('pubspec.yaml').split('\n')) {
    if (line.startsWith('dependencies:') ||
        line.startsWith('dev_dependencies:')) {
      inSection = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      inSection = false;
    }
    final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
    if (inSection && match != null) names.add(match.group(1)!);
  }
  return names;
}

void main() {
  const res = 'android/app/src/main/res';

  group('Android manifest', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    test('the app has its real name', () {
      expect(manifest, contains('android:label="Do It or Dodge It"'));
    });

    test('release builds can download the model', () {
      expect(manifest, contains('android.permission.INTERNET'));
    });

    test('has what nudges and the model download need', () {
      for (final permission in [
        'POST_NOTIFICATIONS',
        'RECEIVE_BOOT_COMPLETED',
        'FOREGROUND_SERVICE_DATA_SYNC',
        'ACCESS_NETWORK_STATE',
      ]) {
        expect(manifest, contains('android.permission.$permission'));
      }
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
    });

    test('asks for nothing it does not use', () {
      for (final permission in [
        'READ_CONTACTS',
        'READ_CALENDAR',
        'RECORD_AUDIO',
        'ACCESS_FINE_LOCATION',
        'SCHEDULE_EXACT_ALARM',
        'USE_EXACT_ALARM',
        'CAMERA',
      ]) {
        expect(manifest, isNot(contains(permission)));
      }
    });

    test('is not debuggable', () {
      expect(manifest, isNot(contains('android:debuggable')));
    });
  });

  group('release signing', () {
    final gradle = read('android/app/build.gradle.kts');

    test('reads the key from key.properties, never from the source', () {
      expect(gradle, contains('key.properties'));
      expect(gradle, contains('hasReleaseKey'));
      expect(gradle, isNot(contains('storePassword = "')));
      expect(gradle, isNot(contains('keyPassword = "')));
    });

    test('warns before falling back to the debug key', () {
      expect(gradle, contains('with the debug key'));
    });

    test('supports Android 11 and newer on 64-bit ARM only', () {
      expect(gradle, contains('minSdk = 30'));
      expect(gradle, contains('arm64-v8a'));
    });

    test('is not shrunk, so nothing can be stripped untested', () {
      expect(gradle, contains('isMinifyEnabled = false'));
      expect(gradle, contains('isShrinkResources = false'));
    });

    test('keys and keystores are ignored by git', () {
      final ignore = read('android/.gitignore');
      for (final pattern in ['key.properties', '*.jks', '*.keystore']) {
        expect(ignore, contains(pattern));
      }
    });

    test('the key template has placeholders, not real values', () {
      final example = read('android/key.properties.example');
      expect(example, contains('storePassword=CHANGE_ME'));
      expect(example, contains('keyPassword=CHANGE_ME'));
    });

    test('the build script refuses to run without a key and builds arm64', () {
      final script = read('scripts/build_release.sh');
      expect(script, contains('android/key.properties'));
      expect(script, contains('exit 1'));
      expect(script, contains('--target-platform android-arm64'));
      expect(script, contains('flutter analyze'));
      expect(script, contains('flutter test'));
      expect(script, contains('sha256sum'));
      // Executable by its owner.
      expect(
        File('scripts/build_release.sh').statSync().mode & 0x40,
        isNonZero,
      );
    });
  });

  group('icons', () {
    test('the launcher icon is an adaptive icon with a themed variant', () {
      final icon = read('$res/mipmap-anydpi-v26/ic_launcher.xml');
      expect(icon, contains('<adaptive-icon'));
      expect(icon, contains('<background'));
      expect(icon, contains('<foreground'));
      expect(icon, contains('<monochrome'));
    });

    test('everything the launcher icon points at exists', () {
      expect(
        File('$res/drawable/ic_launcher_foreground.xml').existsSync(),
        isTrue,
      );
      expect(
        read('$res/values/ic_launcher_background.xml'),
        contains('ic_launcher_background'),
      );
    });

    test(
      'the foreground stays inside the 66dp safe zone of the 108dp canvas',
      () {
        final foreground = read('$res/drawable/ic_launcher_foreground.xml');
        final path = RegExp(r'pathData="([^"]+)"')
            .firstMatch(foreground)!
            .group(1)!;
        final numbers = RegExp(r'-?\d+(\.\d+)?')
            .allMatches(path)
            .map((m) => double.parse(m.group(0)!))
            .toList();
        for (final n in numbers) {
          expect(n, inInclusiveRange(21, 87), reason: 'coordinate $n');
        }
      },
    );

    test('nudges use a white status bar icon that exists', () {
      expect(nudgeNotificationIcon, 'ic_stat_nudge');
      final icon = read('$res/drawable/$nudgeNotificationIcon.xml');
      expect(icon, contains('#FFFFFF'));
      expect(icon, isNot(contains('mipmap')));
    });

    test('the icons are kept if shrinking is ever turned on', () {
      final keep = read('$res/raw/keep.xml');
      expect(keep, contains('ic_stat_nudge'));
      expect(keep, contains('ic_launcher'));
    });
  });

  group('licences and credits', () {
    final readme = read('README.md');

    test('the repo is MIT licensed', () {
      final licence = read('LICENSE');
      expect(licence, startsWith('MIT License'));
      expect(licence, contains('Copyright (c) 2026'));
      expect(readme, contains('MIT licence'));
    });

    test('the README says where the model comes from and its licence', () {
      expect(readme, contains('Apache 2.0'));
      expect(readme, contains('Hugging Face'));
      expect(readme, contains('does not bundle a model'));
      expect(readme, contains('litert-community'));
    });

    test('the README sizes and repositories match the code', () {
      for (final option in GemmaModelOption.all) {
        expect(
          readme,
          contains(formatBytes(option.sizeBytes).replaceFirst(' GB', ' GB')),
        );
        final repo = RegExp(r'litert-community/([^/]+)/')
            .firstMatch(option.url)!
            .group(1)!;
        expect(readme, contains(repo));
      }
      expect(readme, contains('SHA-256'));
    });

    test('every package the app uses is credited', () {
      final missing = [
        for (final name in pubspecPackages())
          if (name != 'flutter' &&
              name != 'flutter_test' &&
              !readme.contains(name))
            name,
      ];
      expect(missing, isEmpty, reason: 'not credited in the README: $missing');
    });

    test(
      'the README covers install, build, privacy and the challenge notes',
      () {
        for (final heading in [
          '## Install',
          '## Build from source',
          '### Release build',
          '## Privacy',
          '## Challenge notes',
          '## Credits',
          '## Licence',
        ]) {
          expect(readme, contains(heading));
        }
        expect(readme, contains('23 October 2026'));
        expect(readme, contains('Commits made after the challenge deadline'));
      },
    );

    test('the README promises only what the manifest allows', () {
      expect(
        readme,
        contains('never reads your contacts, calendar, microphone or location'),
      );
    });
  });

  group('release documents', () {
    test(
      'the release guide covers the key, build, signature check and release',
      () {
        final guide = read('docs/RELEASING.md');
        for (final part in [
          'keytool -genkeypair',
          'key.properties',
          'scripts/build_release.sh',
          'apksigner verify --print-certs',
          'adb install',
          'gh release create',
          'airplane mode',
        ]) {
          expect(guide, contains(part));
        }
      },
    );

    test('the release notes leave a checksum to fill in', () {
      final notes = read('docs/release-notes-v1.0.0.md');
      expect(notes, contains('SHA-256'));
      expect(notes, contains('Android 11'));
    });

    test('the demo script shows airplane mode and both buttons', () {
      final script = read('docs/demo-script.md');
      expect(script, contains('airplane mode'));
      expect(script, contains('**Do It**'));
      expect(script, contains('**Dodge It**'));
    });

    test('the DEV post is an unpublished draft with its gaps marked', () {
      final post = read('docs/dev-post.md');
      expect(post, contains('published: false'));
      expect(post, contains('hf26challenge'));
      expect(post, contains('Best Use of Gemma'));
      expect(post, contains('[['));
      // Claims that were checked against the code.
      expect(post, contains('first one always takes under two minutes'));
      expect(post, contains('Apache 2.0'));
    });
  });

  group('no secrets', () {
    test('no Hugging Face token or password is in the tracked sources', () {
      final tokens = RegExp(r'hf_[A-Za-z0-9]{20,}');
      final files = [
        for (final dir in ['lib', 'docs', 'scripts', 'android/app/src'])
          ...Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (f) => !f.path.endsWith('.png') && !f.path.endsWith('.webp'),
              ),
        File('README.md'),
        File('pubspec.yaml'),
      ];
      for (final file in files) {
        expect(
          tokens.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    });
  });

  test('the app version is set', () {
    expect(read('pubspec.yaml'), contains('version: 1.0.0+1'));
    expect(read('pubspec.yaml'), isNot(contains('A new Flutter project')));
  });
}
