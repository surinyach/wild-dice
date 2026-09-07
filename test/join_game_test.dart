import 'dart:async';
import 'package:challenge_app/app.dart';
import 'package:challenge_app/features/main_menu/domain/main_menu_identity.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Game game([GameStatus status = GameStatus.lobby]) => Game(
  id: 'game-1',
  code: 'A7K92',
  status: status,
  hostUid: 'host',
  currentRound: 0,
  totalRounds: 5,
  data: const {},
);

class FakeGames implements GameClient {
  Game? found = game();
  Object? failure;
  Completer<void>? pendingJoin;
  Completer<Game?>? pendingLookup;
  int lookups = 0;
  int joins = 0;
  String? code, nickname, avatarId, gameId;
  @override
  Future<Game?> findGameByJoinCode(String code) async {
    lookups++;
    this.code = code;
    if (failure != null) throw failure!;
    return pendingLookup == null ? found : await pendingLookup!.future;
  }

  @override
  Future<void> joinGame(
    String gameId, {
    required String nickname,
    required String avatarId,
  }) async {
    joins++;
    this.gameId = gameId;
    this.nickname = nickname;
    this.avatarId = avatarId;
    if (pendingJoin != null) await pendingJoin!.future;
  }

  @override
  Future<Game> createGame({
    required String nickname,
    required String avatarId,
    int totalRounds = 5,
    String? code,
  }) async => game();
}

void main() {
  late FakeGames service;
  late MainMenuIdentityController identity;
  setUp(() {
    service = FakeGames();
    identity = MainMenuIdentityController(
      nickname: 'Player',
      avatarId: 'avatar_01',
    );
  });
  tearDown(() => identity.dispose());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      App(gameService: service, identityController: identity),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('nickname-field')),
      'Current Hero',
    );
    await tester.tap(find.byKey(const Key('avatar-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JOIN GAME'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nickname-field')), findsNothing);
    expect(find.byKey(const Key('avatar-picker')), findsNothing);
  }

  Future<void> submit(WidgetTester tester, [String code = ' a7k92 ']) async {
    await tester.enterText(find.byKey(const Key('game-code-field')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('joins with current menu identity and replaces join with lobby', (
    tester,
  ) async {
    await open(tester);
    await submit(tester);
    expect(service.code, 'A7K92');
    expect(service.gameId, 'game-1');
    expect(service.nickname, 'Current Hero');
    expect(service.avatarId, 'avatar_02');
    expect(service.joins, 1);
    expect(find.byKey(const Key('game-lobby-background')), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-lobby-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
    expect(find.byKey(const Key('game-code-field')), findsNothing);
  });
  testWidgets('empty code and missing menu identity are actionable', (
    tester,
  ) async {
    await open(tester);
    await submit(tester, '  ');
    expect(find.text('Enter a game code.'), findsOneWidget);
    expect(service.lookups, 0);
    identity.updateNickname('');
    await submit(tester);
    expect(
      find.text('Choose your nickname and avatar on the Main Menu first.'),
      findsOneWidget,
    );
    expect(service.joins, 0);
  });
  testWidgets('unknown or invalid codes can be corrected and retried', (
    tester,
  ) async {
    service.found = null;
    await open(tester);
    await submit(tester, '!invalid!');
    expect(
      find.text('No game found. Check the code and try again.'),
      findsOneWidget,
    );
    expect(service.joins, 0);
    service.found = game();
    await submit(tester);
    expect(service.joins, 1);
  });
  for (final status in [
    GameStatus.inProgress,
    GameStatus.finished,
    GameStatus.cancelled,
  ]) {
    testWidgets('rejects ${status.value} before joining', (tester) async {
      service.found = game(status);
      await open(tester);
      await submit(tester);
      expect(
        find.text('This game is no longer available to join.'),
        findsOneWidget,
      );
      expect(service.joins, 0);
    });
  }
  testWidgets('lookup errors allow retry', (tester) async {
    service.failure = Exception('offline');
    await open(tester);
    await submit(tester);
    expect(
      find.text('Could not join the game. Please try again.'),
      findsOneWidget,
    );
    service.failure = null;
    await submit(tester);
    expect(service.joins, 1);
  });
  testWidgets(
    'loading blocks duplicate requests and back navigation; join failure allows retry',
    (tester) async {
      service.pendingLookup = Completer<Game?>();
      service.pendingJoin = Completer<void>();
      await open(tester);
      await tester.enterText(find.byKey(const Key('game-code-field')), 'A7K92');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('game-code-field')))
            .enabled,
        false,
      );
      await tester.tap(find.byKey(const Key('confirm-join-game')));
      expect(service.lookups, 1);
      expect(service.joins, 0);
      service.pendingLookup!.complete(game());
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-join-game')));
      await tester.tap(find.byTooltip('Back to main menu'));
      await tester.pump();
      expect(service.joins, 1);
      expect(find.byKey(const Key('game-code-field')), findsOneWidget);
      service.pendingJoin!.completeError(
        const GameServiceException(
          GameServiceErrorCode.gameUnavailable,
          'This game is no longer available to join.',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('This game is no longer available to join.'),
        findsOneWidget,
      );
      service.pendingJoin = null;
      await tester.tap(find.byKey(const Key('confirm-join-game')));
      await tester.pumpAndSettle();
      expect(service.joins, 2);
      expect(find.byKey(const Key('game-lobby-background')), findsOneWidget);
    },
  );
}
