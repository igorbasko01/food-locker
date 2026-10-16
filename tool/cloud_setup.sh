#!/usr/bin/env bash
# Installs the Flutter SDK in a Claude Code cloud session, so `flutter analyze`
# and `flutter test` can run in the container. Not tied to any one project.
#
# Paste this into the cloud environment's "Setup script" field, or run it from
# a checkout: `bash tool/cloud_setup.sh`. It is idempotent.
#
# Environment overrides:
#   FLUTTER_VERSION  pin a release (e.g. 3.38.5); default: latest on FLUTTER_CHANNEL
#   FLUTTER_CHANNEL  stable (default) or beta
#   FLUTTER_HOME     install location; default: /opt/flutter
#   PROJECT_DIRS     space-separated Flutter projects to run `flutter pub get` in;
#                    default: every pubspec.yaml up to two levels under
#                    $WORKSPACE (default /home/user), skipping hidden and build dirs
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"
WORKSPACE="${WORKSPACE:-/home/user}"
RELEASES_BASE="https://storage.googleapis.com/flutter_infra_release/releases"

log() { echo "==> $*"; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

missing=()
for bin in curl git unzip xz python3; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ ${#missing[@]} -gt 0 ]; then
  log "Installing system packages: ${missing[*]}"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq curl git unzip xz-utils python3 ca-certificates >/dev/null
fi

releases_json="$(curl -fsSL --retry 4 --retry-delay 2 "$RELEASES_BASE/releases_linux.json")"
read -r version archive < <(python3 -c '
import json, sys
d = json.load(sys.stdin)
want, channel = sys.argv[1], sys.argv[2]
if want:
    rs = [r for r in d["releases"] if r["version"] == want]
else:
    h = d["current_release"][channel]
    rs = [r for r in d["releases"] if r["hash"] == h and r["channel"] == channel]
if not rs:
    sys.exit("Flutter release not found: " + (want or "current " + channel))
print(rs[0]["version"], rs[0]["archive"])
' "${FLUTTER_VERSION:-}" "$FLUTTER_CHANNEL" <<<"$releases_json")

# Newer SDKs ship no top-level `version` file, so record what we installed.
marker="$FLUTTER_HOME/.cloud_setup_version"
installed="$(cat "$marker" 2>/dev/null || true)"

if [ "$installed" = "$version" ]; then
  log "Flutter $version already installed at $FLUTTER_HOME"
else
  log "Installing Flutter $version to $FLUTTER_HOME"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fSL --retry 4 --retry-delay 2 -o "$tmp/flutter.tar.xz" "$RELEASES_BASE/$archive"
  tar -xJf "$tmp/flutter.tar.xz" -C "$tmp"
  $SUDO rm -rf "$FLUTTER_HOME"
  $SUDO mkdir -p "$(dirname "$FLUTTER_HOME")"
  $SUDO mv "$tmp/flutter" "$FLUTTER_HOME"
  $SUDO chown -R "$(id -u):$(id -g)" "$FLUTTER_HOME"
  echo "$version" > "$marker"
fi

# The SDK is a git checkout owned by whoever extracted it; without this, git
# refuses it and `flutter` cannot determine its own version.
git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$FLUTTER_HOME" \
  || git config --global --add safe.directory "$FLUTTER_HOME"

# Put flutter/dart on PATH for every shell, including non-login ones.
$SUDO ln -sf "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
$SUDO ln -sf "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart

export PATH="$FLUTTER_HOME/bin:$PATH"
export CI=true  # suppresses first-run banners and prompts

flutter config --no-analytics --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null 2>&1 || true
flutter --version

# Resolve dependencies for any Flutter projects already checked out. The setup
# script may run before the repository is cloned, in which case none are found.
if [ -z "${PROJECT_DIRS:-}" ] && [ -d "$WORKSPACE" ]; then
  PROJECT_DIRS="$(find "$WORKSPACE" -maxdepth 3 -name pubspec.yaml \
    -not -path '*/.*' -not -path '*/build/*' -exec grep -l 'sdk: flutter' {} + 2>/dev/null \
    | xargs -r -n1 dirname | tr '\n' ' ')"
fi
for dir in ${PROJECT_DIRS:-}; do
  log "Running flutter pub get in $dir"
  (cd "$dir" && flutter pub get) || log "flutter pub get failed in $dir; continuing"
done

log "Flutter is ready: run 'flutter analyze' and 'flutter test'"
