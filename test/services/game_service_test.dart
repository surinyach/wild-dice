import 'package:challenge_app/services/firebase_auth_service.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:challenge_app/features/challenges/domain/challenge.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uid = 'anonymous-user-123';

  late FakeFirebaseFirestore firestore;
  late GameService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: uid, isAnonymous: true),
      signedIn: true,
    );
    service = GameService(
      firestore: firestore,
      authService: FirebaseAuthService(auth: auth),
    );
  });

  group('createGame', () {
    test('creates the exact game and host player schema', () async {
      final game = await service.createGame(
        nickname: ' Santi ',
        avatarId: ' avatar_01 ',
        totalRounds: 5,
        code: ' a7k92 ',
      );

      expect(game.code, 'A7K92');
      expect(game.status, GameStatus.lobby);
      expect(game.hostUid, uid);
      expect(game.currentRound, 1);
      expect(game.totalRounds, 5);
      expect(game.selectedChallengeType, isNull);
      expect(game.selectedPlayerUids, isEmpty);
      expect(game.selectedChallengeId, isNull);

      final gameData =
          (await firestore
                  .collection(GameService.gamesCollection)
                  .doc(game.id)
                  .get())
              .data()!;
      expect(gameData.keys, {
        GameService.codeField,
        GameService.statusField,
        GameService.hostUidField,
        GameService.playerOrderField,
        GameService.currentRoundField,
        GameService.totalRoundsField,
        GameService.selectedChallengeTypeField,
        GameService.selectedPlayerUidsField,
        GameService.selectedChallengeIdField,
        GameService.createdAtField,
        GameService.updatedAtField,
      });
      expect(gameData[GameService.statusField], 'lobby');
      expect(gameData[GameService.hostUidField], uid);
      expect(gameData[GameService.playerOrderField], [uid]);
      expect(gameData[GameService.currentRoundField], 1);
      expect(gameData[GameService.selectedChallengeTypeField], isNull);
      expect(gameData[GameService.selectedPlayerUidsField], isEmpty);
      expect(gameData[GameService.selectedChallengeIdField], isNull);

      final hostData =
          (await firestore
                  .collection(GameService.gamesCollection)
                  .doc(game.id)
                  .collection(GameService.playersCollection)
                  .doc(uid)
                  .get())
              .data()!;
      expect(hostData, {
        GameService.ownerUidField: uid,
        GameService.nicknameField: 'Santi',
        GameService.avatarIdField: 'avatar_01',
        GameService.scoreField: 0,
        GameService.numberField: 1,
      });
    });

    test('generates a five-character code when none is supplied', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );

      expect(game.code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{5}$')));
    });

    test('rejects invalid creation input', () async {
      expect(
        () => service.createGame(nickname: '', avatarId: 'avatar_01'),
        throwsA(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
      expect(
        () => service.createGame(
          nickname: 'Host',
          avatarId: 'avatar_01',
          totalRounds: 0,
        ),
        throwsA(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
    });
  });

  group('startGame', () {
    test(
      'updates both realtime listeners and repeated starts are no-ops',
      () async {
        final game = await service.createGame(nickname: 'Host', avatarId: 'a');
        final first = service
            .watchGame(game.id)
            .firstWhere((game) => game?.status == GameStatus.inProgress);
        final second = service
            .watchGame(game.id)
            .firstWhere((game) => game?.status == GameStatus.inProgress);
        await service.startGame(game.id);
        expect((await first)?.status, GameStatus.inProgress);
        expect((await second)?.status, GameStatus.inProgress);
        final reference = firestore.collection('games').doc(game.id);
        final started = (await reference.get()).data();
        await service.startGame(game.id);
        expect((await reference.get()).data(), started);
        expect(started?['currentRound'], 1);
      },
    );

    test('rejects non-host, closed, missing and invalid games', () async {
      final game = await service.createGame(nickname: 'Host', avatarId: 'a');
      final guest = GameService(
        firestore: firestore,
        authService: FirebaseAuthService(
          auth: MockFirebaseAuth(
            mockUser: MockUser(uid: 'guest'),
            signedIn: true,
          ),
        ),
      );
      await expectLater(
        guest.startGame(game.id),
        throwsA(_serviceError(GameServiceErrorCode.notHost)),
      );
      for (final status in [GameStatus.finished, GameStatus.cancelled]) {
        await firestore.collection('games').doc(game.id).update({
          'status': status.value,
        });
        await expectLater(
          service.startGame(game.id),
          throwsA(_serviceError(GameServiceErrorCode.invalidState)),
        );
      }
      await expectLater(
        service.startGame('missing'),
        throwsA(_serviceError(GameServiceErrorCode.gameNotFound)),
      );
      await expectLater(
        service.startGame('bad/id'),
        throwsA(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
    });
  });

  group('findGameByJoinCode', () {
    test('normalizes the code and returns null when absent', () async {
      final created = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
        code: 'A7K92',
      );

      final found = await service.findGameByJoinCode('  a7k92 ');
      expect(found?.id, created.id);
      expect(await service.findGameByJoinCode('XXXXX'), isNull);
    });
  });

  group('joinGame', () {
    for (final status in [
      GameStatus.inProgress,
      GameStatus.finished,
      GameStatus.cancelled,
    ]) {
      test('rejects ${status.value} even after a lobby lookup', () async {
        final game = await service.createGame(
          nickname: 'Host',
          avatarId: 'avatar_01',
          code: 'A7K92',
        );
        expect(
          (await service.findGameByJoinCode('A7K92'))?.status,
          GameStatus.lobby,
        );
        await firestore
            .collection(GameService.gamesCollection)
            .doc(game.id)
            .update({GameService.statusField: status.value});
        final guestService = GameService(
          firestore: firestore,
          authService: FirebaseAuthService(
            auth: MockFirebaseAuth(
              mockUser: MockUser(uid: 'guest', isAnonymous: true),
              signedIn: true,
            ),
          ),
        );
        await expectLater(
          guestService.joinGame(
            game.id,
            nickname: 'Guest',
            avatarId: 'avatar_03',
          ),
          throwsA(_serviceError(GameServiceErrorCode.gameUnavailable)),
        );
        expect(await service.watchPlayers(game.id).first, hasLength(1));
      });
    }

    test('creates a player with the current anonymous UID', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_host',
      );

      const secondUid = 'second-anonymous-user';
      final secondAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: secondUid, isAnonymous: true),
        signedIn: true,
      );
      final secondService = GameService(
        firestore: firestore,
        authService: FirebaseAuthService(auth: secondAuth),
      );

      await secondService.joinGame(
        game.id,
        nickname: 'Player',
        avatarId: 'avatar_02',
      );

      final player =
          (await firestore
                  .collection(GameService.gamesCollection)
                  .doc(game.id)
                  .collection(GameService.playersCollection)
                  .doc(secondUid)
                  .get())
              .data();
      expect(player, {
        GameService.ownerUidField: secondUid,
        GameService.nicknameField: 'Player',
        GameService.avatarIdField: 'avatar_02',
        GameService.scoreField: 0,
        GameService.numberField: 2,
      });
      await secondService.joinGame(
        game.id,
        nickname: 'Player again',
        avatarId: 'avatar_02',
      );
      expect(
        (await service.watchGame(game.id).first)?.data[GameService
            .playerOrderField],
        [uid, secondUid],
      );
    });

    test('preserves an existing score when a player rejoins', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );
      final player = firestore
          .collection(GameService.gamesCollection)
          .doc(game.id)
          .collection(GameService.playersCollection)
          .doc(uid);
      await player.update({GameService.scoreField: 12});

      await service.joinGame(
        game.id,
        nickname: 'Updated Host',
        avatarId: 'avatar_03',
      );

      final data = (await player.get()).data()!;
      expect(data[GameService.scoreField], 12);
      expect(data[GameService.nicknameField], 'Updated Host');
      expect(data[GameService.avatarIdField], 'avatar_03');
    });

    test('returns gameNotFound for a missing game', () {
      expect(
        () => service.joinGame(
          'missing-game',
          nickname: 'Player',
          avatarId: 'avatar_01',
        ),
        throwsA(_serviceError(GameServiceErrorCode.gameNotFound)),
      );
    });
  });

  group('realtime streams', () {
    test('watchGame emits updates and null after deletion', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );
      final gameDocument = firestore
          .collection(GameService.gamesCollection)
          .doc(game.id);

      expect(
        (await service.watchGame(game.id).first)?.status,
        GameStatus.lobby,
      );

      await gameDocument.update({
        GameService.statusField: GameStatus.inProgress.value,
        GameService.currentRoundField: 1,
      });
      final updated = await service.watchGame(game.id).first;
      expect(updated?.status, GameStatus.inProgress);
      expect(updated?.currentRound, 1);

      await gameDocument.delete();
      expect(await service.watchGame(game.id).first, isNull);
    });

    test('watchPlayers emits typed players after membership changes', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );

      var players = await service.watchPlayers(game.id).first;
      expect(players, hasLength(1));
      expect(players.single.ownerUid, uid);
      expect(players.single.nickname, 'Host');
      expect(players.single.avatarId, 'avatar_01');
      expect(players.single.score, 0);
      expect(players.single.number, 1);

      await firestore
          .collection(GameService.gamesCollection)
          .doc(game.id)
          .collection(GameService.playersCollection)
          .doc('another-user')
          .set({
            GameService.ownerUidField: 'another-user',
            GameService.nicknameField: 'Guest',
            GameService.avatarIdField: 'avatar_02',
            GameService.scoreField: 3,
            GameService.numberField: 2,
          });

      players = await service.watchPlayers(game.id).first;
      expect(players, hasLength(2));
      expect(players.map((player) => player.id), [uid, 'another-user']);
    });

    test('reports unsupported game statuses consistently', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );
      await firestore
          .collection(GameService.gamesCollection)
          .doc(game.id)
          .update({GameService.statusField: 'waiting'});

      expect(
        service.watchGame(game.id),
        emitsError(_serviceError(GameServiceErrorCode.firestore)),
      );
    });
  });

  group('round state mapping', () {
    test('deserializes an ordered valid selection', () async {
      final game = await service.createGame(nickname: 'Host', avatarId: 'a');
      await firestore.collection('games').doc(game.id).update({
        GameService.selectedChallengeTypeField: 'pvp',
        GameService.selectedPlayerUidsField: ['second', uid],
        GameService.selectedChallengeIdField: 'challenge-7',
      });

      final mapped = await service.watchGame(game.id).first;
      expect(mapped?.selectedChallengeType, ChallengeType.pvp);
      expect(mapped?.selectedPlayerUids, ['second', uid]);
      expect(mapped?.selectedChallengeId, 'challenge-7');
    });

    test('reads legacy documents with absent selection fields', () async {
      final reference = firestore.collection('games').doc('legacy');
      await reference.set({
        GameService.codeField: 'OLD12',
        GameService.statusField: GameStatus.lobby.value,
        GameService.hostUidField: uid,
        GameService.playerOrderField: [uid],
        GameService.currentRoundField: 1,
        GameService.totalRoundsField: 5,
      });

      final mapped = Game.fromSnapshot(await reference.get());
      expect(mapped.selectedChallengeType, isNull);
      expect(mapped.selectedPlayerUids, isEmpty);
      expect(mapped.selectedChallengeId, isNull);
    });

    test('rejects unsupported types and invalid player selections', () async {
      final game = await service.createGame(nickname: 'Host', avatarId: 'a');
      final reference = firestore.collection('games').doc(game.id);
      await reference.update({GameService.selectedChallengeTypeField: 'team'});
      expect(
        service.watchGame(game.id),
        emitsError(_serviceError(GameServiceErrorCode.firestore)),
      );
      await reference.update({
        GameService.selectedChallengeTypeField: 'pvp',
        GameService.selectedPlayerUidsField: [uid, uid],
      });
      expect(
        service.watchGame(game.id),
        emitsError(_serviceError(GameServiceErrorCode.firestore)),
      );
    });
  });

  group('leaveGame', () {
    test('removes the current player and updates the game', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );
      final gameDocument = firestore
          .collection(GameService.gamesCollection)
          .doc(game.id);
      final playerDocument = gameDocument
          .collection(GameService.playersCollection)
          .doc(uid);

      await service.leaveGame(game.id);

      expect((await playerDocument.get()).exists, isFalse);
      final remainingGame = (await gameDocument.get()).data()!;
      expect(remainingGame[GameService.playerOrderField], isEmpty);
      expect(remainingGame[GameService.statusField], 'cancelled');
      expect(remainingGame[GameService.hostUidField], uid);
      expect(
        (await gameDocument.get()).data()![GameService.updatedAtField],
        isNotNull,
      );
    });

    test(
      'does not report success for a different authenticated user',
      () async {
        final game = await service.createGame(
          nickname: 'Host',
          avatarId: 'avatar_01',
        );
        final differentUser = GameService(
          firestore: firestore,
          authService: FirebaseAuthService(
            auth: MockFirebaseAuth(
              mockUser: MockUser(uid: 'different-user', isAnonymous: true),
              signedIn: true,
            ),
          ),
        );

        await expectLater(
          differentUser.leaveGame(game.id),
          throwsA(_serviceError(GameServiceErrorCode.membershipMismatch)),
        );
        expect(await service.watchPlayers(game.id).first, hasLength(1));
      },
    );

    test('rejects an inconsistent missing player document', () async {
      final game = await service.createGame(
        nickname: 'Host',
        avatarId: 'avatar_01',
      );
      await firestore
          .collection(GameService.gamesCollection)
          .doc(game.id)
          .collection(GameService.playersCollection)
          .doc(uid)
          .delete();

      await expectLater(
        service.leaveGame(game.id),
        throwsA(_serviceError(GameServiceErrorCode.membershipMismatch)),
      );
    });

    for (final status in [
      GameStatus.lobby,
      GameStatus.inProgress,
      GameStatus.finished,
      GameStatus.cancelled,
    ]) {
      test('removes a player while preserving ${status.value}', () async {
        final game = await service.createGame(nickname: 'Host', avatarId: 'a');
        final guest = GameService(
          firestore: firestore,
          authService: FirebaseAuthService(
            auth: MockFirebaseAuth(
              mockUser: MockUser(uid: 'guest', isAnonymous: true),
              signedIn: true,
            ),
          ),
        );
        await guest.joinGame(game.id, nickname: 'Guest', avatarId: 'b');
        await firestore.collection('games').doc(game.id).update({
          GameService.statusField: status.value,
        });

        await guest.leaveGame(game.id);

        final updated = Game.fromSnapshot(
          await firestore.collection('games').doc(game.id).get(),
        );
        expect(updated.status, status);
        expect(updated.data[GameService.playerOrderField], [uid]);
        expect(await service.watchPlayers(game.id).first, hasLength(1));
      });
    }
  });

  group('validation', () {
    test(
      'joining a started game is rejected but its player can leave',
      () async {
        final game = await service.createGame(nickname: 'Host', avatarId: 'a');
        await service.startGame(game.id);
        await expectLater(
          service.joinGame(game.id, nickname: 'Host', avatarId: 'b'),
          throwsA(_serviceError(GameServiceErrorCode.gameUnavailable)),
        );
        await service.leaveGame(game.id);
        expect(await service.watchPlayers(game.id).first, isEmpty);
        expect(
          (await service.watchGame(game.id).first)?.status,
          GameStatus.cancelled,
        );
      },
    );

    test(
      'leaving preserves order and transfers host to the first remaining player',
      () async {
        final game = await service.createGame(nickname: 'Host', avatarId: 'a');
        GameService asUser(String id) => GameService(
          firestore: firestore,
          authService: FirebaseAuthService(
            auth: MockFirebaseAuth(mockUser: MockUser(uid: id), signedIn: true),
          ),
        );
        final second = asUser('second');
        final third = asUser('third');
        await second.joinGame(game.id, nickname: 'Second', avatarId: 'b');
        await third.joinGame(game.id, nickname: 'Third', avatarId: 'c');
        await third.leaveGame(game.id);
        final reference = firestore.collection('games').doc(game.id);
        var updated = Game.fromSnapshot(await reference.get());
        expect(updated.hostUid, uid);
        expect(updated.data[GameService.playerOrderField], [uid, 'second']);
        await service.leaveGame(game.id);
        updated = Game.fromSnapshot(await reference.get());
        expect(updated.hostUid, 'second');
        expect(updated.status, GameStatus.lobby);
        expect(updated.data[GameService.playerOrderField], ['second']);
        expect(
          (await second.watchPlayers(game.id).first).single.ownerUid,
          'second',
        );
        await second.startGame(game.id);
        expect(
          Game.fromSnapshot(await reference.get()).status,
          GameStatus.inProgress,
        );
      },
    );

    test('rejects invalid game IDs in operations and streams', () {
      expect(
        () => service.joinGame(
          'invalid/id',
          nickname: 'Player',
          avatarId: 'avatar_01',
        ),
        throwsA(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
      expect(
        service.watchGame(''),
        emitsError(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
      expect(
        service.watchPlayers('invalid/id'),
        emitsError(_serviceError(GameServiceErrorCode.invalidArgument)),
      );
    });
  });
}

Matcher _serviceError(GameServiceErrorCode code) {
  return isA<GameServiceException>().having(
    (error) => error.code,
    'code',
    code,
  );
}
