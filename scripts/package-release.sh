#!/bin/bash
# Build both macOS apps locally; this script never pushes or publishes a release.
set -euo pipefail
cd "$(dirname "$0")/.."
release_version=$(tr -d '\r\n' < VERSION)
if [[ ! "$release_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "VERSION must use the repository's MAJOR.MINOR.PATCH format" >&2
    exit 1
fi
release_work=$(mktemp -d /private/tmp/PushWithP8-release.XXXXXX)
trap 'rm -rf "$release_work"' EXIT
release_output=${1:-"$PWD/dist/$release_version"}
mkdir -p "$release_output"
release_output=$(cd "$release_output" && pwd)
for variant in Swift OC; do
    if [ "$variant" = Swift ]; then
        project=PushWithP8.xcodeproj
        entitlements=PushWithP8/PushWithP8.entitlements
    else
        project=OC/PushWithP8.xcodeproj
        entitlements=OC/PushWithP8/PushWithP8.entitlements
    fi
    echo "Building $variant $release_version (arm64 + x86_64)…"
    xcodebuild -project "$project" -scheme PushWithP8 -configuration Release \
        -derivedDataPath "$release_work/$variant" CODE_SIGNING_ALLOWED=NO \
        ONLY_ACTIVE_ARCH=NO 'ARCHS=arm64 x86_64' build > "$release_output/$variant-build.log" 2>&1
    app="$release_work/$variant/Build/Products/Release/PushWithP8.app"
    actual_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
    if [ "$actual_version" != "$release_version" ]; then
        echo "$variant version mismatch: $actual_version != $release_version" >&2; exit 1
    fi
    architectures=" $(lipo -archs "$app/Contents/MacOS/PushWithP8") "
    if [[ "$architectures" != *" arm64 "* || "$architectures" != *" x86_64 "* ]]; then
        echo "$variant is missing a Universal architecture:$architectures" >&2; exit 1
    fi
    codesign --force --sign - --entitlements "$entitlements" "$app"
    codesign --verify --deep --strict "$app"
    if [ "$variant" = OC ]; then
        bash OC/Tests/run.sh "$app"
    fi
    archive="PushWithP8-$variant-$release_version-universal.zip"
    ditto -c -k --sequesterRsrc --keepParent "$app" "$release_output/$archive"
    unzip -tq "$release_output/$archive"
done
(
    cd "$release_output"
    shasum -a 256 "PushWithP8-Swift-$release_version-universal.zip" "PushWithP8-OC-$release_version-universal.zip" > SHA256SUMS
)
echo "Release artifacts: $release_output"
