#!/bin/sh
set -eu

TARGET_DIR="$1"
ALIAS_PATH="$TARGET_DIR/Applications"

rm -rf "$ALIAS_PATH"
rm -rf "$TARGET_DIR/Applications alias" "$TARGET_DIR/Applications alias 2" "$TARGET_DIR/Applications alias 3"

if osascript <<EOF
set targetDir to POSIX file "$TARGET_DIR" as alias
tell application "Finder"
    set newAlias to make new alias file to POSIX file "/Applications" at targetDir
    set name of newAlias to "Applications"
end tell
EOF
then
    exit 0
fi

ln -sfn /Applications "$ALIAS_PATH"
