# Game Service Guide

## Purpose

`GameService` centralizes all Flutter-side Firestore game operations. Its
implementation is in `lib/services/game_service.dart`. UI widgets call the
service instead of knowing collection paths, document fields, authentication,
transactions, or Firebase error types.

This work adds no UI, gameplay logic, Firebase Console configuration, or
Security Rules.

## Firestore Structure

```text
games/{gameId}
  code: string
  status: lobby | in_progress | finished | cancelled
  hostUid: string
  playerOrder: list of Firebase UIDs in join order
  currentRound: integer
  totalRounds: integer
  createdAt: server timestamp
  updatedAt: server timestamp

games/{gameId}/players/{playerId}
  ownerUid: string
  nickname: string
  avatarId: string
  score: integer
```

The Firebase UID is the player document ID. This ensures one membership
document per user and game.

The four supported game statuses are:

| Dart value | Firestore value | Meaning |
|------------|-----------------|---------|
| `GameStatus.lobby` | `lobby` | Players can gather before play begins. |
| `GameStatus.inProgress` | `in_progress` | The game is active. |
| `GameStatus.finished` | `finished` | The game completed normally. |
| `GameStatus.cancelled` | `cancelled` | The game was cancelled. |

Any other stored status is treated as a malformed game document.

## Authentication

Ownership and membership operations call
`FirebaseAuthService.ensureAnonymousUser()`:

1. Reuse the current Firebase user if a session exists.
2. Sign in anonymously if no user exists.
3. Use the resulting UID as the owner or player identity.
4. Return a consistent service error if authentication fails.

Widgets never access `FirebaseAuth.instance` directly.

## Creating a Game

```dart
final service = GameService();
final game = await service.createGame(
  nickname: 'Santi',
  avatarId: 'avatar_01',
  totalRounds: 5,
);
```

Creation follows these steps:

1. Ensure a Firebase user exists.
2. Generate a five-character uppercase join code such as `A7K92`.
3. Check whether the code is already used.
4. Retry up to eight times after collisions.
5. Create the game in `lobby` with `currentRound: 0`, the requested total
   rounds, the host UID, and server timestamps.
6. Create the host player with their UID, nickname, avatar, and `score: 0` in
   the same atomic batch.
7. Read and return the stored document as a `Game`.

A caller may pass `code: 'wild42'`. The code is trimmed and
normalized to `WILD42`. An existing code produces `joinCodeUnavailable`.

The client check provides practical collision avoidance, not a strict database
unique constraint. A future backend change can add code-reservation documents
if strict concurrent uniqueness is required.

## Finding a Game by Code

```dart
final game = await service.findGameByJoinCode(userInput);
if (game == null) {
  // No matching game exists.
}
```

The input is trimmed and uppercased, then Firestore is queried by `code`
with a one-document limit. The method returns `null` when no game matches. An
empty code produces `invalidArgument`.

## Joining a Game

```dart
await service.joinGame(
  game.id,
  nickname: 'Miquel',
  avatarId: 'avatar_01',
);
```

The service validates the ID, ensures authentication, and starts a transaction.
It reads the game and player, produces `gameNotFound` when the game is absent,
requires lobby status, then merges a player document identified by the current
UID. New players start with `score: 0`; existing scores survive a repeated join. The transaction also
appends the UID to `playerOrder` only if absent and updates `updatedAt`.

## Listening to Game Changes

```dart
final subscription = service.watchGame(game.id).listen(
  (updatedGame) {
    if (updatedGame == null) {
      // The game was deleted or does not exist.
      return;
    }
    // Update application state.
  },
  onError: (Object error) {
    // Present or log the service error.
  },
);
```

Firestore emits a snapshot whenever the game changes. The stream emits `null`
when the document is absent or deleted. Cancel a manual subscription when the
consumer is disposed:

```dart
await subscription.cancel();
```

A `StreamBuilder<Game?>` may consume the stream, but should only render its
state. Firestore mapping remains inside the service.

## Listening to Player Changes

```dart
final playersStream = service.watchPlayers(game.id);
```

This watches `games/{gameId}/players` and emits an immutable
`List<GamePlayer>`. Players are ordered by document ID for stable output. A
new list is emitted when a player joins, leaves, or changes stored data.

Each player provides:

- `id`: the Firebase UID and player document ID.
- `data`: an immutable map containing all player fields.

## Leaving a Game

```dart
await service.leaveGame(game.id);
```

The service uses a transaction to require lobby status, remove the current UID
from `playerOrder`, delete their player document, and update `updatedAt`.
The first remaining player becomes host. If no players remain, the game becomes
`cancelled` and retains the previous host UID, matching the Firebase rules.

## Returned Models

`Game` exposes:

- `id`: the Firestore document ID.
- `code`: the normalized join code.
- `status`: a validated `GameStatus`.
- `hostUid`: the creator's Firebase UID.
- `currentRound`: the active round number.
- `totalRounds`: the configured round count.
- `data`: an immutable map of the complete document.

`GamePlayer` exposes `id`, `ownerUid`, `nickname`, `avatarId`,
`score`, and the immutable player data. Both factories validate their required
fields, so malformed documents become service errors rather than late UI cast
errors.

## Consistent Error Handling

Every operation exposes `GameServiceException`. Its `code` supports
user-facing decisions, while `cause` retains the original error for logging.

| Code | Meaning |
|------|---------|
| `authentication` | Firebase Authentication failed. |
| `invalidArgument` | A join code or game ID is invalid. |
| `gameNotFound` | The requested game does not exist. |
| `joinCodeUnavailable` | A join code could not be used. |
| `firestore` | A Firebase or Firestore operation failed. |
| `unknown` | An unexpected non-Firebase error occurred. |

```dart
try {
  await service.joinGame(
    gameId,
    nickname: nickname,
    avatarId: avatarId,
  );
} on GameServiceException catch (error) {
  switch (error.code) {
    case GameServiceErrorCode.gameNotFound:
      // Inform the user that the game has closed.
      break;
    default:
      // Show a retry message and log error.cause.
      break;
  }
}
```

Realtime failures use the same exception type and arrive through the stream's
error channel.

## Dependency Injection and Testing

Production code uses `GameService()`. Tests can inject dependencies:

```dart
final service = GameService(
  firestore: testFirestore,
  authService: testAuthService,
  random: seededRandom,
);
```

Injection avoids global Firebase dependencies in tests and allows deterministic
code generation.

The service tests use:

- `fake_cloud_firestore` for an isolated in-memory Firestore implementation.
- `firebase_auth_mocks` for a signed-in anonymous Firebase user.

No test connects to a real Firebase project. The suite covers the exact game
and player schemas, generated and normalized codes, joining and rejoining,
score preservation, missing games, game and player streams, leaving, invalid
statuses, and argument validation.

Run only the service tests with:

```bash
flutter test test/services/game_service_test.dart
```

## Recommended UI Integration

A controller, view model, or state-management layer should:

1. Read and validate raw form input.
2. Call the appropriate service operation.
3. Convert service exceptions into presentation state.
4. Subscribe to game and player streams.
5. Dispose subscriptions when leaving the screen.

Widgets should not call `FirebaseFirestore.instance`, construct database
paths, parse snapshots, or catch raw Firebase exceptions.

## Verification and Delivery

The implementation was checked with:

```bash
flutter analyze
flutter test
```

Static analysis found no issues and all existing tests passed.

The work belongs on `feature/game-service` and targets `develop`. Commit,
push, pull-request review, and merge are repository workflow steps. None of
these require Firebase Console or Security Rules changes.

## Starting a Game

`GameSession` exposes the authenticated user ID, the existing `watchGame`
stream, and `startGame(gameId)` for the lobby. `GameService` implements it.
Starting uses a transaction that checks the authenticated host and changes
`lobby` to `in_progress`, updating `updatedAt`. An already started game is a
no-op; finished/cancelled games produce `invalidState`, and other users receive
`notHost`. Rounds and players remain unchanged.

The lobby subscribes on entry and cancels on disposal. Both hosts and guests
replace the lobby route with a gameplay placeholder when the stream reports
`in_progress`. The start button is disabled until the stream is ready, for
non-hosts, and while starting. Update failures show a retryable error; stream
failures expose a resubscribe action. Navigation follows the shared stream.

The current Join Game page is still a placeholder. Guest transition behavior
is covered by opening the lobby directly in widget tests; end-to-end joining
requires that separate flow. No Firebase configuration or rules are changed.
