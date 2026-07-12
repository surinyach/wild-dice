# Project File Walkthrough

This document explains what each important file does, how the app starts, how the screen is built, and why the folders are organized this way.

It is written as a beginner-friendly map of the current project.

## 1. Big Picture

This is a Flutter app. Flutter apps are built from widgets.

A widget is a piece of UI. A whole screen is a widget. A button is a widget. Text is a widget. Even the app itself is a widget.

The current app starts on the main menu screen. That screen shows:

- A jungle background image.
- A `WILD DICE` logo image.
- A `CREATE GAME` button.
- A `JOIN GAME` button.

When you press either button, the app navigates to a temporary placeholder page. Those placeholder pages exist so the app already has working navigation before the real create/join game flows are built.

## 2. Main Folder Structure

The important folders are:

```text
lib/
  main.dart
  app.dart
  core/
  features/
  shared/

assets/
  images/

docs/

test/
```

### `lib/`

This is where the Dart application code lives.

Most future work will happen here.

### `assets/`

This is where images, sounds, fonts, and other non-code files live.

The current app uses:

```text
assets/images/main_menu_jungle.png
assets/images/wild_dice_logo.png
```

### `docs/`

This is project documentation. It explains decisions and implementation details.

### `test/`

This is where automated tests live.

The current test checks that the main menu appears and that the two buttons navigate correctly.

## 3. How The App Starts

The startup flow is:

```text
lib/main.dart
  -> runs App from lib/app.dart
    -> App creates MaterialApp
      -> MaterialApp uses AppRouter
        -> AppRouter opens MainMenuPage
```

So the path is:

1. `main.dart` is the first file Flutter runs.
2. `main.dart` starts the `App` widget.
3. `App` creates the global Flutter app configuration.
4. `AppRouter` decides which screen belongs to each route.
5. The first route is `/`, which opens `MainMenuPage`.

## 4. App Files

### `lib/main.dart`

This is the app entry point.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
```

What it does:

- `main()` is the first function Flutter runs.
- `WidgetsFlutterBinding.ensureInitialized()` prepares Flutter before the UI starts.
- `runApp(const App())` tells Flutter to display the `App` widget.

Why it exists:

Every Flutter app needs a starting point. This file should usually stay small.

### `lib/app.dart`

This file defines the root app widget.

It creates a `MaterialApp`, which is Flutter's main app container for Material Design apps.

Important parts:

```dart
return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Aguántame El Cubata',
  theme: AppTheme.light,
  initialRoute: AppRouter.mainMenu,
  routes: AppRouter.routes,
);
```

What it does:

- Hides the debug banner.
- Sets the app title.
- Applies the global theme.
- Sets the first screen with `initialRoute`.
- Registers all named routes.

Why it exists:

This keeps global app configuration in one clear place.

Note: if you see the title displayed incorrectly in code, it is probably an encoding issue with the accented text. The intended title is `Aguántame El Cubata`.

## 5. Core Files

The `core` folder contains app-wide infrastructure. Code here is not owned by one feature.

### `lib/core/routing/app_router.dart`

This file defines route names and connects them to pages.

Routes are like addresses inside the app.

Current routes:

```dart
static const mainMenu = '/';
static const login = '/login';
static const createGame = '/create-game';
static const joinGame = '/join-game';
```

The route map says which widget opens for each route:

```dart
mainMenu: (_) => const MainMenuPage(),
login: (_) => const LoginPage(),
createGame: (_) => const ActionPlaceholderPage(...),
joinGame: (_) => const ActionPlaceholderPage(...),
```

What it does:

- `/` opens the main menu.
- `/login` opens the temporary login page.
- `/create-game` opens a placeholder for creating a game.
- `/join-game` opens a placeholder for joining a game.

Why it exists:

It prevents route strings from being scattered everywhere. Instead of typing `'/create-game'` in many files, the app uses `AppRouter.createGame`.

### `lib/core/theme/app_theme.dart`

This file defines the app's shared visual theme.

It currently sets:

- The main color scheme.
- Default button corner radius.
- Material 3 usage.

What it does:

Flutter widgets can read this theme with:

```dart
Theme.of(context)
```

Why it exists:

It gives the app a consistent base style. Individual game screens can still have custom visuals, but shared screens and default widgets get a common look.

## 6. Feature Folders

The app uses feature-first organization.

That means code is grouped by product area:

```text
lib/features/auth/
lib/features/main_menu/
```

This is explained in more detail in:

```text
docs/flutter_architecture.md
```

The short version:

- A feature is a meaningful user flow or product area.
- We do not create a folder for every task.
- We do not create a folder for every single screen.
- We add `domain` and `data` only when the feature actually needs business logic or backend communication.

## 7. Auth Feature

### `lib/features/auth/presentation/pages/login_page.dart`

This is a temporary login screen.

It shows:

- An app bar with `Login`.
- Center text saying `Login page`.

What it does:

Right now, not much. It is a placeholder.

Why it exists:

It lets the router already have a login route, even though real authentication has not been built yet.

Future version:

When real login exists, this feature may grow into:

```text
auth/
  presentation/
  domain/
  data/
```

But only when login has real backend/session logic.

## 8. Main Menu Feature

Current folder:

```text
lib/features/main_menu/
  presentation/
    pages/
    widgets/
```

This feature currently only has `presentation` because it is mostly UI.

There is no backend call, no stored data, and no business rules yet.

### `lib/features/main_menu/presentation/pages/main_menu_page.dart`

This is the main file for the current menu screen.

It contains the page, background, logo display, buttons, animations, and some older helper widgets.

#### `MainMenuPage`

This is the route-level page widget.

```dart
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainMenu();
  }
}
```

What it does:

- Acts as the screen that the router opens.
- Returns the actual `MainMenu` widget.

Why it exists:

It gives routing a clean page entry point.

#### `MainMenu`

This is the real main menu widget.

It is a `StatefulWidget` because it has animation state.

It uses:

```dart
with TickerProviderStateMixin
```

That allows the widget to run an animation controller.

#### `_entranceController`

This controls the entrance animation when the screen opens.

```dart
_entranceController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 850),
)..forward();
```

What it does:

- Starts at 0.
- Animates to 1.
- Other widgets use this value to fade and slide in.

Why it exists:

It makes the logo and buttons appear with polish instead of instantly popping onto the screen.

#### `LayoutBuilder`

The main menu uses `LayoutBuilder` to check the available screen height.

```dart
final compact = constraints.maxHeight < 700;
```

What it does:

- If the screen is short, the layout uses smaller spacing and logo sizes.
- If the screen is taller, it uses the larger layout.

Why it exists:

It helps the screen fit both mobile and web windows.

#### `Scaffold`

`Scaffold` is the standard page structure widget in Flutter.

This screen uses it mainly to provide a full-screen body.

#### `Stack`

The page uses a `Stack` because the UI has layers.

The layers are:

1. Background image.
2. Dark overlay on top of the background.
3. Main content with logo and buttons.

#### `_JungleBackgroundImage`

This widget displays:

```text
assets/images/main_menu_jungle.png
```

It uses:

```dart
fit: BoxFit.cover
```

What it does:

- Makes the image fill the whole screen.
- Crops if needed instead of stretching.

It also has an `errorBuilder`.

If the image fails to load, Flutter shows `_NightCityBackdrop` instead of a broken/blank screen.

#### `_NightCityBackdrop`

This is a fallback background made with `CustomPaint`.

It is not the normal background anymore. It exists as a backup.

#### `_NightCityBackdropPainter`

This draws the fallback background directly on a canvas.

It uses shapes, gradients, buildings, lights, and a road.

Why it exists:

It was likely created before the final jungle image asset existed, and it still works as a fallback if the asset fails.

#### `AnimatedLogo`

This wraps the logo in a fade and slide animation.

It uses:

- `FadeTransition`
- `SlideTransition`
- `CurvedAnimation`

What it does:

- The logo starts slightly higher.
- It fades in.
- It slides down into position.

#### `_GeneratedWildDiceLogo`

This displays the final logo image:

```text
assets/images/wild_dice_logo.png
```

It wraps the image with:

- `Semantics(label: 'WILD DICE')`
- `ExcludeSemantics`
- `RepaintBoundary`

What those mean:

- `Semantics` gives the image an accessibility/test label.
- `ExcludeSemantics` prevents inner image details from being read twice.
- `RepaintBoundary` helps Flutter isolate the logo for rendering performance.

#### `_ButtonsEntrance`

This animates the button group.

It uses the same `_entranceController`, but with a delayed interval:

```dart
Interval(0.24, 1, curve: Curves.easeOutCubic)
```

What it does:

- The logo starts first.
- The buttons begin slightly later.

#### `GameButton`

This is the custom main menu button.

It is used for:

- `CREATE GAME`
- `JOIN GAME`

Each button receives:

```dart
label
icon
color
onPressed
```

The current button visuals are custom built with:

- Gradients.
- Borders.
- Shadows.
- Highlights.
- Press animation.
- Text styling.

#### `_GameButtonState`

This stores whether the button is currently pressed.

```dart
bool _isPressed = false;
```

When the pointer goes down, `_isPressed` becomes `true`.

When the pointer goes up or cancels, `_isPressed` becomes `false`.

The button then uses:

```dart
AnimatedScale(
  scale: _isPressed ? 0.96 : 1,
)
```

What it does:

The button shrinks slightly while pressed, like a tactile game button.

#### `_GameButtonPalette`

This chooses the colors for the button based on its label.

If the label contains `CREATE`, it uses the green palette.

Otherwise, it uses the orange palette.

Why it exists:

It keeps color choices separated from the button layout code.

#### `_ButtonLabelText`

This draws the text inside the button.

It uses the `Baloo 2` font from `google_fonts`.

#### `Navigator.of(context).pushNamed(...)`

This is how the buttons change screen.

Create Game uses:

```dart
Navigator.of(context).pushNamed(AppRouter.createGame)
```

Join Game uses:

```dart
Navigator.of(context).pushNamed(AppRouter.joinGame)
```

What happens:

1. The button is tapped.
2. Flutter asks `AppRouter` what widget belongs to that route.
3. Flutter pushes that new page on top of the current page.

#### Other classes in `main_menu_page.dart`

This file also contains some widgets that are not currently visible in the final screen:

- `ConfettiBackground`
- `_ConfettiPainter`
- `AnimatedTukTuk`
- `_TukTukPlaceholder`
- `_TukTukPainter`
- `_ButtonLeafCluster`
- `BottomMenu`
- `_RoundMenuButton`
- `_SettingsButton`

These look like earlier visual experiments or helper widgets from previous versions of the menu.

They are not part of the current final visible screen unless they are added back into `MainMenu.build`.

Why this matters:

When you are reading Flutter code, the most important thing is not only "what classes exist", but "which widgets are actually returned from `build()`". If a widget class exists but is never used in the active build tree, the user will not see it.

### `lib/features/main_menu/presentation/pages/action_placeholder_page.dart`

This is the temporary page used by both main menu buttons.

It receives:

```dart
title
message
icon
```

That lets the same page show different content for Create Game and Join Game.

What it shows:

- An app bar.
- A circular icon.
- A title.
- A message.

Why it exists:

The real create/join game screens are not built yet. This page proves that navigation works and gives users a clear temporary destination.

## 9. Main Menu Widgets Folder

There are three files in:

```text
lib/features/main_menu/presentation/widgets/
```

Important note: these are currently not imported by the active `main_menu_page.dart`.

That means they are not currently used by the visible screen.

They may be older versions, reusable experiments, or candidates for cleanup/refactor later.

### `loco_reto_logo.dart`

This defines `LocoRetoLogo`, a custom-painted logo with:

- `TUK TUK`
- `GAME`
- Confetti.
- A small tuk-tuk mascot.

It uses `CustomPainter`, meaning it draws shapes directly on the canvas.

Current status:

Not used by the active main menu.

### `pressable_scale_button.dart`

This defines `PressableScaleButton`.

It is a reusable button that scales down when pressed.

It supports:

- Primary style.
- Secondary style.
- Icon.
- Label.
- Press animation.

Current status:

Not used by the active main menu. The active menu uses `GameButton` inside `main_menu_page.dart` instead.

### `wild_dice_logo.dart`

This defines a fully custom-painted `WildDiceLogo`.

It draws the logo using Dart canvas commands instead of loading an image.

It includes:

- Leaves.
- Text.
- A die.
- Floating animation.
- Glow animation.

Current status:

Not used by the active main menu. The active menu uses the image asset `assets/images/wild_dice_logo.png` instead.

## 10. Shared Folder

### `lib/shared/widgets/.gitkeep`

This file exists only to keep an empty folder in Git.

Git normally ignores empty folders. A `.gitkeep` file is a common convention to make Git track the folder.

What this folder is for:

Future widgets that are truly shared across multiple features.

Example:

```text
shared/widgets/app_loading_indicator.dart
```

But we should not move things here too early. If only one feature uses a widget, it should stay inside that feature.

## 11. Assets

### `assets/images/main_menu_jungle.png`

This is the full-screen jungle background image.

Used by:

```text
_JungleBackgroundImage
```

### `assets/images/wild_dice_logo.png`

This is the final `WILD DICE` logo image.

Used by:

```text
_GeneratedWildDiceLogo
```

### `assets/images/.gitkeep`

Keeps the image folder tracked by Git.

## 12. Pubspec

### `pubspec.yaml`

This is Flutter's project configuration file.

It declares:

- Project name.
- Dependencies.
- Dev dependencies.
- Flutter asset folders.

Important current dependency:

```yaml
google_fonts: ^6.3.2
```

This lets the app use fonts from the `google_fonts` package.

Important asset registration:

```yaml
assets:
  - assets/images/
```

Why it matters:

Flutter will not load assets unless they are registered in `pubspec.yaml`.

### `pubspec.lock`

This records the exact versions of installed packages.

You usually do not edit this manually.

## 13. Tests

### `test/widget_test.dart`

This is an automated widget test.

It starts the app:

```dart
await tester.pumpWidget(const App());
```

Then it checks:

- The `WILD DICE` semantic label exists.
- The `CREATE GAME` button exists.
- The `JOIN GAME` button exists.

Then it taps Create Game and expects the create placeholder message.

Then it goes back, taps Join Game, and expects the join placeholder message.

Why it exists:

It protects the most important current behavior: the main menu loads and both buttons navigate.

## 14. Documentation Files

### `docs/main_menu_screen_process.md`

Explains the process used to build the current main menu.

This is more like a development story: what was built, what was removed, what assets were used, and how it was verified.

### `docs/flutter_architecture.md`

Explains the folder architecture rules for future development.

The most important rule:

Do not create folders just because a task exists. Create folders when there is a real feature, layer, or shared responsibility.

### `docs/project_file_walkthrough.md`

This file.

It explains what the current files do and how they connect.

## 15. Platform Folders

These folders are created by Flutter:

```text
android/
ios/
linux/
macos/
web/
windows/
```

They contain platform-specific runner projects.

Most of the time, you do not touch them while building normal Flutter screens.

You might edit them later for:

- App icons.
- Splash screens.
- Permissions.
- Firebase/native setup.
- Platform-specific configuration.

## 16. Generated And Tool Folders

### `.dart_tool/`

Generated by Dart and Flutter tooling.

Do not edit manually.

### `build/`

Generated build output.

Do not edit manually.

### `.flutter-plugins-dependencies`

Generated plugin metadata.

Do not edit manually.

### `.metadata`

Flutter project metadata.

Usually do not edit manually.

## 17. How To Read The Main Menu Code

If you want to understand the main menu, read it in this order:

1. `lib/app.dart`
2. `lib/core/routing/app_router.dart`
3. `lib/features/main_menu/presentation/pages/main_menu_page.dart`
4. `lib/features/main_menu/presentation/pages/action_placeholder_page.dart`
5. `test/widget_test.dart`

Inside `main_menu_page.dart`, read:

1. `MainMenuPage`
2. `MainMenu`
3. `_JungleBackgroundImage`
4. `AnimatedLogo`
5. `_GeneratedWildDiceLogo`
6. `_ButtonsEntrance`
7. `GameButton`
8. `_GameButtonPalette`

That is the active path for what you see on screen.

## 18. Why The App Is Structured This Way

The current structure is intentionally simple.

The main menu only has:

```text
presentation/
```

Because the main menu is currently just UI.

It does not need:

```text
domain/
data/
```

yet.

Later, features like lobby, game, challenges, or authentication may need those layers.

Example:

```text
lib/features/lobby/
  presentation/
  domain/
  data/
```

Why:

- `presentation` shows the screens.
- `domain` defines app rules like room codes or lobby state.
- `data` talks to the backend.

This keeps the code clean without overcomplicating the project too early.

## 19. Current Improvement Opportunity

There are some unused widgets in the main menu feature.

They are not harmful, but they can confuse someone learning the project because they look important even though the active screen does not use them.

Later, we can either:

- Delete them if they are no longer needed.
- Move useful ones into smaller files.
- Replace duplicated code with reusable widgets.

For now, the safest way to understand the app is to follow what is imported and returned from `build()` methods.
