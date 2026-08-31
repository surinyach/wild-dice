# Local assets setup

## Overview

This document describes the implementation completed for the `feature/local-assets-setup` user story. The goal was to bundle player avatars and default challenge data directly with the Flutter application, without Firebase Storage or another external file service.

The implementation is intentionally limited to asset definition, loading, parsing, validation, and verification. It does not implement challenge selection, game rules, player assignment, or custom challenge persistence.

## Why these assets are bundled locally

The avatars and default challenges are application defaults. They must be available immediately after installation, including before sign-in and without network connectivity. Bundling them with Flutter provides the following benefits:

- The same files are available on every supported Flutter platform.
- Loading does not depend on connectivity, authentication, Firebase configuration, or storage rules.
- Default content is versioned together with the source code.
- There is no download, cache, retry, or synchronization logic to maintain.
- Firestore can store stable IDs such as `avatar_01` instead of binary image data or local paths.

This applies only to built-in content. Player-created challenges remain dynamic data and belong in Firestore. The application does not modify `challenges.json` at runtime.

## Resulting structure

```text
assets/
|-- avatars/
|   |-- avatar_01.png
|   |-- avatar_02.png
|   |-- avatar_03.png
|   |-- avatar_04.png
|   |-- avatar_05.png
|   |-- avatar_06.png
|   |-- avatar_07.png
|   |-- avatar_08.png
|   |-- avatar_09.png
|   `-- avatar_10.png
`-- data/
    `-- challenges.json

lib/
|-- core/assets/
|   `-- app_assets.dart
`-- features/challenges/
    |-- data/
    |   `-- local_challenge_repository.dart
    `-- domain/
        `-- challenge.dart

test/
`-- local_assets_test.dart
```

The asset folders are separated by responsibility. `assets/avatars/` contains player-profile images, while `assets/data/` contains structured static data. This also keeps data files separate from the general artwork already stored in `assets/images/`.

The Dart code follows a lightweight feature-oriented structure:

- `core/assets/` owns application-wide asset identifiers and paths.
- `features/challenges/domain/` owns the typed challenge representation.
- `features/challenges/data/` owns the Flutter-specific asset loading process.
- `test/` verifies both the physical bundle and the parsing boundary.

## Flutter asset registration

The required directories were added under `flutter.assets` in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/avatars/
    - assets/data/
```

Registering directories rather than every file keeps the manifest minimal. A file added inside one of these folders is included in the Flutter bundle without another `pubspec.yaml` entry.

Bundle registration and application availability are separate concerns. A file may be included by Flutter but should only be offered to users after it has a stable entry in the Dart registry. This prevents accidental or unfinished files from becoming selectable merely because they exist in the directory.

## Stable ID conventions

Asset identifiers use lowercase names, underscore separators, and zero-padded sequential numbers:

```text
avatar_01
avatar_02
...
avatar_10

challenge_001
challenge_002
challenge_003
```

The ID is intentionally independent of visible content. For example, Firestore should store `avatar_04`, not `wolf` and not `assets/avatars/avatar_04.png`.

This separation creates a stable persistence contract:

- Artwork can be replaced without rewriting stored player documents.
- Paths can be reorganized behind the registry.
- UI labels can be localized without changing persisted data.
- Database data does not depend on Flutter-specific bundle paths.

IDs are case-sensitive. After release, an ID should not be reused for a different persisted identity. New IDs should continue the zero-padded sequence.

## Central asset registry

`lib/core/assets/app_assets.dart` is the authoritative mapping between stable IDs and Flutter paths:

```dart
abstract final class AppAssets {
  static const challenges = 'assets/data/challenges.json';

  static const avatars = <String, String>{
    'avatar_01': 'assets/avatars/avatar_01.png',
    // ...
    'avatar_10': 'assets/avatars/avatar_10.png',
  };
}
```

`abstract final` makes `AppAssets` a non-instantiable namespace. The values are compile-time constants.

Centralization avoids scattering raw path strings across widgets, repositories, and services. A consumer can resolve a stored ID with `AppAssets.avatars[avatarId]`. An unknown ID returns `null`, allowing the presentation layer to use a deliberate fallback instead of constructing an invalid path.

## Avatar catalog

The development bundle contains ten PNG avatars:

| ID | Subject |
| --- | --- |
| `avatar_01` | Threatening jaguar |
| `avatar_02` | Threatening black panther |
| `avatar_03` | Friendly koala |
| `avatar_04` | Wolf howling toward the moon |
| `avatar_05` | Frog on a water lily catching a fly |
| `avatar_06` | Crocodile half-hidden in water and poised to attack |
| `avatar_07` | Colorful toucan perched on a branch |
| `avatar_08` | Playful monkey making silly arm gestures |
| `avatar_09` | Panda eating bamboo |
| `avatar_10` | Threatening snake coiled around a branch |

These files provide useful development content but are not treated as final production artwork. Their IDs already follow the persistence convention, so artwork may be replaced later without changing player references.

## Default challenge data

`assets/data/challenges.json` contains three built-in samples. The root is a JSON array, and each entry contains the required fields:

```json
{
  "id": "challenge_001",
  "text": "Do 10 squats",
  "type": "normal"
}
```

| Field | JSON type | Purpose |
| --- | --- | --- |
| `id` | string | Stable identifier for the bundled challenge |
| `text` | string | Player-facing challenge instruction |
| `type` | string | Category used to interpret the challenge |

The initial dataset contains one sample for each supported type:

- `normal`: a standard challenge.
- `wild`: a less conventional or group-driven challenge.
- `pvp`: a challenge between exactly two players.

PvP data does not store player count or team size. The requirement defines PvP as always one-versus-one, so an additional field would be redundant and could introduce invalid combinations.

## Typed challenge domain model

`lib/features/challenges/domain/challenge.dart` converts untyped JSON into application-domain values.

### ChallengeType

```dart
enum ChallengeType {
  normal,
  wild,
  pvp;
}
```

An enum prevents arbitrary strings from spreading through application logic. Consumers work with a finite, compiler-known set of types rather than repeatedly comparing text values.

The structure remains extensible: a future sprint can add an enum member and its behavior without changing the existing JSON shape. `ChallengeType.fromJson` matches JSON text against the enum names and throws `FormatException` for unsupported values.

Rejecting unknown values at the data boundary is intentional. Silently accepting a category that the app cannot interpret would move the failure into later game code, where it would be harder to diagnose.

### Challenge

`Challenge` is immutable. Its constructor requires `id`, `text`, and `type`, and its fields are `final`.

`Challenge.fromJson` verifies that all three incoming values are strings before constructing the model. Missing fields, `null`, numbers, objects, and arrays are rejected with a descriptive `FormatException`.

The model currently validates the required structure and supported category. Stronger content policies, such as rejecting blank text or enforcing an ID regular expression, can be introduced when product requirements define those rules.

## Loading and parsing

`lib/features/challenges/data/local_challenge_repository.dart` owns asset loading:

1. It reads `assets/data/challenges.json` through an `AssetBundle`.
2. It decodes the string with `jsonDecode`.
3. It verifies that the root value is an array.
4. It verifies that every array item is a JSON object.
5. It converts every object into a typed `Challenge`.
6. It returns an unmodifiable list.

The repository defaults to Flutter's `rootBundle`:

```dart
LocalChallengeRepository({AssetBundle? assetBundle})
  : assetBundle = assetBundle ?? rootBundle;
```

The optional bundle is a testability seam. Production code can use `LocalChallengeRepository()`, while a test or isolated consumer can inject a controlled `AssetBundle`.

The fallback is evaluated at runtime because `rootBundle` is not a compile-time constant. This is why the repository constructor itself is not `const`.

Returning `List.unmodifiable` protects the default dataset from accidental mutation. A caller can create a working copy when necessary, while the repository result continues to represent read-only bundled content.

Example:

```dart
final repository = LocalChallengeRepository();
final challenges = await repository.loadChallenges();
```

Asset loading is asynchronous. Callers should handle malformed-data `FormatException` values and Flutter asset-loading failures at an appropriate application boundary.

## Tests and verification

`test/local_assets_test.dart` calls `TestWidgetsFlutterBinding.ensureInitialized()` so Flutter's bundle is available in the test environment.

### Avatar verification

The test asserts the complete expected sequence from `avatar_01` through `avatar_10`. It loads every registered path with `rootBundle.load` and requires a byte length greater than zero.

This detects:

- missing files;
- incorrect registry paths;
- assets omitted from the Flutter bundle;
- empty placeholder files;
- accidental omissions or changes in the stable ID list.

### Challenge loading and parsing

The test loads the real bundled JSON through `LocalChallengeRepository`. It asserts:

- three challenges are returned;
- the IDs are `challenge_001`, `challenge_002`, and `challenge_003`;
- the parsed type set matches all current `ChallengeType` values.

This acts as an integration test for the manifest, file path, JSON syntax, loader, and domain conversion together.

### Invalid type behavior

A challenge with `type: "unknown"` is passed directly to `Challenge.fromJson`, and the test expects `FormatException`. This proves that categories outside `normal`, `wild`, and `pvp` are not silently accepted.

Relevant commands:

```shell
flutter test test/local_assets_test.dart
flutter analyze
flutter build web
```

The focused test verifies the bundle and parser. Static analysis checks Dart and Flutter lint correctness. A build confirms that Flutter can assemble the manifest and package the assets into an application target.

## Using an avatar in the UI

A future presentation feature can resolve an ID and pass the path to `Image.asset`:

```dart
final avatarPath = AppAssets.avatars[player.avatarId];

if (avatarPath != null) {
  return Image.asset(avatarPath);
}
```

The missing-ID fallback belongs to the presentation layer and was intentionally not introduced here. A screen may show a default avatar, player initials, or an error state depending on its requirements.

## Adding another avatar

1. Add a non-empty PNG to `assets/avatars/` using the next ID, for example `avatar_11.png`.
2. Add `avatar_11` and its path to `AppAssets.avatars`.
3. Add the ID to the expected sequence in `local_assets_test.dart`.
4. Run the focused test and static analysis.

No manifest change is needed while the file stays inside the registered avatars directory.

## Adding another default challenge

1. Add an object to the array in `assets/data/challenges.json`.
2. Use the next stable ID, for example `challenge_004`.
3. Provide string values for `id`, `text`, and `type`.
4. Use a value represented by `ChallengeType`.
5. Update tests that intentionally assert dataset size or IDs.
6. Run the focused test and static analysis.

To add a new category in a future sprint, first add the enum member and define its application behavior. Then use its exact lowercase enum name in JSON and expand the tests. This prevents bundled data from getting ahead of supported behavior.

## Scope boundaries

The following were intentionally not implemented:

- challenge selection or randomization;
- game-session logic;
- PvP opponent selection;
- team or player-count configuration;
- avatar-selection UI;
- Firebase Storage uploads or downloads;
- Firestore persistence for bundled content;
- custom challenge creation or synchronization;
- replacement of bundled data at runtime.

Keeping these concerns outside this task leaves a small, predictable asset layer that later features can consume without coupling it to a particular screen or game flow.

## Acceptance criteria mapping

| Acceptance criterion | Implementation |
| --- | --- |
| Local asset structure exists | Added `assets/avatars/` and `assets/data/` |
| Placeholder avatars are available | Added ten non-empty PNG avatars |
| Avatar assets load correctly | Tests load every registry path through `rootBundle` |
| Challenge JSON contains valid samples | Added three entries in `challenges.json` |
| Every challenge has `id`, `text`, and `type` | Enforced by data and `Challenge.fromJson` |
| Only supported types are used | Enum supports `normal`, `wild`, and `pvp` |
| IDs follow a consistent convention | Uses `avatar_XX` and `challenge_XXX` |
| Assets are registered | Registered avatar and data directories in `pubspec.yaml` |
| Challenge data loads and parses | Implemented and tested `LocalChallengeRepository` |
| App builds without asset errors | Verified through Flutter tests, analysis, and build checks |

Branch creation, commits, pull-request review, and merging into `develop` are Git workflow steps outside the source implementation documented here.
