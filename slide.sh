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

step "5. Crack it open: what dyld actually sees" \
     "the __mod_init_func and __interpose sections, and the disassembly dyld runs" \
     "otool -l $LIB | grep -A4 '__interpose\|__mod_init_func'"
otool -l "$LIB" | grep -A4 "__interpose\|__mod_init_func"
echo
echo "${DIM}disassembly of the hijacked getuid():${RESET}"
otool -tV "$LIB" | grep -A8 "inject.fakeGetuid:"

step "6. Why this doesn't work on a hardened binary" \
     "codesign --options runtime + no custom entitlement = DYLD refuses to load the dylib." \
     "(see README.md for the defensive side)"

GECHO="$(brew --prefix coreutils 2>/dev/null)/bin/gecho"
if [ ! -x "$GECHO" ]; then
    echo "needs GNU coreutils: brew install coreutils" >&2
    exit 1
fi

step "7. Why not /bin/echo" \
     "/bin/echo is a SIP-protected platform binary - DYLD_INSERT_LIBRARIES is silently" \
     "ignored against it, no error, dylib never loads. Using GNU coreutils' echo instead:" \
     "a real, unmodified, adhoc-signed echo binary SIP doesn't protect. $GECHO hello world"
"$GECHO" hello world

step "8. Now inject it" \
     "DYLD_INSERT_LIBRARIES=libhack_echo.dylib $GECHO hello world" \
     "every call to fputs in the process gets redirected"
DYLD_INSERT_LIBRARIES="$(pwd)/zig-out/lib/libhack_echo.dylib" "$GECHO" hello world

echo
echo "${BOLD}${CYAN}── done ──${RESET}"
