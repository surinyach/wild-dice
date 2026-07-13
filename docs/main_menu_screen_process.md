# Main Menu Screen Implementation Process

This document explains the process followed to build the current main menu screen for the game app. It covers the user story, final structure, visual decisions, assets, navigation, animations, responsiveness, and verification.

## 1. Goal

The objective was to create a polished main menu screen where the user can quickly start the main flows:

- Create a game.
- Join a game.

The screen needed to feel like a premium mobile game menu, not a default Material Design screen. The final visual direction became a jungle-themed game screen with a large custom `WILD DICE` title logo, a tropical background, and two large 3D call-to-action buttons.

## 2. Main Files

The implementation is mainly contained in:

- `lib/features/main_menu/presentation/pages/main_menu_page.dart`
- `lib/features/main_menu/presentation/pages/action_placeholder_page.dart`
- `lib/core/routing/app_router.dart`
- `lib/app.dart`
- `assets/images/main_menu_jungle.png`
- `assets/images/wild_dice_logo.png`
- `test/widget_test.dart`

The final image assets are registered through the existing `assets/images/` entry in `pubspec.yaml`.

Architecture note: this screen follows the project guideline in `docs/flutter_architecture.md`. `main_menu` currently only has a `presentation` layer because it is a UI-focused feature with no backend communication or reusable business logic yet. `domain` and `data` should be added later only when a feature needs them.

## 3. Screen Entry Point

The app opens on the main menu through the route configuration.

In `lib/app.dart`, the app uses:

```dart
initialRoute: AppRouter.mainMenu,
routes: AppRouter.routes,
```

The route itself is defined in `AppRouter`, where the main menu route points to `MainMenuPage`.

This satisfies the requirement that the main menu appears when the app opens.

## 4. Main Menu Layout

The main menu is implemented with a `Scaffold` and a full-screen `Stack`.

The stack contains:

- A full-screen jungle background image.
- A `SafeArea` content layer.
- A centered constrained layout so the UI works on mobile and web widths.

The main content is arranged with a `Column`:

- Flexible space above.
- The animated `WILD DICE` logo.
- The Create Game button.
- The Join Game button.
- Flexible space below.

This keeps the layout simple, centered, and responsive.

## 5. Background

The background is handled by `_JungleBackgroundImage`.

It loads:

```dart
assets/images/main_menu_jungle.png
```

The image is rendered with:

```dart
fit: BoxFit.cover
```

This allows it to fill different screen sizes without stretching.

A dark gradient overlay is placed above the image so the logo and buttons remain readable on top of the background.

If the image fails to load, the screen falls back to a custom-painted `_NightCityBackdrop`, so the app still has a visual background instead of showing a blank screen.

## 6. Title Logo

The final title is an image asset:

```dart
assets/images/wild_dice_logo.png
```

The logo was generated as a high-end square game logo with:

- The text `WILD DICE`.
- Sandstone-style `WILD` letters.
- Golden carved-stone `DICE` letters.
- Tropical leaves and vines around the title.
- A stone die at the bottom.

After generation, the flat warm background behind the logo was removed locally so the logo has transparent corners and fits naturally over the jungle main menu background.

The title is displayed by `_GeneratedWildDiceLogo`, which wraps the image in:

- `Semantics(label: 'WILD DICE')`
- `ExcludeSemantics`
- `RepaintBoundary`
- `Image.asset`

The semantic label helps tests and accessibility identify the title without exposing duplicated image internals.

## 7. Logo Animation

The logo is displayed through `AnimatedLogo`.

It uses:

- `FadeTransition`
- `SlideTransition`
- `CurvedAnimation`

The logo starts slightly above its final position and fades/slides into place when the screen opens.

This satisfies the subtle entrance animation requirement.

## 8. Main Buttons

The main buttons are implemented with the reusable `GameButton` widget.

The same widget is used for:

- `CREATE GAME`
- `JOIN GAME`

The widget keeps the original behavior simple:

```dart
onPressed: () => Navigator.of(context).pushNamed(...)
```

The visual style was upgraded to look like AAA mobile game UI rather than standard Material buttons.

Each button uses multiple visual layers:

- Outer shadow.
- Colored vertical gradient.
- Border.
- Inner bevel overlay.
- Top highlight line.
- Darker bottom edge.
- Cream-colored icon and text.
- Press scale feedback.

The Create Game button uses a green palette:

- Top: `#8BCB2A`
- Middle: `#6FAE19`
- Bottom: `#5A930F`
- Border: `#4D7A10`

The Join Game button uses an orange palette:

- Top: `#F2B129`
- Middle: `#E08B13`
- Bottom: `#C36D08`
- Border: `#8C5208`

## 9. Button Press Feedback

The button press effect is handled with:

```dart
Listener
AnimatedScale
```

When the pointer is pressed, the button scales down slightly:

```dart
scale: _isPressed ? 0.96 : 1
```

This creates a tactile game-button feel.

## 10. Navigation

The two buttons navigate to placeholder screens:

- Create Game button navigates to `AppRouter.createGame`.
- Join Game button navigates to `AppRouter.joinGame`.

The placeholder pages live in:

```text
lib/features/main_menu/presentation/pages/action_placeholder_page.dart
```

This keeps the current story scoped to the main menu while still proving that navigation works.

## 11. Removed Elements During Iteration

Several elements were tested and then removed to simplify the final screen:

- Settings button at the top.
- Three small bottom icon buttons.
- Subtitle text.
- Middle tuk-tuk mascot/logo.
- Extra decorative leaves on the main buttons.

The final screen focuses only on:

- Background.
- Title logo.
- Create Game button.
- Join Game button.

This makes the screen clearer and more game-like.

## 12. Responsiveness

The layout adapts based on height:

```dart
final compact = constraints.maxHeight < 700;
```

This affects:

- Padding.
- Logo size.
- Button height.
- Spacing.

The content is also constrained to a maximum width:

```dart
BoxConstraints(maxWidth: 460)
```

This keeps the menu readable on wider web screens while still fitting mobile screens.

## 13. Assets

Current relevant assets:

```text
assets/images/main_menu_jungle.png
assets/images/wild_dice_logo.png
```

The jungle background is used as the full-screen background.

The logo image is used as the title and has a transparent background so it blends with the jungle scene.

Temporary image files created during validation were removed from the project.

## 14. Testing

The widget test verifies:

- The main menu loads.
- The `WILD DICE` title semantic label exists.
- The Create Game button exists.
- The Join Game button exists.
- Create Game navigation opens the create placeholder.
- Join Game navigation opens the join placeholder.

The test file is:

```text
test/widget_test.dart
```

## 15. Verification Commands

The final implementation was verified with:

```bash
flutter analyze
flutter test
```

Both commands passed after the final changes.

## 16. Final Result

The final main menu screen includes:

- A full-screen jungle background.
- A large premium `WILD DICE` game logo.
- Two clear main actions.
- Game-style 3D buttons.
- Press feedback.
- Entrance animation.
- Placeholder navigation.
- Responsive mobile/web layout.

The current screen is focused, playful, and understandable, while leaving nickname/avatar selection for a later game-entry flow.
