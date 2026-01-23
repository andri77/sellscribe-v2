"""
Page Objects for SellScribe Web Application
"""
from .base_page import BasePage
from .login_page import LoginPage
from .register_page import RegisterPage
from .home_page import HomePage
from .upload_page import UploadPage
from .history_page import HistoryPage
from .settings_page import SettingsPage

__all__ = [
    'BasePage',
    'LoginPage',
    'RegisterPage',
    'HomePage',
    'UploadPage',
    'HistoryPage',
    'SettingsPage'
]
