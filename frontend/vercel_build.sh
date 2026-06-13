#!/usr/bin/env bash
set -euo pipefail

printf "SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\nSTORAGE_QUOTA_BYTES=%s\nAPI_BASE_URL=%s\n" \
  "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "$STORAGE_QUOTA_BYTES" "$API_BASE_URL" > .env

git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter config --enable-web
flutter pub get
flutter build web --release
