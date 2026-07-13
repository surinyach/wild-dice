# Flutter Architecture Guidelines

This project uses a lightweight feature-first architecture. The goal is to keep the app easy to grow without creating folders or abstractions before they are useful.

## Core Rule

Create folders for real product boundaries, not for individual tasks or prompts.

A good feature folder represents something the user can do or a meaningful area of the product, such as:

- `main_menu`
- `auth`
- `lobby`
- `game`
- `challenges`
- `profile`

Avoid creating a top-level feature folder for every single view, such as:

- `create_game_view`
- `join_game_view`
- `settings_view`

If several views belong to the same user flow, keep them inside the same feature.

## Default Feature Shape

Start each feature with only the folders it actually needs.

For a UI-only feature:

```text
lib/features/main_menu/
  presentation/
    pages/
    widgets/
```

For a feature with backend or business logic:

```text
lib/features/game/
  presentation/
    pages/
    widgets/
  domain/
    entities/
    repositories/
    use_cases/
  data/
    datasources/
    dtos/
    repositories/
```

Do not create `domain` or `data` just because a feature exists. Add them when the feature has real domain rules, backend communication, local persistence, or reusable business logic.

## Layer Responsibilities

### Presentation

Contains Flutter UI and UI-specific state.

Use it for:

- Pages and screens.
- Feature-specific widgets.
- Animations and layout behavior.
- View models or controllers, if the feature needs them.
- Navigation triggered by user interaction.

Presentation should not contain direct API calls or JSON parsing.

### Domain

Contains app/business concepts that should not depend on Flutter widgets or backend details.

Use it for:

- Entities such as `Game`, `Player`, `Challenge`, or `Lobby`.
- Repository contracts when the UI should depend on an abstraction.
- Use cases when logic is reused, complex, or combines multiple repositories.

The domain layer is optional. If a feature is simple CRUD or UI-only, skip it until it earns its place.

### Data

Contains implementation details for getting and storing data.

Use it for:

- Remote data sources that call the backend.
- Local data sources such as storage or cache.
- DTOs and JSON serialization.
- Repository implementations.

Even when the backend is a separate project, the Flutter app can still have a data layer. It is the client-side adapter to that backend.

## Shared And Core

Use `core` for app-wide infrastructure:

- Routing.
- Theme.
- Network client setup.
- Environment configuration.
- Cross-cutting error handling.

Use `shared` for truly reusable UI or utilities that are not owned by one feature.

Do not move code to `shared` too early. If only one feature uses it, keep it in that feature. If two or more features need it and it has no clear owner, then promote it.

## Decision Checklist

Before creating a folder or layer, ask:

- Is this a real feature/user flow, or just one screen?
- Does this feature talk to a backend, local storage, or platform API?
- Does this feature have business rules that are useful outside one widget?
- Will this code be reused by multiple pages or features?
- Would this folder make the next change easier to find and safer to make?

If the answer is no, keep the structure smaller.

## Current Project Application

`main_menu` currently only needs `presentation` because it is mainly visual: background, logo, buttons, animation, and navigation.

Future flows such as creating a game, joining a lobby, running a game round, or loading challenges should grow into their own feature folders when they contain real behavior.

Example:

```text
lib/features/lobby/
  presentation/
    pages/
      create_game_page.dart
      join_game_page.dart
      lobby_page.dart
    widgets/
  domain/
    entities/
      lobby.dart
      room_code.dart
    use_cases/
      create_lobby.dart
      join_lobby.dart
  data/
    datasources/
      lobby_remote_data_source.dart
    dtos/
      lobby_dto.dart
    repositories/
      lobby_repository_impl.dart
```

This keeps related views and logic together without creating one isolated feature folder per view.
