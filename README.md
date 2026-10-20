# dylib-injection-demo

Interactive, talk-ready demo of macOS dylib injection, written in Zig.

A victim binary (`AcmeVault`) gatekeeps a secret behind `getuid() == 0`.
A malicious dylib gets loaded into it via `DYLD_INSERT_LIBRARIES` and:

1. runs a `__DATA,__mod_init_func` constructor before `main()` even starts
2. interposes `getuid()` via `__DATA,__interpose`, so every call inside the
   victim returns `0` regardless of who actually ran it

Run clean, the vault is locked. Run injected, it's root and unlocked.

A second piece, `libhack_echo.dylib`, shows the other half of why this
technique matters: it's not just bypassing a check, it's hijacking a real
program's output wholesale. Injected into an echo binary, `echo hello world`
prints `hacked` no matter what you pass it.

Apple's own `/bin/echo` can't be the target: it's a SIP-protected platform
binary, so `DYLD_INSERT_LIBRARIES` is silently ignored against it (verified
below, no error, dylib never loads). GNU coreutils' `echo` (`gecho`, via
`brew install coreutils`) is a real, unmodified, adhoc-signed echo binary
with no such protection - that's the target:

```sh
brew install coreutils
GECHO="$(brew --prefix coreutils)/bin/gecho"
"$GECHO" hello world                                              # hello world
DYLD_INSERT_LIBRARIES=./zig-out/lib/libhack_echo.dylib "$GECHO" hello world  # hacked
```

## The play (run it)

```sh
zig build
./slide.sh
```

`slide.sh` walks through: build -> clean run -> show the dylib source ->
injected run -> disassemble the hijack with `otool` -> why hardened binaries
block this -> the real-echo injection. Each step pauses for enter.

## Run it yourself

```sh
zig build
./zig-out/bin/victim                                             # denied
DYLD_INSERT_LIBRARIES=./zig-out/lib/libinject.dylib ./zig-out/bin/victim  # granted
```

See the intro above for the `gecho` injection example.

## How it works

- **Constructor injection** (`src/inject.zig`): a function pointer placed in
  the `__DATA,__mod_init_func` section runs automatically when dyld loads the
  image, before the host's `main()`. This is how most "DYLD_INSERT_LIBRARIES
  droppers" get arbitrary code execution for free.
- **Symbol interposing** (`src/inject.zig`): an `__DATA,__interpose` entry of
  `{replacement, original}` pointers tells dyld to redirect every call to
  `getuid` inside the process to `fakeGetuid` instead. No binary patching, no
  PLT hooking by hand - dyld does the rewrite.
- **The victim** (`src/victim.zig`) is deliberately naive: it trusts whatever
  `getuid()` tells it.

## The defensive side

This technique dies against any of:

- **Hardened Runtime** (`codesign --options runtime`): dyld refuses to load
  *any* unsigned/mismatched-team dylib into the process, injection or not.
  Verified in this repo:
  ```sh
  codesign -s - --options runtime -f ./zig-out/bin/victim
  DYLD_INSERT_LIBRARIES=./zig-out/lib/libinject.dylib ./zig-out/bin/victim
  # -> silently ignored, no error, prints "ACCESS DENIED" same as clean run
  ```
- **Library Validation** entitlement: restricts loaded dylibs to ones signed
  by the same Team ID as the host, even without full hardened runtime.
- **SIP**: protects system binaries from `DYLD_INSERT_LIBRARIES` outright,
  system-wide, regardless of signing.
- Real privilege checks should call `geteuid()`/`issetugid()` and talk to the
  OS (XPC, Authorization Services) rather than trusting a libc call that any
  loaded code in-process can intercept.

## Multi-arch builds

Native build targets the host arch. Cross-build for the other Apple arch or
ship a universal binary:

```sh
zig build -Dtarget=aarch64-macos   # Apple Silicon
zig build -Dtarget=x86_64-macos    # Intel

lipo -create -output victim-universal \
  zig-out/bin/victim \
  <other-arch-build>/victim
```

## Requirements

- Zig 0.17+
- macOS (uses `DYLD_INSERT_LIBRARIES`, Mach-O load commands, `codesign`)
- `brew install coreutils` (for the echo injection target, `gecho`)

## Disclosure

Built for a conference talk on dylib injection. Educational only: the victim
app is a toy, ships no real secret, and the technique is well documented
public macOS internals (dyld, Mach-O). Don't point this at a binary you don't
own or lack authorization to test.
