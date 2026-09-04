# Releasing Food Locker

This document explains how versioning and releases work in this project. We use a fully automated semantic versioning flow powered by Google's [Release Please](https://github.com/googleapis/release-please) action.

## 1. How Versioning Works (Conventional Commits)

Developers **do not** manually change the app version in `pubspec.yaml` on their branches! 
Instead, we use **Conventional Commits** format for our commit messages or Pull Request titles. The CI system reads these commits to automatically calculate what the next version should be.

When you merge PRs into `main`, prefix the squash merge commit like this:

- **Patch Bump (0.1.0 -> 0.1.1)**
  - Use `fix:` (e.g., `fix: fix the crash on the settings page`)
- **Minor Bump (0.1.0 -> 0.2.0)**
  - Use `feat:` (e.g., `feat: introduce the new calendar view`)
- **Major Bump (0.1.0 -> 1.0.0)**
  - Include an exclamation mark or `BREAKING CHANGE:` (e.g., `feat!: rewrite the database schema`)

You can also use other prefixes like `chore:`, `docs:`, `refactor:`, or `test:`. These will be ignored for version bumping, though they are still useful for history!

## 2. The Release PR

Once you merge a commit into `main`, GitHub Actions runs the **release-please** workflow.
1. The bot calculates the next version based on your commits.
2. The bot creates or updates a Pull Request titled `chore: release vX.Y.Z`.
3. In this PR, the bot has automatically:
   - Bumped the version in `pubspec.yaml`.
   - Updated the `CHANGELOG.md` with release notes detailing every `feat` and `fix` since the last release.

**Note:** You can continue merging multiple features into `main`. The bot will simply keep force-pushing updates to that single open Release PR until you merge it.

## 3. Shipping the Release

When the team decides it is time to cut a release:
1. Merge the bot's `chore: release vX.Y.Z` Pull Request into `main`.
2. This triggers the bot to create an official GitHub Release and tag on the repository.
3. The creation of that GitHub Release then triggers our `build_release.yml` workflow.
4. `build_release.yml` builds a production-signed Android APK securely on CI, names it with the new version and build number, and uploads it to the action artifacts.

### Merging the Release PR automatically

Step 1 also happens on its own. `sunday-release-merge.yml` runs at 01:00 UTC every Sunday (04:00 in Israel during IDT) and squash-merges the open release PR, so a week's worth of merged features ships without anyone doing anything. The same workflow has a **Run workflow** button for shipping immediately, which works from the GitHub mobile app.

It fails closed and merges nothing if the release PR is red, still running, has no checks at all, or cannot be merged — and if more than one PR carries the `autorelease: pending` label, since there is then no way to tell which one is the release. Every run writes what it did, or why it did nothing, to its job summary.

The merge is performed with `RELEASE_PLEASE_TOKEN` rather than the default `GITHUB_TOKEN`: a push made with `GITHUB_TOKEN` does not trigger other workflows, so the release-please run that cuts the release and tag would never fire.

## 4. Setting up Release Signing

To build a production release, you need a Keystore to cryptographically sign the Android APK.

### Step 1: Generate the Upload Keystore
Run this locally on your machine to generate a `.jks` file:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Note the password you use, as you will need it in the next steps.*

### Step 2: Configure Local Properties
To build release versions locally on your machine, create a file at `android/key.properties` (make sure it is inside the `android/` folder, and **DO NOT** commit it to Git):
```properties
storePassword=the_password_you_entered
keyPassword=the_password_you_entered
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Configure GitHub Secrets
To allow GitHub Actions to build signed APKs on CI, go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**.

Add the following 4 secrets:
1. `KEYSTORE_PASSWORD`: The password you set in Step 1.
2. `KEY_PASSWORD`: The same password.
3. `KEY_ALIAS`: `upload`
4. `KEYSTORE_BASE64`: A Base64 encoded string of your `.jks` file.
   *To get this, run:*
   ```bash
   base64 -i android/app/upload-keystore.jks | pbcopy
   ```

> If you do not supply these secrets, the CI workflow will gracefully fall back to using debug keys.

## 5. Building Locally

If you need to build and install the release version to examine it locally, you can use the helper script:

```bash
./build_install_release.sh
```

This script will:
- Check for `android/key.properties` to cryptographically sign a release-grade build. (If missing, it falls back to a debug-release).
- Extract the current version from `pubspec.yaml`.
- Build the APK without a debug banner.
- Auto-install it to a connected physical or virtual Android device.

## 6. Troubleshooting

### Forgot Conventional Commits?
If you merged a Pull Request that didn't follow the Conventional Commits standard, Release Please might not trigger a new release or update the changelog correctly.
To fix this, you can push a new commit with the correct prefix (e.g., `feat:`, `fix:`, or `chore:`) to trigger the pipeline again.
