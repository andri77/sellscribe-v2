"""
Configuration settings for Playwright Tests
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Configuration class for test settings"""

    # Base URL - Update this to your SellScribe web application URL
    BASE_URL = os.getenv("BASE_URL", "http://localhost:8080")

    # Test User Credentials
    TEST_USER_EMAIL = os.getenv("TEST_USER_EMAIL", "test@example.com")
    TEST_USER_PASSWORD = os.getenv("TEST_USER_PASSWORD", "Password123!")
    TEST_USER_NAME = os.getenv("TEST_USER_NAME", "Test User")

    # Timeouts (in milliseconds)
    DEFAULT_TIMEOUT = int(os.getenv("DEFAULT_TIMEOUT", "30000"))
    NAVIGATION_TIMEOUT = int(os.getenv("NAVIGATION_TIMEOUT", "60000"))
    ELEMENT_TIMEOUT = int(os.getenv("ELEMENT_TIMEOUT", "10000"))

    # Browser Settings
    DEFAULT_BROWSER = os.getenv("BROWSER", "chromium")
    HEADLESS = os.getenv("HEADLESS", "false").lower() == "true"
    SLOW_MO = int(os.getenv("SLOW_MO", "0"))

    # Viewport Settings
    VIEWPORT_WIDTH = int(os.getenv("VIEWPORT_WIDTH", "1920"))
    VIEWPORT_HEIGHT = int(os.getenv("VIEWPORT_HEIGHT", "1080"))

    # Recording Settings
    RECORD_VIDEO = os.getenv("RECORD_VIDEO", "false").lower() == "true"
    SCREENSHOT_ON_FAILURE = os.getenv("SCREENSHOT_ON_FAILURE", "true").lower() == "true"

    # Report Settings
    REPORT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "reports")
    SCREENSHOT_DIR = os.path.join(REPORT_DIR, "screenshots")

    # API Settings (if applicable)
    API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8080/api")
    API_TIMEOUT = int(os.getenv("API_TIMEOUT", "30000"))

    @classmethod
    def get_browser_args(cls) -> list:
        """Get browser launch arguments"""
        args = [
            "--disable-dev-shm-usage",
            "--no-sandbox",
        ]
        if not cls.HEADLESS:
            args.append("--start-maximized")
        return args

    @classmethod
    def ensure_directories(cls):
        """Ensure report directories exist"""
        os.makedirs(cls.REPORT_DIR, exist_ok=True)
        os.makedirs(cls.SCREENSHOT_DIR, exist_ok=True)
        if cls.RECORD_VIDEO:
            os.makedirs(os.path.join(cls.REPORT_DIR, "videos"), exist_ok=True)
