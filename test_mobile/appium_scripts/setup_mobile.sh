#!/bin/bash
# setup_mobile.sh — install everything the Appium mobile suite needs, from the CLI only
#
# No Android Studio required. Safe to re-run: each step skips what is already installed.
#
# Installs (macOS + Homebrew):
#   JDK 17                      brew install openjdk@17
#   Android SDK                 brew cask android-commandlinetools bootstraps sdkmanager,
#                               which then installs into ~/Library/Android/sdk
#   SDK packages                platform-tools, emulator, platform, build-tools, NDK, system image
#   Android emulator (AVD)      sellscribe_api35 (Pixel 7)
#   Appium + UiAutomator2       npm install -g appium
#   Python 3.13 + test deps     brew install python@3.13, test_mobile/venv
#   SellScribe debug APK        flutter build apk --debug
#
# Usage: ./setup_mobile.sh [--skip-apk] [--api N]
#   --skip-apk   don't build the app APK
#   --api N      Android API level for the emulator image (default: 35)

set -euo pipefail

# ── Output helpers ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD='\033[1m'; CYAN='\033[36m'; GREEN='\033[32m'
  YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
else
  BOLD=''; CYAN=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

step() { printf "\n${BOLD}${CYAN}[%s] %s${RESET}\n" "$1" "$2"; }
ok()   { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
note() { printf "${YELLOW}  %s${RESET}\n" "$1"; }
die()  { printf "${RED}✘ %s${RESET}\n" "$1" >&2; exit 1; }

# ── Options ───────────────────────────────────────────────────────────────────
BUILD_APK=true
API_LEVEL=35

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-apk) BUILD_APK=false; shift ;;
    --api)      API_LEVEL="$2"; shift 2 ;;
    -h|--help)  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          die "Unknown option: $1" ;;
  esac
done

# ── Paths and versions ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$TEST_DIR")"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"

# Match what Flutter 3.47 / AGP 8.9 build with (flutter.compileSdkVersion, ndkVersion)
PLATFORM_PKG="platforms;android-36"
BUILD_TOOLS_PKG="build-tools;35.0.0"
NDK_PKG="ndk;28.2.13676358"

case "$(uname -m)" in
  arm64)  ABI="arm64-v8a" ;;
  x86_64) ABI="x86_64" ;;
  *)      die "Unsupported CPU: $(uname -m)" ;;
esac
SYSTEM_IMAGE="system-images;android-${API_LEVEL};google_apis;${ABI}"
AVD_NAME="sellscribe_api${API_LEVEL}"

# ── 0. Preflight ──────────────────────────────────────────────────────────────
step "0/8" "Preflight"
[[ "$(uname)" == "Darwin" ]] || die "This script supports macOS only."
command -v brew >/dev/null || die "Homebrew is required: https://brew.sh"
command -v flutter >/dev/null || die "Flutter is required: brew install --cask flutter"
command -v node >/dev/null || die "Node.js is required: brew install node"
ok "macOS $(sw_vers -productVersion) on $(uname -m)"
note "Android SDK: $ANDROID_HOME"

# ── 1. JDK 17 ─────────────────────────────────────────────────────────────────
step "1/8" "JDK 17"
if ! brew list openjdk@17 >/dev/null 2>&1; then
  brew install openjdk@17
fi
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
ok "$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"

# ── 2. Android command-line tools ─────────────────────────────────────────────
step "2/8" "Android command-line tools"
accept_licenses() {
  # `yes` exits on SIGPIPE when sdkmanager stops reading, so ignore the pipeline status
  yes | "$1" --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || true
}

if [[ ! -x "$SDKMANAGER" ]]; then
  if ! brew list --cask android-commandlinetools >/dev/null 2>&1; then
    brew install --cask android-commandlinetools
  fi
  # The cask's sdkmanager installs a self-updating copy into the SDK itself
  BOOTSTRAP="$(brew --prefix)/bin/sdkmanager"
  mkdir -p "$ANDROID_HOME"
  accept_licenses "$BOOTSTRAP"
  "$BOOTSTRAP" --sdk_root="$ANDROID_HOME" --install "cmdline-tools;latest"
fi
[[ -x "$SDKMANAGER" ]] || die "sdkmanager missing at $SDKMANAGER"
ok "sdkmanager $("$SDKMANAGER" --version 2>/dev/null | tail -1)"

# ── 3. SDK packages ───────────────────────────────────────────────────────────
step "3/8" "Android SDK packages (several GB on first run)"
accept_licenses "$SDKMANAGER"
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" --install \
  "platform-tools" "emulator" "$PLATFORM_PKG" "$BUILD_TOOLS_PKG" "$NDK_PKG" "$SYSTEM_IMAGE" \
  | grep -vE '^\[=*' || true
for dir in platform-tools emulator "platforms/android-36" "build-tools/35.0.0" \
           "system-images/android-${API_LEVEL}/google_apis/${ABI}"; do
  [[ -d "$ANDROID_HOME/$dir" ]] || die "SDK package missing after install: $dir"
done
ok "SDK packages installed"

# ── 4. Emulator (AVD) ─────────────────────────────────────────────────────────
step "4/8" "Android emulator"
if "$ANDROID_HOME/emulator/emulator" -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
  ok "AVD $AVD_NAME already exists"
else
  echo "no" | "$AVDMANAGER" create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" -d pixel_7
  ok "AVD $AVD_NAME created"
fi
# Settings that keep Appium sessions stable:
#   swiftshader GPU: host GL emulation stalled under Flutter rendering and dropped adb
#   4 GB RAM:        the 2 GB default is tight for Android 15 + debug app + UiAutomator2
#   hw keyboard:     no on-screen keyboard popping up over fields while typing
AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
set_avd() {
  if grep -q "^$1=" "$AVD_CONFIG"; then
    sed -i '' "s|^$1=.*|$1=$2|" "$AVD_CONFIG"
  else
    echo "$1=$2" >> "$AVD_CONFIG"
  fi
}
set_avd hw.gpu.enabled yes
set_avd hw.gpu.mode swiftshader_indirect
set_avd hw.ramSize 4096
set_avd hw.keyboard yes
ok "AVD configured (software GPU, 4 GB RAM, hardware keyboard)"

# ── 5. Flutter Android toolchain ──────────────────────────────────────────────
step "5/8" "Flutter Android toolchain"
flutter config --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME" >/dev/null
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
flutter doctor 2>&1 | grep -E "Android toolchain" || true
ok "Flutter configured for $ANDROID_HOME"

# ── 6. Appium + UiAutomator2 ──────────────────────────────────────────────────
step "6/8" "Appium"
if ! command -v appium >/dev/null; then
  npm install -g appium
fi
if ! appium driver list --installed 2>&1 | grep -q uiautomator2; then
  appium driver install uiautomator2
fi
ok "Appium $(appium --version) with UiAutomator2"

# ── 7. Python test dependencies ───────────────────────────────────────────────
step "7/8" "Python dependencies"
# macOS's own python3 is 3.9 (end of life), so build the venv on Homebrew's
if ! brew list python@3.13 >/dev/null 2>&1; then
  brew install python@3.13
fi
PYTHON="$(brew --prefix python@3.13)/bin/python3.13"
# Recreate a venv on another Python, or one copied from another machine (its scripts
# point at that machine's paths)
VENV_PY="$TEST_DIR/venv/bin/python"
if ! "$VENV_PY" -c 'import sys; assert sys.version_info[:2] == (3, 13)' 2>/dev/null \
   || ! "$VENV_PY" -m pip --version >/dev/null 2>&1; then
  [[ -e "$TEST_DIR/venv" ]] && note "Replacing venv: not a working Python 3.13 venv"
  rm -rf "$TEST_DIR/venv"
  "$PYTHON" -m venv "$TEST_DIR/venv"
fi
"$VENV_PY" -m pip install --quiet --upgrade pip
"$VENV_PY" -m pip install --quiet -r "$SCRIPT_DIR/requirements.txt"
ok "$("$TEST_DIR/venv/bin/python" --version) venv ready"

# ── 8. SellScribe debug APK ───────────────────────────────────────────────────
step "8/8" "SellScribe debug APK"
if [[ "$BUILD_APK" == "true" ]]; then
  [[ -f "$PROJECT_DIR/.env" ]] || die "$PROJECT_DIR/.env is missing (the app bundles it); create it, then re-run"
  (cd "$PROJECT_DIR" && flutter build apk --debug)
  ok "APK: $PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
else
  note "Skipped (--skip-apk)"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${BOLD}${GREEN}Mobile setup complete.${RESET}\n\n"
cat <<EOF
Run the suite (starts the emulator and Appium, then stops them afterwards):
  ./test_mobile/appium_scripts/launch_and_test.sh

Optional, to use adb / emulator / sdkmanager directly, add to ~/.zshrc:
  export ANDROID_HOME="$ANDROID_HOME"
  export JAVA_HOME="$JAVA_HOME"
  export PATH="\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$ANDROID_HOME/cmdline-tools/latest/bin"
EOF
