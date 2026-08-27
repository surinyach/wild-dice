import 'package:challenge_app/core/assets/app_assets.dart';
import 'package:challenge_app/features/challenges/data/local_challenge_repository.dart';
import 'package:challenge_app/features/challenges/domain/challenge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all registered avatar assets can be loaded', () async {
    expect(AppAssets.avatars.keys, [
      'avatar_01',
      'avatar_02',
      'avatar_03',
      'avatar_04',
      'avatar_05',
      'avatar_06',
      'avatar_07',
      'avatar_08',
      'avatar_09',
      'avatar_10',
    ]);

    for (final assetPath in AppAssets.avatars.values) {
      final avatar = await rootBundle.load(assetPath);
      expect(avatar.lengthInBytes, greaterThan(0), reason: assetPath);
    }
  });

  test('bundled challenges can be loaded and parsed', () async {
    final challenges = await LocalChallengeRepository().loadChallenges();

    expect(challenges, hasLength(3));
    expect(challenges.map((challenge) => challenge.id), [
      'challenge_001',
      'challenge_002',
      'challenge_003',
    ]);
    expect(
      challenges.map((challenge) => challenge.type).toSet(),
      ChallengeType.values.toSet(),
    );
  });

  test('unknown challenge types are rejected', () {
    expect(
      () => Challenge.fromJson({
        'id': 'challenge_999',
        'text': 'Unsupported challenge',
        'type': 'unknown',
      }),
      throwsFormatException,
    );
  });
}
