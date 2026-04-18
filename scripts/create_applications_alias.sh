#!/bin/sh
set -eu

TARGET_DIR="$1"
ALIAS_PATH="$TARGET_DIR/Applications"

rm -rf "$ALIAS_PATH"

if osascript <<EOF
set targetDir to POSIX file "$TARGET_DIR" as alias
tell application "Finder"
    make new alias file to POSIX file "/Applications" at targetDir
end tell
EOF
then
    exit 0
fi

ln -sfn /Applications "$ALIAS_PATH"
