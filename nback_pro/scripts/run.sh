#!/usr/bin/env bash
# Run Flutter and filter out Android MediaPlayer verbose logs (e.g. resetDrmState).
cd "$(dirname "$0")/.."
exec flutter run "$@" 2>&1 | grep -v -E 'resetDrmState|V/MediaPlayer'
