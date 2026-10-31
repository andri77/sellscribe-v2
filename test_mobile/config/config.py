"""
SellScribe Mobile App Test Configuration
"""
import os
from dotenv import load_dotenv

_TEST_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# test_mobile/.env (gitignored; see .env.example), then the app's own .env for the
# Supabase URL and anon key (values already set win)
load_dotenv(os.path.join(_TEST_DIR, '.env'))
load_dotenv(os.path.join(os.path.dirname(_TEST_DIR), '.env'))


class Config:
    """Base configuration"""
    # Appium Server
    APPIUM_HOST = os.getenv('APPIUM_HOST', 'localhost')
    APPIUM_PORT = int(os.getenv('APPIUM_PORT', 4723))
    APPIUM_URL = f'http://{APPIUM_HOST}:{APPIUM_PORT}'
    APPIUM_SERVER = f'http://{APPIUM_HOST}:{APPIUM_PORT}/wd/hub'

    # Timeouts. No implicit wait: page objects use explicit waits, and an implicit one
    # makes every "is it absent?" check wait the full time.
    IMPLICIT_WAIT = 0
    EXPLICIT_WAIT = 20
    PAGE_LOAD_TIMEOUT = 60

    # Test User Credentials
    TEST_EMAIL = os.getenv('TEST_EMAIL', 'test@sellscribe.com')
    TEST_PASSWORD = os.getenv('TEST_PASSWORD', 'Password123!')
    # Email domain for accounts the sign-up tests create; unset skips those tests
    SIGNUP_DOMAIN = os.getenv('TEST_SIGNUP_DOMAIN', '')

    # Supabase project, for signing in through the API (utils/auth.py)
    SUPABASE_URL = os.getenv('SUPABASE_URL', '')
    SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', '')

    APP_PACKAGE = 'com.sellscribe.app'

    # App paths. The profile build (flutter build apk --profile): a debug build is too
    # slow on the emulator and UiAutomator2 commands time out. Profile builds are still
    # debuggable, which utils/auth.py needs to store the session.
    ANDROID_APK_PATH = os.getenv('ANDROID_APK_PATH', os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
        'build/app/outputs/flutter-apk/app-profile.apk'
    ))
    IOS_APP_PATH = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
        'build/ios/iphoneos/Runner.app'
    )

    @classmethod
    def get_android_capabilities(cls):
        """Get Android capabilities"""
        return AndroidConfig.get_capabilities()

    @classmethod
    def get_ios_capabilities(cls):
        """Get iOS capabilities"""
        return IOSConfig.get_capabilities()


class AndroidConfig(Config):
    """Android-specific configuration"""
    PLATFORM_NAME = 'Android'
    AUTOMATION_NAME = 'UiAutomator2'
    DEVICE_NAME = os.getenv('ANDROID_DEVICE_NAME', 'emulator-5554')
    APP_ACTIVITY = '.MainActivity'

    @classmethod
    def get_capabilities(cls):
        return {
            'platformName': cls.PLATFORM_NAME,
            'appium:automationName': cls.AUTOMATION_NAME,
            'appium:deviceName': cls.DEVICE_NAME,
            'appium:app': cls.ANDROID_APK_PATH,
            'appium:appPackage': cls.APP_PACKAGE,
            'appium:appActivity': cls.APP_ACTIVITY,
            'appium:noReset': False,
            'appium:fullReset': False,
            'appium:newCommandTimeout': 300,
            'appium:autoGrantPermissions': True,
            # Stability for Flutter: no system animations during tests, and a stuck
            # UiAutomator2 command fails after 60 s instead of hanging for 4 minutes
            'appium:disableWindowAnimation': True,
            'appium:uiautomator2ServerReadTimeout': 60000,
            # Fixtures launch the app themselves, so a signed-in test can store its
            # session first (tests/conftest.py)
            'appium:autoLaunch': False,
        }


class IOSConfig(Config):
    """iOS-specific configuration"""
    PLATFORM_NAME = 'iOS'
    AUTOMATION_NAME = 'XCUITest'
    DEVICE_NAME = os.getenv('IOS_DEVICE_NAME', 'iPhone 15')
    PLATFORM_VERSION = os.getenv('IOS_VERSION', '17.0')
    BUNDLE_ID = 'com.sellscribe.app'

    @classmethod
    def get_capabilities(cls):
        return {
            'platformName': cls.PLATFORM_NAME,
            'appium:automationName': cls.AUTOMATION_NAME,
            'appium:deviceName': cls.DEVICE_NAME,
            'appium:platformVersion': cls.PLATFORM_VERSION,
            'appium:app': cls.IOS_APP_PATH,
            'appium:bundleId': cls.BUNDLE_ID,
            'appium:noReset': False,
            'appium:fullReset': False,
            'appium:newCommandTimeout': 300,
            'appium:autoAcceptAlerts': True,
        }
