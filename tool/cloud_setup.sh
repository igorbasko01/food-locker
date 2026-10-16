#!/usr/bin/env bash
# Installs the Flutter SDK for a Claude Code cloud session, so `flutter analyze`
# and `flutter test` can run in the container.
#
# Paste this into the cloud environment's "Setup script" field, or run it from
# a checkout: `bash tool/cloud_setup.sh`. It is idempotent.
#
# Environment overrides:
#   FLUTTER_VERSION  pin a release (e.g. 3.38.5); default: latest stable, as CI uses
#   FLUTTER_HOME     install location; default: /opt/flutter
#   PROJECT_DIR      checkout to run `flutter pub get` in; default: the repo this
#                    script lives in, else /home/user/food-locker if it exists
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"
RELEASES_BASE="https://storage.googleapis.com/flutter_infra_release/releases"

log() { echo "==> $*"; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# Tools the SDK and its tarball need. xz for the archive, unzip for pub,
# libsqlite3 as a fallback for the bite store's tests.
missing=()
for bin in curl git unzip xz python3; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ ${#missing[@]} -gt 0 ] || ! ldconfig -p 2>/dev/null | grep -q libsqlite3.so; then
  log "Installing system packages"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq curl git unzip xz-utils python3 libsqlite3-dev ca-certificates >/dev/null
fi

releases_json="$(curl -fsSL "$RELEASES_BASE/releases_linux.json")"
read -r version archive < <(python3 -c '
import json, sys
d = json.load(sys.stdin)
want = sys.argv[1]
if want:
    rs = [r for r in d["releases"] if r["version"] == want and r["channel"] == "stable"]
else:
    h = d["current_release"]["stable"]
    rs = [r for r in d["releases"] if r["hash"] == h]
if not rs:
    sys.exit("Flutter release not found: " + (want or "current stable"))
print(rs[0]["version"], rs[0]["archive"])
' "${FLUTTER_VERSION:-}" <<<"$releases_json")

marker="$FLUTTER_HOME/.cloud_setup_version"
installed="$(cat "$marker" 2>/dev/null || true)"

if [ "$installed" = "$version" ]; then
  log "Flutter $version already installed at $FLUTTER_HOME"
else
  log "Installing Flutter $version to $FLUTTER_HOME"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fSL --retry 4 --retry-delay 2 -o "$tmp/flutter.tar.xz" "$RELEASES_BASE/$archive"
  $SUDO rm -rf "$FLUTTER_HOME"
  $SUDO mkdir -p "$(dirname "$FLUTTER_HOME")"
  $SUDO tar -xJf "$tmp/flutter.tar.xz" -C "$(dirname "$FLUTTER_HOME")"
  if [ "$(dirname "$FLUTTER_HOME")/flutter" != "$FLUTTER_HOME" ]; then
    $SUDO mv "$(dirname "$FLUTTER_HOME")/flutter" "$FLUTTER_HOME"
  fi
  $SUDO chown -R "$(id -u):$(id -g)" "$FLUTTER_HOME"
  echo "$version" > "$marker"
fi

# The SDK is a git checkout owned by whoever extracted it; without this, git
# refuses it and `flutter` cannot determine its own version.
git config --global --get-all safe.directory | grep -qxF "$FLUTTER_HOME" \
  || git config --global --add safe.directory "$FLUTTER_HOME"

# Put flutter/dart on PATH for every shell, including non-login ones.
$SUDO ln -sf "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
$SUDO ln -sf "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart

export PATH="$FLUTTER_HOME/bin:$PATH"
export CI=true  # suppresses Flutter's first-run banner and root warning noise

flutter config --no-analytics --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null 2>&1 || true
flutter --version

# Resolve dependencies for the project if its checkout is present.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -z "${PROJECT_DIR:-}" ]; then
  if [ -n "$script_dir" ] && [ -f "$script_dir/../pubspec.yaml" ]; then
    PROJECT_DIR="$(cd "$script_dir/.." && pwd)"
  elif [ -f /home/user/food-locker/pubspec.yaml ]; then
    PROJECT_DIR=/home/user/food-locker
  fi
fi
if [ -n "${PROJECT_DIR:-}" ]; then
  log "Running flutter pub get in $PROJECT_DIR"
  (cd "$PROJECT_DIR" && flutter pub get)
fi

log "Flutter is ready: run 'flutter analyze' and 'flutter test'"
