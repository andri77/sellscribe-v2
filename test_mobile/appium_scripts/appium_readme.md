# Appium Mobile Testing Setup Guide

This guide provides detailed instructions for setting up Appium to test the SellScribe mobile application on Android and iOS.

## Table of Contents

0. [Quick Setup (macOS, CLI only)](#quick-setup-macos-cli-only)
1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Installation Steps](#installation-steps)
4. [Android Setup](#android-setup)
5. [iOS Setup](#ios-setup)
6. [Running Tests](#running-tests)
7. [Troubleshooting](#troubleshooting)

---

## Quick Setup (macOS, CLI only)

`setup_mobile.sh` installs everything the Android suite needs from the terminal. No Android
Studio is required. It is safe to re-run: each step skips what is already installed.

**You need first:** [Homebrew](https://brew.sh), Flutter, Node.js, and the app's
`.env` at the repo root (the APK bundles it).

```bash
./test_mobile/appium_scripts/setup_mobile.sh
```

| Step | What it installs | How |
|------|------------------|-----|
| 1 | JDK 17 | `brew install openjdk@17` |
| 2 | Android command-line tools in `~/Library/Android/sdk` | `brew install --cask android-commandlinetools` to bootstrap `sdkmanager` |
| 3 | platform-tools, emulator, Android 36 platform, build-tools 35, NDK 28.2, API 35 system image | `sdkmanager` (licenses accepted automatically) |
| 4 | Emulator `sellscribe_api35` (Pixel 7) | `avdmanager create avd` |
| 5 | Flutter pointed at that SDK and JDK | `flutter config`, `flutter doctor --android-licenses` |
| 6 | Appium with the UiAutomator2 driver | `npm install -g appium`, `appium driver install uiautomator2` |
| 7 | Python 3.13 and the test dependencies (replaces a venv that can't run) | `brew install python@3.13`, `pip install -r requirements.txt` into `test_mobile/venv` |
| 8 | SellScribe profile APK | `flutter build apk --profile` |

The first run downloads several GB and takes a while. Options:

```bash
./test_mobile/appium_scripts/setup_mobile.sh --skip-apk   # don't build the APK
./test_mobile/appium_scripts/setup_mobile.sh --api 36     # different emulator API level
```

Then run the suite. It boots the emulator and starts Appium, and stops both afterwards:

```bash
./test_mobile/appium_scripts/launch_and_test.sh            # all tests
./test_mobile/appium_scripts/launch_and_test.sh -m smoke   # smoke only
./scripts/run-all-tests.sh                                  # web + API + mobile
```

After app changes, rebuild the APK with `flutter build apk --profile` and uninstall the old
one (`adb uninstall com.sellscribe.app`): the runner only installs the APK when the app
is missing from the emulator.

The script doesn't touch your shell profile. To use `adb`, `emulator` or `sdkmanager`
directly, add the exports it prints at the end to `~/.zshrc`.

The manual steps below are the equivalent for other platforms, or for Android Studio users.

---

## Prerequisites

### Required Software

- **Node.js** (v16 or later) - Appium is built on Node.js
- **Python** (3.8+) - Test scripts are written in Python
- **Java JDK** (8 or 11) - Required for Android SDK
- **Android Studio** (for Android testing)
- **Xcode** (for iOS testing, macOS only)

### Hardware Requirements

- **Android**: Physical Android device or Android Emulator
- **iOS**: Physical iOS device or iOS Simulator (macOS required)

---

## System Requirements

### macOS
```
- macOS 10.15+ (Catalina or later)
- Xcode 12+ (for iOS testing)
- Homebrew package manager
```

### Windows
```
- Windows 10/11
- Android Studio with SDK Tools
- Note: iOS testing not supported on Windows
```

### Linux
```
- Ubuntu 18.04+ or equivalent
- Android Studio with SDK Tools
- Note: iOS testing not supported on Linux
```

---

## Installation Steps

### Step 1: Install Node.js

**macOS (using Homebrew):**
```bash
brew install node
```

**Windows:**
Download from https://nodejs.org/ and run the installer.

**Linux:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Verify installation:
```bash
node --version
npm --version
```

### Step 2: Install Appium

```bash
# Install Appium globally
npm install -g appium

# Verify installation
appium --version
```

### Step 3: Install Appium Drivers

```bash
# Install UiAutomator2 driver for Android
appium driver install uiautomator2

# Install XCUITest driver for iOS (macOS only)
appium driver install xcuitest

# List installed drivers
appium driver list --installed
```

### Step 4: Install Appium Doctor (Optional but Recommended)

Appium Doctor helps verify your setup is correct:

```bash
npm install -g @appium/doctor

# Check Android setup
appium-doctor --android

# Check iOS setup (macOS only)
appium-doctor --ios
```

### Step 5: Install Python Dependencies

Navigate to the test_mobile directory and install Python packages:

```bash
cd /path/to/SellScribe/test_mobile

# Create virtual environment (recommended)
python3 -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate
# Windows:
.\venv\Scripts\activate

# Install dependencies
pip install -r appium_scripts/requirements.txt
```

---

## Android Setup

### Step 1: Install Android Studio

1. Download Android Studio from https://developer.android.com/studio
2. Run the installer and follow the setup wizard
3. Install SDK Components when prompted

### Step 2: Configure Environment Variables

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, or Windows Environment Variables):

**macOS/Linux:**
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS default
# OR for Linux:
# export ANDROID_HOME=$HOME/Android/Sdk

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

**Windows (System Environment Variables):**
```
ANDROID_HOME = C:\Users\<username>\AppData\Local\Android\Sdk
PATH += %ANDROID_HOME%\emulator
PATH += %ANDROID_HOME%\platform-tools
PATH += %ANDROID_HOME%\tools
PATH += %ANDROID_HOME%\tools\bin
```

Verify setup:
```bash
adb --version
```

### Step 3: Create Android Emulator

1. Open Android Studio
2. Go to **Tools > Device Manager**
3. Click **Create Device**
4. Select a device (e.g., Pixel 6)
5. Select a system image (e.g., API 33)
6. Finish and launch the emulator

### Step 4: Enable Developer Options on Physical Device

1. Go to **Settings > About Phone**
2. Tap **Build Number** 7 times
3. Go back to **Settings > Developer Options**
4. Enable **USB Debugging**
5. Connect device via USB and authorize debugging

### Step 5: Install the App

```bash
# Install the profile APK on connected device/emulator
adb install /path/to/SellScribe/build/app/outputs/flutter-apk/app-profile.apk

# Verify installation
adb shell pm list packages | grep sellscribe
```

---

## iOS Setup (macOS Only)

### Step 1: Install Xcode

1. Download Xcode from the Mac App Store
2. Open Xcode and accept the license agreement
3. Install additional components when prompted

### Step 2: Install Xcode Command Line Tools

```bash
xcode-select --install
```

### Step 3: Install Carthage and ios-deploy

```bash
brew install carthage ios-deploy
```

### Step 4: Configure WebDriverAgent

```bash
# Navigate to WebDriverAgent directory
cd ~/.appium/node_modules/appium-xcuitest-driver/node_modules/appium-webdriveragent

# Install dependencies
./Scripts/bootstrap.sh

# Open in Xcode to configure signing
open WebDriverAgent.xcodeproj
```

In Xcode:
1. Select **WebDriverAgentLib** target
2. Go to **Signing & Capabilities**
3. Select your team/Apple ID
4. Repeat for **WebDriverAgentRunner** target

### Step 5: Trust Developer on Device (Physical Device)

1. On the iOS device, go to **Settings > General > VPN & Device Management**
2. Trust your developer certificate

### Step 6: Start iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 14"

# Install the app
xcrun simctl install booted /path/to/SellScribe.app
```

---

## Running Tests

### Start Appium Server

**Option 1: Using the start script**
```bash
cd test_mobile/appium_scripts
./start_appium.sh
```

**Option 2: Manual start**
```bash
appium --port 4723 --base-path /wd/hub
```

### Run Tests

**Run all tests:**
```bash
cd test_mobile
pytest tests/ -v
```

**Run specific test file:**
```bash
pytest tests/test_login.py -v
```

**Run tests with specific markers:**
```bash
pytest tests/ -v -m "smoke"
pytest tests/ -v -m "regression"
```

**Run tests for specific platform:**
```bash
# Android
pytest tests/ -v --platform=android

# iOS
pytest tests/ -v --platform=ios
```

**Generate HTML report:**
```bash
pytest tests/ -v --html=reports/report.html
```

---

## Troubleshooting

### Common Issues

#### 1. "Appium not found" error
```bash
# Ensure Node.js and npm are installed
node --version
npm --version

# Reinstall Appium
npm install -g appium
```

#### 2. "ANDROID_HOME is not set"
```bash
# Add to your shell profile
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

#### 3. "adb: command not found"
```bash
# Ensure platform-tools is in PATH
echo $PATH | grep platform-tools

# Add if missing
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

#### 4. "Unable to find an active device or emulator"
```bash
# Check connected devices
adb devices

# If empty, start emulator or connect device
emulator -avd <emulator_name>
```

#### 5. "Session not created" error
- Verify app is installed: `adb shell pm list packages | grep sellscribe`
- Check appPackage and appActivity in config
- Ensure Appium server is running

#### 6. "WebDriverAgentRunner failed to start" (iOS)
- Open WebDriverAgent.xcodeproj in Xcode
- Verify signing configuration
- Build and run WebDriverAgentRunner target manually first

### Debug Mode

Run tests with verbose logging:
```bash
pytest tests/ -v -s --log-cli-level=DEBUG
```

Check Appium logs:
```bash
# Start Appium with debug logging
appium --log-level debug
```

---

## Project Structure

```
test_mobile/
├── appium_scripts/
│   ├── appium_readme.md      # This file
│   ├── requirements.txt      # Python dependencies
│   ├── install_appium.sh     # Appium installation script
│   ├── start_appium.sh       # Start Appium server
│   └── run_tests.sh          # Run test suite
├── config/
│   └── config.py             # Test configuration
├── pages/
│   ├── __init__.py
│   ├── base_page.py          # Base page object
│   ├── login_page.py
│   ├── register_page.py
│   ├── home_page.py
│   ├── settings_page.py
│   ├── profile_edit_page.py
│   ├── upload_page.py
│   ├── history_page.py
│   ├── payment_methods_page.py
│   └── purchase_credits_page.py
├── tests/
│   ├── conftest.py           # Pytest fixtures
│   ├── test_login.py
│   ├── test_register.py
│   ├── test_listing.py
│   └── test_settings.py
└── reports/                   # Test reports
```

---

## Useful Commands

```bash
# List connected Android devices
adb devices

# Get app package and activity
adb shell dumpsys window | grep mCurrentFocus

# Take screenshot
adb exec-out screencap -p > screenshot.png

# Get device logs
adb logcat

# List iOS simulators
xcrun simctl list devices

# Get iOS app bundle ID
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" /path/to/app/Info.plist
```

---

## Resources

- [Appium Documentation](https://appium.io/docs/en/latest/)
- [UiAutomator2 Driver](https://github.com/appium/appium-uiautomator2-driver)
- [XCUITest Driver](https://github.com/appium/appium-xcuitest-driver)
- [Appium Python Client](https://github.com/appium/python-client)
- [Android Debug Bridge (adb)](https://developer.android.com/studio/command-line/adb)
