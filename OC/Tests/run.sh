#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_TEST_DIR=$(mktemp -d /private/tmp/PushWithP8-tests.XXXXXX)
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$TASK_TEST_DIR/key.pem" 2>/dev/null
openssl pkey -in "$TASK_TEST_DIR/key.pem" -pubout -outform DER -out "$TASK_TEST_DIR/public.der" 2>/dev/null
sanitize_flags=(-fno-omit-frame-pointer)
if [ "${SANITIZE:-0}" = 1 ]; then
    sanitize_flags=(-fsanitize=address,undefined -fno-omit-frame-pointer)
fi
sources=(Tests/CoreTests.m)
for source in PushWithP8/Utils/*.m; do
    [ -e "$source" ] && sources+=("$source")
done
xcrun clang -fobjc-arc -fmodules -fmodules-cache-path="$TASK_TEST_DIR/modules" -Wall -Wextra -Werror -mmacosx-version-min=12.0 -framework Foundation -framework Security "${sanitize_flags[@]}" "${sources[@]}" -o "$TASK_TEST_DIR/CoreTests"
"$TASK_TEST_DIR/CoreTests" "$TASK_TEST_DIR/key.pem" "$TASK_TEST_DIR/public.der"

if [ "$#" -gt 0 ]; then
    xcrun clang -fobjc-arc -fmodules -fmodules-cache-path="$TASK_TEST_DIR/modules" -mmacosx-version-min=12.0 -framework Cocoa -framework Security Tests/StoryboardTests.m PushWithP8/AppDelegate.m PushWithP8/MainViewController.m PushWithP8/Utils/*.m -o "$TASK_TEST_DIR/StoryboardTests"
    "$TASK_TEST_DIR/StoryboardTests" "$1"
fi
