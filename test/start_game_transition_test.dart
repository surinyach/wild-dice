import 'dart:async';

import 'package:challenge_app/features/game_lobby/presentation/pages/game_lobby_page.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:challenge_app/shared/widgets/jungle_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Game game(GameStatus status) => Game(
  id: 'game',
  code: 'ABCDE',
  status: status,
  hostUid: 'host',
  currentRound: 0,
  totalRounds: 5,
  data: const {},
);

class Session implements GameSession {
  Session(this.currentUserId);
  @override
  final String currentUserId;
  final updates = StreamController<Game?>.broadcast();
  Completer<void> start = Completer<void>();
  int calls = 0;

  @override
  Future<void> leaveGame(String gameId) async {}

  @override
  Stream<List<GamePlayer>> watchPlayers(String gameId) =>
      Stream<List<GamePlayer>>.multi((controller) {
        controller.add(const []);
      });

  @override
  Future<Game?> findGameByJoinCode(String code) async => null;

  @override
  Future<void> joinGame(
    String gameId, {
    required String nickname,
    required String avatarId,
  }) async {}
  @override
  Stream<Game?> watchGame(String id) => updates.stream;
  @override
  Future<void> startGame(String id) {
    calls++;
    return start.future;
  }

  @override
  Future<Game> createGame({
    required String nickname,
    required String avatarId,
    int totalRounds = 5,
    String? code,
  }) => throw UnimplementedError();
}

void main() {
  Future<void> open(WidgetTester tester, Session session) async {
    addTearDown(session.updates.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GameLobbyPage(game: game(GameStatus.lobby), gameService: session),
      ),
    );
    session.updates.add(game(GameStatus.lobby));
    await tester.pumpAndSettle();
  }

  for (final uid in ['host', 'guest']) {
    testWidgets('$uid navigates once from realtime status', (tester) async {
      final session = Session(uid);
      await open(tester, session);
      if (uid == 'guest') {
        expect(find.byKey(const Key('start-game-button')), findsNothing);
      }
      session.updates.add(game(GameStatus.inProgress));
      session.updates.add(game(GameStatus.inProgress));
      await tester.pumpAndSettle();
      expect(find.text('Your game has started.'), findsOneWidget);
      expect(find.byType(GameLobbyPage), findsNothing);
      expect(session.calls, 0);
      expect(session.updates.hasListener, isFalse);
    });
  }

  testWidgets(
    'blocks duplicate taps, reports failure, retries and awaits stream',
    (tester) async {
      final session = Session('host');
      await open(tester, session);
      final button = find.byKey(const Key('start-game-button'));
      final action = tester.widget<JungleActionButton>(button).onPressed!;
      action();
      action();
      await tester.pump();
      expect(session.calls, 1);
      expect(tester.widget<JungleActionButton>(button).loading, isTrue);
      session.start.completeError(
        const GameServiceException(
          GameServiceErrorCode.firestore,
          'Update failed.',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Update failed.'), findsOneWidget);
      session.start = Completer<void>();
      tester.widget<JungleActionButton>(button).onPressed!();
      session.start.complete();
      await tester.pump();
      expect(session.calls, 2);
      expect(tester.widget<JungleActionButton>(button).onPressed, isNull);
      expect(find.byType(GameLobbyPage), findsOneWidget);
      session.updates.add(game(GameStatus.inProgress));
      await tester.pumpAndSettle();
      expect(find.text('Your game has started.'), findsOneWidget);
    },
  );

  testWidgets('stream failures disable start and can be retried', (
    tester,
  ) async {
    final session = Session('host');
    await open(tester, session);
    session.updates.addError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-game-button')), findsNothing);
    expect(
      find.text('Could not refresh the game. Please retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry game'));
    session.updates.add(game(GameStatus.inProgress));
    await tester.pumpAndSettle();
    expect(find.text('Your game has started.'), findsOneWidget);
  });
}
