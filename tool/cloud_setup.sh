#!/bin/bash
# Installs Flutter (latest stable, or $FLUTTER_VERSION) for Claude Code cloud sessions.
set -euo pipefail
FH=${FLUTTER_HOME:-/opt/flutter}
B=https://storage.googleapis.com/flutter_infra_release/releases
A=$(curl -fsSL --retry 4 $B/releases_linux.json | python3 -c 'import json,sys
d=json.load(sys.stdin);v=sys.argv[1];h=d["current_release"]["stable"]
print(next(r["archive"] for r in d["releases"] if (r["version"]==v if v else r["hash"]==h)))' "${FLUTTER_VERSION:-}")
if [ "$(cat $FH/.archive 2>/dev/null)" != "$A" ]; then
  rm -rf $FH && mkdir -p $FH
  curl -fsSL --retry 4 $B/$A | tar -xJ -C $FH --strip-components=1
  echo $A > $FH/.archive
fi
git config --global --get-all safe.directory | grep -qx $FH || git config --global --add safe.directory $FH
ln -sf $FH/bin/flutter $FH/bin/dart /usr/local/bin/
flutter config --no-analytics >/dev/null && flutter --version
for p in $(find /home/user -maxdepth 3 -name pubspec.yaml -not -path '*/.*' 2>/dev/null); do
  (cd ${p%/*} && flutter pub get) || true
done
