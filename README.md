# FoodLocker

A Flutter application designed to track food intake and manage daily nutritional goals efficiently. This project leverages `Hive CE` for fast local data storage and `Provider` for state management.

## Features

- **Daily Food Tracking**: Log your daily food consumption easily.
- **Persistent Storage**: Data is saved locally using [Hive CE](https://pub.dev/packages/hive_ce) and [SharedPreferences](https://pub.dev/packages/shared_preferences), ensuring your records are kept safe even after the app is closed.
- **Food Configuration**: Manage and customize your food items and their nutritional values.
- **Theming**: Includes a custom app theme for a consistent and pleasant user interface.
- **State Management**: Utilizes the `Provider` package for efficient state management across the application.

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Flutter SDK: `^3.10.4`
- Dart SDK: (included with Flutter)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/yourusername/food_locker.git
    cd food_locker
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the application:**

    ```bash
    flutter run
    ```

### Code Generation

This project uses `build_runner` for code generation (e.g., for Hive CE adapters). If you make changes to models that require code generation, run:

```bash
flutter pub run build_runner build
```

## Project Structure

- `lib/features`: Contains feature-specific code (e.g., `days`, `food`).
- `lib/ui`: UI components and pages.
- `lib/main.dart`: Application entry point.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
