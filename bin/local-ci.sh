#!/bin/bash
# Реплика .github/workflows/build.yml — те же шаги, тот же порядок.
cd "$(dirname "$0")/cyclop" || exit 9
fail() { echo "FAIL:$1"; exit 1; }
./Scripts/bundle.sh release >/tmp/ci-build.log 2>&1 || fail "bundle.sh"
APP=build/Cyclop.app
VERSION="$(sed -n 's/^VERSION=//p' Scripts/version)"
test -x "$APP/Contents/MacOS/Cyclop"                          || fail "нет бинарника"
test -f "$APP/Contents/Resources/libcyclopmedia.dylib"        || fail "нет dylib"
test -f "$APP/Contents/Resources/en.lproj/Localizable.strings" || fail "нет en.lproj"
test -f "$APP/Contents/Resources/ru.lproj/Localizable.strings" || fail "нет ru.lproj"
INSIDE="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
test "$INSIDE" = "$VERSION" || fail "версия $INSIDE != $VERSION"
codesign --verify --strict "$APP" 2>/dev/null || fail "codesign"
./Scripts/test-helper.sh >/tmp/ci-helper.log 2>&1 || fail "test-helper.sh"
python3 - <<'PY' || exit 1
import re, io, pathlib, sys
pat = re.compile(r'\b(?:localized|Text|Button|TextField)\(\s*"((?:[^"\\]|\\.)+)"')
code = set()
for p in pathlib.Path("Sources").rglob("*.swift"):
    for m in pat.finditer(io.open(p, encoding="utf-8").read()):
        key = m.group(1)
        if "\\(" in key or not any(c.isalpha() for c in key): continue
        code.add(key.replace("\\n", "\n"))
bad = False
for table in pathlib.Path("Resources").glob("*.lproj/Localizable.strings"):
    text = io.open(table, encoding="utf-8").read()
    keys = {k.replace("\\n","\n") for k in re.findall(r'^"((?:[^"\\]|\\.)*)"\s*=', text, re.M)}
    missing = code - keys
    if missing:
        bad = True
        print(f"FAIL:ключи {table}: {sorted(missing)}")
sys.exit(1 if bad else 0)
PY
echo "PASS"
