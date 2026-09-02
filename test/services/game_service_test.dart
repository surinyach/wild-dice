import 'package:challenge_app/services/firebase_auth_service.dart';
import 'package:challenge_app/services/game_service.dart';
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
      expect(game.currentRound, 0);
      expect(game.totalRounds, 5);

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
        GameService.currentRoundField,
        GameService.totalRoundsField,
        GameService.createdAtField,
        GameService.updatedAtField,
      });
      expect(gameData[GameService.statusField], 'lobby');
      expect(gameData[GameService.hostUidField], uid);

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
      });
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
      expect(
        (await gameDocument.get()).data()![GameService.updatedAtField],
        isNotNull,
      );
    });
  });

  group('validation', () {
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
