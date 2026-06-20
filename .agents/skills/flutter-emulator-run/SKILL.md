---
name: flutter-emulator-run
description: Orchestrates Flutter emulator management, including listing available emulators, launching an emulator, and deploying/running the Flutter application on the running emulator.
---
# Flutter Emulator Run

This skill outlines how to list, launch a mobile emulator, and run/deploy the Flutter application onto the launched emulator.

## Workflow

### 1. List Available Emulators
To view all configured emulators on the system, run:
```bash
flutter emulators
```
This will print a list of emulators along with their IDs, names, and platforms (e.g., `Pixel_3a_API_34_extension_level_7_arm64-v8a`).

### 2. Launch the Selected Emulator
Launch your desired emulator by passing its emulator ID:
```bash
flutter emulators --launch <emulator_id>
```
For example:
```bash
flutter emulators --launch Pixel_3a_API_34_extension_level_7_arm64-v8a
```
> [!NOTE]
> Since launching an emulator can be a long-running process that remains active, when executing via the `run_command` tool, the system will automatically transition it to a background task.

### 3. Verify Active Devices
Before running the application, verify that the emulator is booted and recognized as an active device:
```bash
flutter devices
```
Wait until the emulator's ID appears in the list of active devices.

### 4. Deploy and Run the App
Deploy and run the Flutter application onto the running emulator:
```bash
flutter run
```
If multiple devices/emulators are connected, specify the target emulator device ID explicitly:
```bash
flutter run -d <device_id>
```
