# FoodLocker

A Flutter application for tracking your daily weight and pacing your eating, one bite at a time. FoodLocker stores everything locally and uses `Provider` for state management.

## Features

- **Daily Weight Tracking**: Log one weight entry per day, in kilograms or pounds.
- **Analytics & Insights**: See your lowest weight all-time and over the last 7 / 30 days.
- **Weight History & Chart**: Browse past entries and visualize trends with a chart (`fl_chart`).
- **Bite Counting & Pacing**: Tap once per bite to count your bites for the day, with a colour-coded timer that paces you between bites (too soon → hold on → clear) and a haptic buzz when it's a good time for the next one. Bites are never blocked — the pacing is feedback, not a lockout.
- **Backup & Restore**: Export all your data — weight and bites — to a zip file and import it back later from the Settings tab.
- **Persistent Storage**: Data is saved locally — weight in [Hive CE](https://pub.dev/packages/hive_ce) and bites in [Drift](https://pub.dev/packages/drift)/SQLite — so your records survive app restarts.
- **State Management**: Uses the [Provider](https://pub.dev/packages/provider) package for state management across the app.

## Getting Started

### Prerequisites

- Flutter SDK: `^3.10.4`
- Dart SDK: (included with Flutter)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/igorbasko01/food-locker.git
    cd food-locker
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **(Optional) Set up git hooks** to run `flutter analyze` and `flutter test` before every push:

    ```bash
    ./setup.sh
    ```

4.  **Run the application:**

    ```bash
    flutter run
    ```

### Code Generation

This project uses `build_runner` for code generation (Hive CE adapters and the Drift database). If you change a model or Drift table that requires code generation, regenerate the `*.g.dart` files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

- `lib/features`: Feature-specific domain and persistence code (e.g. `weight`, `bite`, `settings`).
- `lib/ui`: UI pages, widgets, the app shell, and theme.
- `lib/core`: Shared helpers (CSV serialization, query utilities).
- `lib/main.dart`: Application entry point and dependency wiring.

## Contributing

This project uses **Conventional Commits** and **release-please** to automate versioning and changelog generation. Prefix commits / PR titles with `feat:`, `fix:`, `chore:`, etc. See [RELEASING.md](RELEASING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
