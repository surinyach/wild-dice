import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';

enum GameServiceErrorCode {
  authentication,
  invalidArgument,
  gameNotFound,
  gameUnavailable,
  joinCodeUnavailable,
  firestore,
  unknown,
}

class GameServiceException implements Exception {
  const GameServiceException(this.code, this.message, {this.cause});
  final GameServiceErrorCode code;
  final String message;
  final Object? cause;
  @override
  String toString() => 'GameServiceException($code): $message';
}

enum GameStatus {
  lobby('lobby'),
  inProgress('in_progress'),
  finished('finished'),
  cancelled('cancelled');

  const GameStatus(this.value);
  final String value;

  static GameStatus fromValue(Object? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'The game document contains an unsupported status.',
      ),
    );
  }
}

class Game {
  const Game({
    required this.id,
    required this.code,
    required this.status,
    required this.hostUid,
    required this.currentRound,
    required this.totalRounds,
    required this.data,
  });
  factory Game.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw const GameServiceException(
        GameServiceErrorCode.gameNotFound,
        'The game no longer exists.',
      );
    }
    final code = data[GameService.codeField];
    final hostUid = data[GameService.hostUidField];
    final currentRound = data[GameService.currentRoundField];
    final totalRounds = data[GameService.totalRoundsField];
    if (code is! String ||
        hostUid is! String ||
        currentRound is! int ||
        totalRounds is! int) {
      throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'Invalid game document.',
      );
    }
    return Game(
      id: snapshot.id,
      code: code,
      status: GameStatus.fromValue(data[GameService.statusField]),
      hostUid: hostUid,
      currentRound: currentRound,
      totalRounds: totalRounds,
      data: Map.unmodifiable(data),
    );
  }
  final String id;
  final String code;
  final GameStatus status;
  final String hostUid;
  final int currentRound;
  final int totalRounds;
  final Map<String, dynamic> data;
}

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.ownerUid,
    required this.nickname,
    required this.avatarId,
    required this.score,
    required this.data,
  });
  factory GamePlayer.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final ownerUid = data[GameService.ownerUidField];
    final nickname = data[GameService.nicknameField];
    final avatarId = data[GameService.avatarIdField];
    final score = data[GameService.scoreField];
    if (ownerUid is! String ||
        nickname is! String ||
        avatarId is! String ||
        score is! int) {
      throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'Invalid player document.',
      );
    }
    return GamePlayer(
      id: snapshot.id,
      ownerUid: ownerUid,
      nickname: nickname,
      avatarId: avatarId,
      score: score,
      data: Map.unmodifiable(data),
    );
  }
  final String id;
  final String ownerUid;
  final String nickname;
  final String avatarId;
  final int score;
  final Map<String, dynamic> data;
}

/// Centralizes Firestore access for games and their player subcollections.
abstract interface class GameCreator {
  Future<Game> createGame({
    required String nickname,
    required String avatarId,
    int totalRounds = 5,
    String? code,
  });
}

abstract interface class GameJoiner {
  Future<Game?> findGameByJoinCode(String code);
  Future<void> joinGame(
    String gameId, {
    required String nickname,
    required String avatarId,
  });
}

abstract interface class GameClient implements GameCreator, GameJoiner {}

class GameService implements GameClient {
  GameService({
    FirebaseFirestore? firestore,
    FirebaseAuthService? authService,
    Random? random,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = authService ?? FirebaseAuthService(),
       _random = random ?? Random.secure();

  static const gamesCollection = 'games';
  static const playersCollection = 'players';
  static const codeField = 'code';
  static const statusField = 'status';
  static const hostUidField = 'hostUid';
  static const currentRoundField = 'currentRound';
  static const totalRoundsField = 'totalRounds';
  static const ownerUidField = 'ownerUid';
  static const nicknameField = 'nickname';
  static const avatarIdField = 'avatarId';
  static const scoreField = 'score';
  static const createdAtField = 'createdAt';
  static const updatedAtField = 'updatedAt';
  static const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _auth;
  final Random _random;
  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection(gamesCollection);

  @override
  Future<Game> createGame({
    required String nickname,
    required String avatarId,
    int totalRounds = 5,
    String? code,
  }) => _guard(() async {
    _validatePlayer(nickname, avatarId);
    if (totalRounds <= 0) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidArgument,
        'Total rounds must be greater than zero.',
      );
    }
    final owner = await _auth.ensureAnonymousUser();
    final normalizedCode = code == null
        ? await _availableCode()
        : _normalizeCode(code);
    if (code != null && await findGameByJoinCode(normalizedCode) != null) {
      throw const GameServiceException(
        GameServiceErrorCode.joinCodeUnavailable,
        'That join code is already in use.',
      );
    }
    final game = _games.doc();
    final batch = _firestore.batch();
    batch.set(game, {
      codeField: normalizedCode,
      statusField: GameStatus.lobby.value,
      hostUidField: owner.uid,
      currentRoundField: 0,
      totalRoundsField: totalRounds,
      createdAtField: FieldValue.serverTimestamp(),
      updatedAtField: FieldValue.serverTimestamp(),
    });
    batch.set(game.collection(playersCollection).doc(owner.uid), {
      ownerUidField: owner.uid,
      nicknameField: nickname.trim(),
      avatarIdField: avatarId.trim(),
      scoreField: 0,
    });
    await batch.commit();
    return Game.fromSnapshot(await game.get());
  });

  @override
  Future<Game?> findGameByJoinCode(String code) => _guard(() async {
    final result = await _games
        .where(codeField, isEqualTo: _normalizeCode(code))
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : Game.fromSnapshot(result.docs.first);
  });

  @override
  Future<void> joinGame(
    String gameId, {
    required String nickname,
    required String avatarId,
  }) => _guard(() async {
    _validateId(gameId);
    _validatePlayer(nickname, avatarId);
    final user = await _auth.ensureAnonymousUser();
    final game = _games.doc(gameId);
    await _firestore.runTransaction((transaction) async {
      final player = game.collection(playersCollection).doc(user.uid);
      final gameSnapshot = await transaction.get(game);
      if (!gameSnapshot.exists) {
        throw const GameServiceException(
          GameServiceErrorCode.gameNotFound,
          'The game does not exist.',
        );
      }
      if (gameSnapshot.data()?[statusField] != GameStatus.lobby.value) {
        throw const GameServiceException(
          GameServiceErrorCode.gameUnavailable,
          'This game is no longer available to join.',
        );
      }
      final playerSnapshot = await transaction.get(player);
      transaction.set(player, {
        ownerUidField: user.uid,
        nicknameField: nickname.trim(),
        avatarIdField: avatarId.trim(),
        scoreField: playerSnapshot.data()?[scoreField] is int
            ? playerSnapshot.data()![scoreField]
            : 0,
      }, SetOptions(merge: true));
      transaction.update(game, {updatedAtField: FieldValue.serverTimestamp()});
    });
  });

  Stream<Game?> watchGame(String gameId) {
    try {
      _validateId(gameId);
      return _mapStream(
        _games.doc(gameId).snapshots(),
        (snapshot) => snapshot.exists ? Game.fromSnapshot(snapshot) : null,
      );
    } catch (error, stackTrace) {
      return Stream.error(error, stackTrace);
    }
  }

  Stream<List<GamePlayer>> watchPlayers(String gameId) {
    try {
      _validateId(gameId);
      return _mapStream(
        _games
            .doc(gameId)
            .collection(playersCollection)
            .orderBy(FieldPath.documentId)
            .snapshots(),
        (snapshot) =>
            List.unmodifiable(snapshot.docs.map(GamePlayer.fromSnapshot)),
      );
    } catch (error, stackTrace) {
      return Stream.error(error, stackTrace);
    }
  }

  Future<void> leaveGame(String gameId) => _guard(() async {
    _validateId(gameId);
    final user = await _auth.ensureAnonymousUser();
    final game = _games.doc(gameId);
    final batch = _firestore.batch();
    batch.delete(game.collection(playersCollection).doc(user.uid));
    batch.update(game, {updatedAtField: FieldValue.serverTimestamp()});
    await batch.commit();
  });

  Future<String> _availableCode() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = List.generate(
        5,
        (_) => _characters[_random.nextInt(_characters.length)],
      ).join();
      if (await findGameByJoinCode(code) == null) return code;
    }
    throw const GameServiceException(
      GameServiceErrorCode.joinCodeUnavailable,
      'Could not allocate a join code. Please try again.',
    );
  }

  static String _normalizeCode(String value) {
    final code = value.trim().toUpperCase();
    if (code.isEmpty) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidArgument,
        'The join code cannot be empty.',
      );
    }
    return code;
  }

  static void _validateId(String id) {
    if (id.trim().isEmpty || id.contains('/')) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidArgument,
        'A valid game ID is required.',
      );
    }
  }

  static void _validatePlayer(String nickname, String avatarId) {
    if (nickname.trim().isEmpty || avatarId.trim().isEmpty) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidArgument,
        'A nickname and avatar ID are required.',
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on GameServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw GameServiceException(
        error.plugin == 'firebase_auth'
            ? GameServiceErrorCode.authentication
            : GameServiceErrorCode.firestore,
        error.message ?? 'A Firebase game operation failed.',
        cause: error,
      );
    } catch (error) {
      throw GameServiceException(
        GameServiceErrorCode.unknown,
        'An unexpected game operation failure occurred.',
        cause: error,
      );
    }
  }

  Stream<R> _mapStream<T, R>(
    Stream<T> source,
    R Function(T value) convert,
  ) async* {
    try {
      await for (final value in source) {
        yield convert(value);
      }
    } on GameServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw GameServiceException(
        GameServiceErrorCode.firestore,
        error.message ?? 'A realtime game operation failed.',
        cause: error,
      );
    } catch (error) {
      throw GameServiceException(
        GameServiceErrorCode.unknown,
        'A realtime game operation failed.',
        cause: error,
      );
    }
  }
}
