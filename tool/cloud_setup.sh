#!/bin/bash
# Claude Code cloud environment setup script. Installs `flutter-ensure` and a
# user-level SessionStart hook that runs it, so each session gets the Flutter
# version its project pins (.fvmrc, or an exact environment.flutter in
# pubspec.yaml), else the latest stable.
set -euo pipefail

cat > /usr/local/bin/flutter-ensure <<'EOF'
#!/bin/bash
set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-$PWD}"
P=$(grep -l 'sdk: flutter' $(find . -maxdepth 3 -name pubspec.yaml -not -path '*/.*') 2>/dev/null | head -1 || true)
[ -n "$P" ] || exit 0
cd "${P%/*}"
V=${FLUTTER_VERSION:-}
[ -z "$V" ] && [ -f .fvmrc ] && V=$(python3 -c 'import json;print(json.load(open(".fvmrc"))["flutter"])' 2>/dev/null || true)
[ -z "$V" ] && V=$(sed -n '/^environment:/,/^[^ ]/s/^ *flutter: *["'\'']\{0,1\}\([0-9][0-9.]*\)["'\'']\{0,1\} *$/\1/p' pubspec.yaml)
[[ "$V" =~ ^[0-9] ]] || V=
B=https://storage.googleapis.com/flutter_infra_release/releases
read -r V A < <(curl -fsSL --retry 4 $B/releases_linux.json | python3 -c 'import json,sys
d=json.load(sys.stdin);v=sys.argv[1];h=d["current_release"]["stable"]
r=next(r for r in d["releases"] if (r["version"]==v if v else r["hash"]==h))
print(r["version"],r["archive"])' "$V")
D=/opt/flutter-$V
if [ ! -x $D/bin/flutter ]; then
  rm -rf $D.tmp && mkdir -p $D.tmp
  curl -fsSL --retry 4 $B/$A | tar -xJ -C $D.tmp --strip-components=1
  mv $D.tmp $D
fi
git config --global --get-all safe.directory | grep -qx $D || git config --global --add safe.directory $D
ln -sfn $D/bin/flutter $D/bin/dart /usr/local/bin/
flutter config --no-analytics >/dev/null 2>&1 || true
flutter pub get >/dev/null 2>&1 || echo "flutter pub get failed in $PWD"
echo "Flutter $V ready for $PWD"
EOF
chmod +x /usr/local/bin/flutter-ensure

python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
hook = {"type": "command", "command": "/usr/local/bin/flutter-ensure", "timeout": 600}
starts = s.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == hook["command"] for e in starts for h in e.get("hooks", [])):
    starts.append({"hooks": [hook]})
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(s, open(p, "w"), indent=2)
EOF
