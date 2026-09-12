import 'dart:async';

import 'package:challenge_app/core/assets/app_assets.dart';
import 'package:challenge_app/features/game_lobby/presentation/pages/game_lobby_page.dart';
import 'package:challenge_app/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const game = Game(
  id: 'game',
  code: 'A7K92',
  status: GameStatus.lobby,
  hostUid: 'host',
  currentRound: 0,
  totalRounds: 5,
  data: {},
);
const host = GamePlayer(
  id: 'host',
  ownerUid: 'host',
  nickname: 'Host Hero',
  avatarId: 'avatar_01',
  score: 0,
  data: {},
);
const guest = GamePlayer(
  id: 'guest',
  ownerUid: 'guest',
  nickname: 'Guest Hero',
  avatarId: 'avatar_02',
  score: 0,
  data: {},
);

class LobbyReader implements GameLobbyReader {
  LobbyReader(this.currentUserId);
  @override
  final String currentUserId;
  final players = StreamController<List<GamePlayer>>.broadcast();
  final games = StreamController<Game?>.broadcast();
  Completer<void>? pendingLeave;
  int leaves = 0;
  @override
  Future<void> startGame(String gameId) async {}
  @override
  Stream<Game?> watchGame(String gameId) => games.stream;
  @override
  Future<void> leaveGame(String gameId) async {
    leaves++;
    if (pendingLeave != null) await pendingLeave!.future;
  }

  int subscriptions = 0;
  @override
  Stream<List<GamePlayer>> watchPlayers(String gameId) {
    expect(gameId, game.id);
    subscriptions++;
    return players.stream;
  }
}

void main() {
  for (final uid in ['host', 'guest']) {
    testWidgets(
      '$uid sees shared players and only the actual host is labeled host',
      (tester) async {
        final service = LobbyReader(uid);
        addTearDown(service.players.close);
        addTearDown(service.games.close);
        await tester.pumpWidget(
          MaterialApp(
            home: GameLobbyPage(game: game, gameService: service),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        service.players.add([host]);
        await tester.pumpAndSettle();
        expect(find.text('Host Hero'), findsOneWidget);
        expect(find.text('Guest Hero'), findsNothing);

        service.players.add([host, guest]);
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNWidgets(2));
        final hostCard = find.byKey(const ValueKey('player-host'));
        final guestCard = find.byKey(const ValueKey('player-guest'));
        expect(
          find.descendant(of: hostCard, matching: find.text('HOST')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: guestCard, matching: find.text('PLAYER')),
          findsOneWidget,
        );
        final avatar = tester.widget<CircleAvatar>(
          find.descendant(of: guestCard, matching: find.byType(CircleAvatar)),
        );
        expect(
          (avatar.backgroundImage! as AssetImage).assetName,
          AppAssets.avatars['avatar_02'],
        );
        expect(
          find.byKey(const Key('start-game-button')),
          uid == 'host' ? findsOneWidget : findsNothing,
        );
        if (uid == 'guest') {
          expect(
            find.text('Waiting for the host to start the game'),
            findsOneWidget,
          );
        }
        service.players.add([host]);
        await tester.pumpAndSettle();
        expect(find.text('Guest Hero'), findsNothing);
        expect(service.subscriptions, 1);
        await tester.pumpWidget(const SizedBox());
        expect(service.players.hasListener, false);
      },
    );
  }

  testWidgets('host transfer updates host label and start button live', (
    tester,
  ) async {
    final service = LobbyReader('guest');
    addTearDown(service.players.close);
    addTearDown(service.games.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GameLobbyPage(game: game, gameService: service),
      ),
    );
    service.players.add([host, guest]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-game-button')), findsNothing);
    service.games.add(
      const Game(
        id: 'game',
        code: 'A7K92',
        status: GameStatus.lobby,
        hostUid: 'guest',
        currentRound: 0,
        totalRounds: 5,
        data: {},
      ),
    );
    service.players.add([guest]);
    await tester.pumpAndSettle();
    expect(find.text('Host Hero'), findsNothing);
    expect(find.text('HOST'), findsOneWidget);
    expect(find.byKey(const Key('start-game-button')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(service.games.hasListener, false);
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      'leave via ${systemBack ? "system back" : "arrow"} waits and allows retry',
      (tester) async {
        final service = LobbyReader('guest');
        addTearDown(service.players.close);
        addTearDown(service.games.close);
        service.pendingLeave = Completer<void>();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        GameLobbyPage(game: game, gameService: service),
                  ),
                ),
                child: const Text('Open lobby'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open lobby'));
        await tester.pump();
        service.players.add([host, guest]);
        await tester.pumpAndSettle();
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byKey(const Key('game-lobby-back-button')));
        }
        await tester.pump();
        expect(find.text('Leaving game\u2026'), findsOneWidget);
        await tester.tap(find.byKey(const Key('game-lobby-back-button')));
        expect(service.leaves, 1);
        service.pendingLeave!.completeError(Exception('permission-denied'));
        await tester.pumpAndSettle();
        expect(
          find.text('Could not leave the game. Please try again.'),
          findsOneWidget,
        );
        expect(find.byType(GameLobbyPage), findsOneWidget);
        service.pendingLeave = null;
        await tester.tap(find.byKey(const Key('game-lobby-back-button')));
        await tester.pumpAndSettle();
        expect(service.leaves, 2);
        expect(find.byType(GameLobbyPage), findsNothing);
        expect(find.text('Open lobby'), findsOneWidget);
      },
    );
  }

  testWidgets('app lifecycle changes do not remove the player', (tester) async {
    final service = LobbyReader('guest');
    addTearDown(service.players.close);
    addTearDown(service.games.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GameLobbyPage(game: game, gameService: service),
      ),
    );
    service.players.add([host, guest]);
    await tester.pumpAndSettle();

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }

    expect(service.leaves, 0);
    expect(find.byType(GameLobbyPage), findsOneWidget);
  });

  testWidgets('a membership mismatch keeps the lobby open and explains why', (
    tester,
  ) async {
    final service = LobbyReader('changed-user')
      ..pendingLeave = Completer<void>();
    addTearDown(service.players.close);
    addTearDown(service.games.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GameLobbyPage(game: game, gameService: service),
      ),
    );
    service.players.add([host, guest]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('game-lobby-back-button')));
    service.pendingLeave!.completeError(
      const GameServiceException(
        GameServiceErrorCode.membershipMismatch,
        'Your player session no longer matches this game.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameLobbyPage), findsOneWidget);
    expect(
      find.text('Your player session no longer matches this game.'),
      findsOneWidget,
    );
  });

  testWidgets('player stream errors can be retried', (tester) async {
    final service = LobbyReader('guest');
    addTearDown(service.players.close);
    addTearDown(service.games.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GameLobbyPage(game: game, gameService: service),
      ),
    );
    service.players.addError(Exception('permission-denied'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load players. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    service.players.add([host, guest]);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(
      find.text('Could not load players. Please try again.'),
      findsNothing,
    );
    expect(service.subscriptions, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
