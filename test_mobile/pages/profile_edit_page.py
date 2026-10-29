"""
Profile Edit Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class ProfileEditPage(BasePage):
    """Page object for Profile Edit screen"""

    FIRST_NAME_INPUT_ID = "first-name-input"
    LAST_NAME_INPUT_ID = "last-name-input"
    MOBILE_INPUT_ID = "mobile-input"
    ADDRESS_INPUT_ID = "address-input"
    CITY_INPUT_ID = "city-input"
    STATE_INPUT_ID = "state-input"
    ZIP_CODE_INPUT_ID = "zip-code-input"
    COUNTRY_INPUT_ID = "country-input"
    SAVE_BUTTON_ID = "save-profile-button"

    def is_profile_edit_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if profile edit screen is displayed"""
        return self.is_present(self.by_id(self.FIRST_NAME_INPUT_ID), timeout)

    def is_field_displayed(self, test_id: str) -> bool:
        """Check if a profile field is displayed (scrolling to it if needed)"""
        try:
            self.scroll_to(self.by_id(test_id))
            return True
        except Exception:
            return False

    def _enter(self, test_id: str, value: str):
        self.scroll_to(self.by_id(test_id))
        return self.type_into(test_id, value)

    def enter_first_name(self, name: str):
        """Enter first name"""
        return self._enter(self.FIRST_NAME_INPUT_ID, name)

    def enter_last_name(self, name: str):
        """Enter last name"""
        return self._enter(self.LAST_NAME_INPUT_ID, name)

    def enter_mobile(self, mobile: str):
        """Enter mobile number"""
        return self._enter(self.MOBILE_INPUT_ID, mobile)

    def enter_address(self, address: str):
        """Enter street address"""
        return self._enter(self.ADDRESS_INPUT_ID, address)

    def enter_city(self, city: str):
        """Enter city"""
        return self._enter(self.CITY_INPUT_ID, city)

    def enter_state(self, state: str):
        """Enter state"""
        return self._enter(self.STATE_INPUT_ID, state)

    def enter_zip_code(self, zip_code: str):
        """Enter ZIP code"""
        return self._enter(self.ZIP_CODE_INPUT_ID, zip_code)

    def enter_country(self, country: str):
        """Enter country"""
        return self._enter(self.COUNTRY_INPUT_ID, country)

    def tap_save(self):
        """Tap Save (on success the screen closes back to Settings)"""
        self.scroll_to(self.by_id(self.SAVE_BUTTON_ID))
        self.tap(self.by_id(self.SAVE_BUTTON_ID))
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)

    def fill_profile(self, first_name: str = None, last_name: str = None,
                     mobile: str = None, address: str = None,
                     city: str = None, state: str = None,
                     zip_code: str = None, country: str = None):
        """Fill the given profile fields"""
        for test_id, value in (
            (self.FIRST_NAME_INPUT_ID, first_name), (self.LAST_NAME_INPUT_ID, last_name),
            (self.MOBILE_INPUT_ID, mobile), (self.ADDRESS_INPUT_ID, address),
            (self.CITY_INPUT_ID, city), (self.STATE_INPUT_ID, state),
            (self.ZIP_CODE_INPUT_ID, zip_code), (self.COUNTRY_INPUT_ID, country),
        ):
            if value:
                self._enter(test_id, value)
        return self

    def go_back(self):
        """Go back to settings without saving"""
        self.tap_back()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
