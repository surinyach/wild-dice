import 'dart:math';
import 'dart:typed_data';

import 'package:challenge_app/core/assets/app_assets.dart';
import 'package:challenge_app/features/challenges/data/local_challenge_repository.dart';
import 'package:challenge_app/services/firebase_auth_service.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedRandom extends Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value % max;
  @override
  bool nextBool() => value.isOdd;
  @override
  double nextDouble() => 0;
}

class _ChallengesBundle extends CachingAssetBundle {
  _ChallengesBundle(this.json);
  final String json;
  @override
  Future<ByteData> load(String key) async => ByteData.view(Uint8List.fromList(
    (key == AppAssets.challenges ? json : '').codeUnits,
  ).buffer);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const uid = 'host';
  const data = '''[
    {"id":"n","text":"normal","type":"normal"},
    {"id":"w","text":"wild","type":"wild"},
    {"id":"p","text":"pvp","type":"pvp"}
  ]''';

  Future<GameService> makeService(FakeFirebaseFirestore firestore, int pick) async =>
      GameService(
        firestore: firestore,
        random: _FixedRandom(pick),
        authService: FirebaseAuthService(
          auth: MockFirebaseAuth(
            mockUser: MockUser(uid: uid, isAnonymous: true),
            signedIn: true,
          ),
        ),
        challengeRepository: LocalChallengeRepository(
          assetBundle: _ChallengesBundle(data),
        ),
      );

  test('writes a valid complete normal round in a single game update', () async {
    final firestore = FakeFirebaseFirestore();
    final service = await makeService(firestore, 0);
    final game = await service.createGame(nickname: 'Host', avatarId: 'a');
    await service.startGame(game.id);

    final result = await service.generateRound(game.id);

    expect(result.currentRound, 2);
    expect(result.selectedChallengeType.name, 'normal');
    expect(result.selectedPlayerUids, [uid]);
    expect(result.selectedChallengeId, 'n');
    final stored = (await firestore.collection('games').doc(game.id).get()).data()!;
    expect(stored[GameService.selectedChallengeTypeField], 'normal');
    expect(stored[GameService.selectedPlayerUidsField], [uid]);
    expect(stored[GameService.selectedChallengeIdField], 'n');
  });

  test('pvp uses two different game participants', () async {
    final firestore = FakeFirebaseFirestore();
    final service = await makeService(firestore, 2);
    final game = await service.createGame(nickname: 'Host', avatarId: 'a');
    await firestore.collection('games').doc(game.id).collection('players').doc('guest').set({
      'ownerUid': 'guest', 'nickname': 'Guest', 'avatarId': 'b', 'score': 0, 'number': 2,
    });
    await service.startGame(game.id);

    final result = await service.generateRound(game.id);

    expect(result.selectedChallengeType.name, 'pvp');
    expect(result.selectedPlayerUids, hasLength(2));
    expect(result.selectedPlayerUids.toSet(), {'host', 'guest'});
    expect(result.selectedChallengeId, 'p');
  });

  test('wild selects exactly one participant and a wild challenge', () async {
    final firestore = FakeFirebaseFirestore();
    final service = await makeService(firestore, 1);
    final game = await service.createGame(nickname: 'Host', avatarId: 'a');
    await service.startGame(game.id);

    final result = await service.generateRound(game.id);

    expect(result.selectedChallengeType.name, 'wild');
    expect(result.selectedPlayerUids, [uid]);
    expect(result.selectedChallengeId, 'w');
  });

  test('pvp fails with fewer than two participants', () async {
    final firestore = FakeFirebaseFirestore();
    final service = await makeService(firestore, 2);
    final game = await service.createGame(nickname: 'Host', avatarId: 'a');
    await service.startGame(game.id);

    await expectLater(
      service.generateRound(game.id),
      throwsA(isA<GameServiceException>()),
    );
    final stored = (await firestore.collection('games').doc(game.id).get()).data()!;
    expect(stored[GameService.currentRoundField], 1);
    expect(stored[GameService.selectedChallengeTypeField], isNull);
  });

  test('missing games and empty participant lists fail', () async {
    final firestore = FakeFirebaseFirestore();
    final service = await makeService(firestore, 0);
    await expectLater(service.generateRound('missing'), throwsA(isA<GameServiceException>()));
    final gameRef = firestore.collection('games').doc('empty');
    await gameRef.set({
      'code': 'EMPTY', 'status': 'in_progress', 'hostUid': 'host',
      'currentRound': 1, 'totalRounds': 5,
    });
    await expectLater(service.generateRound('empty'), throwsA(isA<GameServiceException>()));
  });

  test('fails when selected type has no valid local challenge', () async {
    final firestore = FakeFirebaseFirestore();
    final service = GameService(
      firestore: firestore,
      random: _FixedRandom(0),
      authService: FirebaseAuthService(
        auth: MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
      ),
      challengeRepository: LocalChallengeRepository(
        assetBundle: _ChallengesBundle('[{"id":"w","text":"x","type":"wild"}]'),
      ),
    );
    final game = await service.createGame(nickname: 'Host', avatarId: 'a');
    await service.startGame(game.id);
    await expectLater(service.generateRound(game.id), throwsA(isA<GameServiceException>()));
    expect((await firestore.collection('games').doc(game.id).get()).data()![GameService.currentRoundField], 1);
  });
}
