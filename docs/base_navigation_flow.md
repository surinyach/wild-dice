# Base Navigation Flow

This document explains what was implemented for the base navigation story and how the different parts work together. It is written as a simple guide that you can return to when the real Create Game and Join Game features are built.

## 1. Goal

The purpose of this task was to connect the main menu to two future areas of the app:

- Create Game.
- Join Game.

These areas are placeholders only. They show that navigation works, but they do not create a game, join a game, request a nickname, or request an avatar yet.

The completed user flow is:

```text
App starts
    |
    v
Main Menu
    |--------------------|
    v                    v
Create Game          Join Game
placeholder          placeholder
    |                    |
    v                    v
Back to Main Menu    Back to Main Menu
```

There are no dead ends because each placeholder has a custom back button that returns to the main menu.

## 2. Files Involved

The navigation flow uses these files:

```text
lib/
  app.dart
  core/
    routing/
      app_router.dart
  features/
    main_menu/
      presentation/pages/main_menu_page.dart
    create_game/
      presentation/pages/create_game_page.dart
    join_game/
      presentation/pages/join_game_page.dart
  shared/
    widgets/future_feature_page.dart

test/
  widget_test.dart
```

Each file has one clear responsibility:

- `app.dart` connects the Flutter app to the router.
- `app_router.dart` defines the available paths and builds the correct page.
- `main_menu_page.dart` starts navigation when a menu button is pressed.
- `create_game_page.dart` provides the content for the Create Game placeholder.
- `join_game_page.dart` provides the content for the Join Game placeholder.
- `future_feature_page.dart` contains the shared placeholder design.
- `widget_test.dart` checks that the complete flow works.

## 3. How the App Opens on the Main Menu

The `MaterialApp` in `lib/app.dart` contains:

```dart
initialRoute: AppRouter.mainMenu,
onGenerateRoute: AppRouter.onGenerateRoute,
```

`initialRoute` tells Flutter which screen to show first. `AppRouter.mainMenu` has the value `/`, so the application starts on the main menu.

`onGenerateRoute` tells Flutter to ask `AppRouter` to build a page whenever the application navigates to a named route.

## 4. Route Names

The paths are defined once in `lib/core/routing/app_router.dart`:

```dart
static const mainMenu = '/';
static const createGame = '/create-game';
static const joinGame = '/join-game';
```

Using constants is safer than typing route strings in several files. If a path needs to change later, it only needs to be changed in one place.

The router matches each path to its page:

```dart
final page = switch (settings.name) {
  mainMenu => const MainMenuPage(),
  createGame => const CreateGamePage(),
  joinGame => const JoinGamePage(),
  _ => null,
};
```

For example, when Flutter receives `/create-game`, the router builds `CreateGamePage`.

If an unknown route is requested, the router safely shows `MainMenuPage`. This prevents an invalid route from leaving the user on an error screen.

## 5. Navigating from the Main Menu

The two buttons in `main_menu_page.dart` call `Navigator.pushNamed`.

The Create Game button uses:

```dart
Navigator.of(context).pushNamed(AppRouter.createGame);
```

The Join Game button uses:

```dart
Navigator.of(context).pushNamed(AppRouter.joinGame);
```

`pushNamed` places the new page on top of the current page. You can imagine the navigation history as a stack of cards:

```text
Before pressing a button:

| Main Menu |

After pressing CREATE GAME:

| Create Game |
| Main Menu   |
```

The main menu stays underneath the placeholder instead of being destroyed. This is why returning to it is simple.

## 6. Returning to the Main Menu

Each placeholder has a custom back button in the top-left corner. It uses a large white arrow, a dark game-style background, and the page's accent color around its border. There is no text beside the button, which keeps the header clean.

The button calls `Navigator.maybePop()`. This removes the current placeholder from the navigation stack when a previous page is available:

```text
Before pressing Back:

| Create Game |
| Main Menu   |

After pressing Back:

| Main Menu |
```

The button has a `Back to main menu` tooltip for accessibility and a ripple animation that gives visual feedback when it is pressed. The Android system back button and Flutter's back gesture use the same navigation history, so they also return to the main menu.

## 7. Smooth Page Animation

The router uses `PageRouteBuilder` instead of the default route animation. The animation combines:

- A short fade.
- A small horizontal slide.
- An easing curve that makes the movement start quickly and finish gently.

Opening a page takes 320 milliseconds, while returning takes 240 milliseconds:

```dart
transitionDuration: const Duration(milliseconds: 320),
reverseTransitionDuration: const Duration(milliseconds: 240),
```

The reverse animation is automatically played when the user goes back. This keeps navigation smooth and consistent in both directions.

## 8. Placeholder Pages

`CreateGamePage` and `JoinGamePage` are intentionally small. They only provide the text, icon, and accent color that are different for each destination.

For example, `CreateGamePage` returns a `FutureFeaturePage` with Create Game information:

```dart
return const FutureFeaturePage(
  title: 'Create Game',
  message: 'Game creation is coming soon.',
  details: 'This is where you will set up a new game in a future update.',
  icon: Icons.add_circle_outline_rounded,
  accentColor: Color(0xFF8BCB2A),
);
```

`JoinGamePage` uses the same shared widget with different content and an orange accent color.

This gives each route its own page while avoiding duplicated layout code.

## 9. Shared Visual Design

`FutureFeaturePage` contains the complete placeholder layout used by both pages. It reuses:

- The global Flutter theme through `Theme.of(context)`.
- The jungle image used by the main menu.
- The same dark game-like color palette.
- The Baloo 2 font already used by the main menu.
- A colored accent that matches the corresponding main-menu button.

The page is built with a `Stack`:

1. The jungle image fills the screen.
2. A dark gradient improves text readability.
3. The placeholder card appears above the background.

The card is wrapped in `Center`, so it is horizontally and vertically centered. It also uses equal padding on every side:

```dart
padding: const EdgeInsets.all(24),
```

`SingleChildScrollView` is included so the page remains usable on a very small screen. If there is not enough vertical space, the user can scroll instead of seeing an overflow error.

The `COMING SOON` label clearly communicates that these screens are temporary and that the real functionality will be added later.

## 10. Automated Tests

The tests in `test/widget_test.dart` cover the acceptance criteria with three scenarios.

### Application startup

The first test verifies that the app opens with:

- The `WILD DICE` logo.
- The `CREATE GAME` button.
- The `JOIN GAME` button.

### Create Game flow

The second test:

1. Opens the app.
2. Presses `CREATE GAME`.
3. Checks the Create Game placeholder content.
4. Presses the custom `Back to main menu` button.
5. Confirms that both main-menu buttons are visible again.

### Join Game flow

The third test repeats the same process for `JOIN GAME`.

The project was verified with:

```bash
flutter analyze
flutter test
```

`flutter analyze` checks the Dart code for errors and lint problems. `flutter test` runs the automated widget tests.

## 11. Adding the Real Features Later

When Create Game or Join Game is implemented, the route names and main-menu buttons can stay the same. Only the content inside `CreateGamePage` or `JoinGamePage` needs to be replaced.

For example:

```text
Current:
CreateGamePage -> FutureFeaturePage

Later:
CreateGamePage -> Real create-game form and logic
```

This is the main benefit of the current structure: the app already has a stable navigation flow, while the temporary content can be replaced without changing how users reach the screen.

## 12. Summary

The application now:

- Opens on the Main Menu.
- Navigates to Create Game.
- Navigates to Join Game.
- Returns to the Main Menu from both pages.
- Uses smooth forward and backward animations.
- Keeps both placeholders centered and visually consistent.
- Clearly marks unfinished functionality as `COMING SOON`.
- Has automated coverage for every required navigation path.

Only placeholder UI was created. No game creation, game joining, nickname, or avatar functionality was added.
