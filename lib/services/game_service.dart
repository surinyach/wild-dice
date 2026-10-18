import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/challenges/domain/challenge.dart';
import '../features/challenges/data/local_challenge_repository.dart';
import 'firebase_auth_service.dart';

enum GameServiceErrorCode {
  authentication,
  invalidArgument,
  gameNotFound,
  gameUnavailable,
  membershipMismatch,
  joinCodeUnavailable,
  notHost,
  invalidState,
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

class _MembershipChanged implements Exception {
  const _MembershipChanged();
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
    this.selectedChallengeType,
    this.selectedPlayerUids = const [],
    this.selectedChallengeId,
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
    final selectedChallengeTypeValue =
        data[GameService.selectedChallengeTypeField];
    final selectedPlayerUidsValue =
        data[GameService.selectedPlayerUidsField] ?? const <String>[];
    final selectedChallengeId = data[GameService.selectedChallengeIdField];
    if (code is! String ||
        hostUid is! String ||
        currentRound is! int ||
        totalRounds is! int ||
        (selectedChallengeTypeValue != null &&
            selectedChallengeTypeValue is! String) ||
        selectedPlayerUidsValue is! List ||
        selectedPlayerUidsValue.any((uid) => uid is! String) ||
        (selectedChallengeId != null && selectedChallengeId is! String)) {
      throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'Invalid game document.',
      );
    }
    ChallengeType? selectedChallengeType;
    if (selectedChallengeTypeValue != null) {
      try {
        selectedChallengeType = ChallengeType.fromJson(
          selectedChallengeTypeValue as String,
        );
      } on FormatException {
        throw const GameServiceException(
          GameServiceErrorCode.firestore,
          'The game document contains an unsupported challenge type.',
        );
      }
    }
    final selectedPlayerUids = selectedPlayerUidsValue.cast<String>();
    _validateSelection(selectedChallengeType, selectedPlayerUids);
    return Game(
      id: snapshot.id,
      code: code,
      status: GameStatus.fromValue(data[GameService.statusField]),
      hostUid: hostUid,
      currentRound: currentRound,
      totalRounds: totalRounds,
      selectedChallengeType: selectedChallengeType,
      selectedPlayerUids: List.unmodifiable(selectedPlayerUids),
      selectedChallengeId: selectedChallengeId as String?,
      data: Map.unmodifiable(data),
    );
  }
  final String id;
  final String code;
  final GameStatus status;
  final String hostUid;
  final int currentRound;
  final int totalRounds;
  final ChallengeType? selectedChallengeType;
  final List<String> selectedPlayerUids;
  final String? selectedChallengeId;
  final Map<String, dynamic> data;

  static void _validateSelection(
    ChallengeType? type,
    List<String> selectedPlayerUids,
  ) {
    final validCount = switch (type) {
      null => selectedPlayerUids.isEmpty,
      ChallengeType.normal ||
      ChallengeType.wild => selectedPlayerUids.length == 1,
      ChallengeType.pvp =>
        selectedPlayerUids.length == 2 &&
            selectedPlayerUids[0] != selectedPlayerUids[1],
    };
    if (!validCount) {
      throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'The game document contains an invalid player selection.',
      );
    }
  }
}

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.ownerUid,
    required this.nickname,
    required this.avatarId,
    required this.score,
    required this.number,
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
    final number = data[GameService.numberField];
    if (ownerUid is! String ||
        nickname is! String ||
        avatarId is! String ||
        score is! int ||
        number is! int ||
        number < 1) {
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
      number: number,
      data: Map.unmodifiable(data),
    );
  }
  final String id;
  final String ownerUid;
  final String nickname;
  final String avatarId;
  final int score;

  /// The current, one-based position of this player in the game.
  final int number;
  final Map<String, dynamic> data;
}

class GeneratedRound {
  const GeneratedRound({
    required this.currentRound,
    required this.selectedChallengeType,
    required this.selectedPlayerUids,
    required this.selectedChallengeId,
  });

  final int currentRound;
  final ChallengeType selectedChallengeType;
  final List<String> selectedPlayerUids;
  final String selectedChallengeId;
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

abstract interface class GameLobbyReader {
  String? get currentUserId;
  Stream<List<GamePlayer>> watchPlayers(String gameId);
  Stream<Game?> watchGame(String gameId);
  Future<void> leaveGame(String gameId);
  Future<void> startGame(String gameId);
}

abstract interface class GameSession
    implements GameCreator, GameJoiner, GameLobbyReader {}

abstract interface class GameClient implements GameSession {}

class GameService implements GameClient {
  GameService({
    FirebaseFirestore? firestore,
    FirebaseAuthService? authService,
    Random? random,
    LocalChallengeRepository? challengeRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = authService ?? FirebaseAuthService(),
       _random = random ?? Random.secure(),
       _challengeRepository = challengeRepository ?? LocalChallengeRepository();

  static const gamesCollection = 'games';
  static const playersCollection = 'players';
  static const codeField = 'code';
  static const statusField = 'status';
  static const hostUidField = 'hostUid';
  static const playerCountField = 'playerCount';
  static const currentRoundField = 'currentRound';
  static const totalRoundsField = 'totalRounds';
  static const selectedChallengeTypeField = 'selectedChallengeType';
  static const selectedPlayerUidsField = 'selectedPlayerUids';
  static const selectedChallengeIdField = 'selectedChallengeId';
  static const ownerUidField = 'ownerUid';
  static const nicknameField = 'nickname';
  static const avatarIdField = 'avatarId';
  static const scoreField = 'score';
  static const numberField = 'number';
  static const createdAtField = 'createdAt';
  static const updatedAtField = 'updatedAt';
  static const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _auth;
  final Random _random;
  final LocalChallengeRepository _challengeRepository;
  @override
  String? get currentUserId => _auth.currentUserId;
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
      playerCountField: 1,
      currentRoundField: 1,
      totalRoundsField: totalRounds,
      selectedChallengeTypeField: null,
      selectedPlayerUidsField: <String>[],
      selectedChallengeIdField: null,
      createdAtField: FieldValue.serverTimestamp(),
      updatedAtField: FieldValue.serverTimestamp(),
    });
    batch.set(game.collection(playersCollection).doc(owner.uid), {
      ownerUidField: owner.uid,
      nicknameField: nickname.trim(),
      avatarIdField: avatarId.trim(),
      scoreField: 0,
      numberField: 1,
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
      final storedGame = Game.fromSnapshot(gameSnapshot);
      if (storedGame.status != GameStatus.lobby) {
        throw const GameServiceException(
          GameServiceErrorCode.gameUnavailable,
          'This game is no longer available to join.',
        );
      }
      final playerSnapshot = await transaction.get(player);
      final existingNumber = playerSnapshot.data()?[numberField];
      final isExistingPlayer = existingNumber is int && existingNumber >= 1;
      final playerCount = _playerCount(storedGame);
      final playerNumber = isExistingPlayer ? existingNumber : playerCount + 1;
      transaction.set(player, {
        ownerUidField: user.uid,
        nicknameField: nickname.trim(),
        avatarIdField: avatarId.trim(),
        scoreField: playerSnapshot.data()?[scoreField] is int
            ? playerSnapshot.data()![scoreField]
            : 0,
        numberField: playerNumber,
      }, SetOptions(merge: true));
      transaction.update(game, {
        if (!isExistingPlayer) playerCountField: playerNumber,
        updatedAtField: FieldValue.serverTimestamp(),
      });
    });
  });

  /// Atomically starts a lobby. Repeated starts are successful no-ops.
  @override
  Future<void> startGame(String gameId) => _guard(() async {
    _validateId(gameId);
    final user = await _auth.ensureAnonymousUser();
    final reference = _games.doc(gameId);
    await _firestore.runTransaction((transaction) async {
      final game = Game.fromSnapshot(await transaction.get(reference));
      if (game.hostUid != user.uid) {
        throw const GameServiceException(
          GameServiceErrorCode.notHost,
          'Only the host can start the game.',
        );
      }
      if (game.status == GameStatus.inProgress) return;
      if (game.status != GameStatus.lobby) {
        throw const GameServiceException(
          GameServiceErrorCode.invalidState,
          'This game can no longer be started.',
        );
      }
      transaction.update(reference, {
        statusField: GameStatus.inProgress.value,
        updatedAtField: FieldValue.serverTimestamp(),
      });
    });
  });

  /// Selects an entire round locally and publishes it with one game update.
  Future<GeneratedRound> generateRound(String gameId) => _guard(() async {
    _validateId(gameId);
    final reference = _games.doc(gameId);
    final gameSnapshot = await reference.get();
    if (!gameSnapshot.exists) {
      throw const GameServiceException(
        GameServiceErrorCode.gameNotFound,
        'The game does not exist.',
      );
    }
    final game = Game.fromSnapshot(gameSnapshot);
    if (game.status != GameStatus.inProgress) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidState,
        'Only an in-progress game can generate a round.',
      );
    }
    final playerSnapshot = await reference.collection(playersCollection).get();
    final players = playerSnapshot.docs.map(GamePlayer.fromSnapshot).toList();
    if (players.isEmpty) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidState,
        'Cannot generate a round without players.',
      );
    }
    final type = ChallengeType.values[_random.nextInt(ChallengeType.values.length)];
    final requiredCount = type == ChallengeType.pvp ? 2 : 1;
    if (players.length < requiredCount) {
      throw const GameServiceException(
        GameServiceErrorCode.invalidState,
        'A PvP round requires at least two players.',
      );
    }
    // Partial Fisher-Yates gives every eligible player an equal chance.
    for (var i = 0; i < requiredCount; i++) {
      final swapIndex = i + _random.nextInt(players.length - i);
      final player = players[i];
      players[i] = players[swapIndex];
      players[swapIndex] = player;
    }
    final selectedPlayers = players.take(requiredCount).map((p) => p.id).toList();
    final challenges = (await _challengeRepository.loadChallenges())
        .where((challenge) => challenge.type == type)
        .toList();
    if (challenges.isEmpty) {
      throw GameServiceException(
        GameServiceErrorCode.invalidState,
        'No challenges are available for ${type.name}.',
      );
    }
    final challenge = challenges[_random.nextInt(challenges.length)];
    final round = GeneratedRound(
      currentRound: game.currentRound + 1,
      selectedChallengeType: type,
      selectedPlayerUids: List.unmodifiable(selectedPlayers),
      selectedChallengeId: challenge.id,
    );
    await reference.update({
      currentRoundField: round.currentRound,
      selectedChallengeTypeField: type.name,
      selectedPlayerUidsField: round.selectedPlayerUids,
      selectedChallengeIdField: challenge.id,
      updatedAtField: FieldValue.serverTimestamp(),
    });
    return round;
  });

  @override
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

  @override
  Stream<List<GamePlayer>> watchPlayers(String gameId) {
    try {
      _validateId(gameId);
      return _mapStream(
        _games
            .doc(gameId)
            .collection(playersCollection)
            .orderBy(numberField)
            .snapshots(),
        (snapshot) =>
            List.unmodifiable(snapshot.docs.map(GamePlayer.fromSnapshot)),
      );
    } catch (error, stackTrace) {
      return Stream.error(error, stackTrace);
    }
  }

  @override
  Future<void> leaveGame(String gameId) => _guard(() async {
    _validateId(gameId);
    final user = await _auth.ensureAnonymousUser();
    final game = _games.doc(gameId);
    for (var attempt = 0; attempt < 3; attempt++) {
      final players = await game
          .collection(playersCollection)
          .orderBy(numberField)
          .get();
      if (players.docs.every((player) => player.id != user.uid)) {
        throw const GameServiceException(
          GameServiceErrorCode.membershipMismatch,
          'Your player membership is inconsistent. Please rejoin the game '
          'and try again.',
        );
      }
      try {
        await _firestore.runTransaction((transaction) async {
          final storedGame = Game.fromSnapshot(await transaction.get(game));
          final playerSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final player in players.docs) {
            playerSnapshots.add(await transaction.get(player.reference));
          }
          if (_playerCount(storedGame) != playerSnapshots.length) {
            throw const _MembershipChanged();
          }
          final currentPlayer = playerSnapshots.where(
            (snapshot) => snapshot.id == user.uid,
          );
          if (currentPlayer.isEmpty ||
              currentPlayer.single.data()?[ownerUidField] != user.uid) {
            throw const GameServiceException(
              GameServiceErrorCode.membershipMismatch,
              'Your player membership is inconsistent. Please rejoin the game '
              'and try again.',
            );
          }
          final remaining = playerSnapshots
              .where((snapshot) => snapshot.id != user.uid)
              .toList();
          transaction.delete(currentPlayer.single.reference);
          for (var index = 0; index < remaining.length; index++) {
            transaction.update(remaining[index].reference, {
              numberField: index + 1,
            });
          }
          transaction.update(game, {
            playerCountField: remaining.length,
            hostUidField: remaining.isEmpty
                ? storedGame.hostUid
                : remaining.first.id,
            statusField: remaining.isEmpty
                ? GameStatus.cancelled.value
                : storedGame.status.value,
            updatedAtField: FieldValue.serverTimestamp(),
          });
        });
        return;
      } on _MembershipChanged {
        if (attempt == 2) {
          throw const GameServiceException(
            GameServiceErrorCode.firestore,
            'The player list changed while leaving. Please try again.',
          );
        }
      }
    }
  });

  static int _playerCount(Game game) {
    final count = game.data[playerCountField];
    if (count is! int || count < 0) {
      throw const GameServiceException(
        GameServiceErrorCode.firestore,
        'The game has no valid player count. Please create a new game.',
      );
    }
    return count;
  }

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
