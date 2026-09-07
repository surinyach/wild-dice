import 'package:challenge_app/app.dart';
import 'package:challenge_app/features/main_menu/domain/main_menu_identity.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens on the main menu with editable identity', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('WILD DICE'), findsOneWidget);
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
    expect(find.byKey(const Key('avatar-picker')), findsOneWidget);
    expect(find.text('NICKNAME'), findsNothing);
    expect(find.text('Player'), findsNothing);
    expect(find.text('your name'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('nickname-field')))
          .textAlign,
      TextAlign.center,
    );
    expect(find.text('CREATE GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
  });

  testWidgets('opens Create Game with logo and round options', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('CREATE GAME'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-game-background')), findsOneWidget);
    expect(find.byKey(const Key('nickname-field')), findsNothing);
    expect(find.byKey(const Key('avatar-picker')), findsNothing);
    expect(find.bySemanticsLabel('WILD DICE'), findsOneWidget);
    expect(find.byKey(const Key('round-3')), findsOneWidget);
    expect(find.byKey(const Key('round-5')), findsOneWidget);
    expect(find.byKey(const Key('round-10')), findsOneWidget);
    expect(find.text('3 rounds'), findsOneWidget);
    expect(find.text('5 rounds'), findsOneWidget);
    expect(find.text('10 rounds'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('round-5')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirm-create-game')), findsOneWidget);
    expect(find.byKey(const Key('create-game-back-button')), findsOneWidget);
    expect(find.text('CREATE GAME'), findsOneWidget);

    await tester.tap(find.byKey(const Key('round-10')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('round-10')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('create-game-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
  });

  testWidgets(
    'creates a game with the selected rounds and main-menu identity',
    (tester) async {
      final creator = _FakeGameClient();
      final identity = MainMenuIdentityController(
        nickname: 'Jungle Hero',
        avatarId: 'avatar_03',
      );
      await tester.pumpWidget(
        App(gameService: creator, identityController: identity),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('CREATE GAME'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('round-10')));
      await tester.tap(find.byKey(const Key('confirm-create-game')));
      await tester.pumpAndSettle();

      expect(creator.nickname, 'Jungle Hero');
      expect(creator.avatarId, 'avatar_03');
      expect(creator.totalRounds, 10);
      expect(find.text('A7K92'), findsWidgets);
      expect(find.text('GAME LOBBY'), findsNothing);
      expect(find.byKey(const Key('game-lobby-background')), findsOneWidget);
      expect(find.byKey(const Key('game-lobby-back-button')), findsOneWidget);
      expect(find.byKey(const Key('start-game-button')), findsOneWidget);
      expect(find.text('START GAME'), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('game-code')))
            .style
            ?.color,
        Colors.white,
      );
    },
  );

  testWidgets('selects an avatar from the carousel bottom sheet', (
    tester,
  ) async {
    final identity = MainMenuIdentityController(avatarId: 'avatar_01');
    await tester.pumpWidget(
      App(gameService: _FakeGameClient(), identityController: identity),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('avatar-picker')));
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE YOUR AVATAR'), findsOneWidget);
    expect(find.byKey(const Key('avatar-carousel')), findsOneWidget);
    expect(find.text('JAGUAR'), findsOneWidget);
    expect(find.text('AVATAR 01'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    expect(identity.avatarId, 'avatar_02');
    expect(find.text('BLACK PANTHER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-avatar')));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE YOUR AVATAR'), findsNothing);
  });

  testWidgets('navigates to Join Game and back to the main menu', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('JOIN GAME'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-code-field')), findsOneWidget);
    await tester.tap(find.byTooltip('Back to main menu'));
    await tester.pumpAndSettle();
    expect(find.text('CREATE GAME'), findsOneWidget);
  });
}

App _testApp([GameClient? creator]) => App(
  gameService: creator ?? _FakeGameClient(),
  identityController: MainMenuIdentityController(),
);

class _FakeGameClient implements GameClient {
  @override
  Future<Game?> findGameByJoinCode(String code) async => null;

  @override
  Future<void> joinGame(
    String gameId, {
    required String nickname,
    required String avatarId,
  }) async {}

  String? nickname;
  String? avatarId;
  int? totalRounds;

  @override
  Future<Game> createGame({
    required String nickname,
    required String avatarId,
    int totalRounds = 5,
    String? code,
  }) {
    this.nickname = nickname;
    this.avatarId = avatarId;
    this.totalRounds = totalRounds;
    return Future.value(
      Game(
        id: 'game-1',
        code: 'A7K92',
        status: GameStatus.lobby,
        hostUid: 'anonymous-user',
        currentRound: 0,
        totalRounds: totalRounds,
        data: const {},
      ),
    );
  }
}
