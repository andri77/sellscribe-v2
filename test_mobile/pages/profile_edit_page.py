"""
Profile Edit Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class ProfileEditPage(BasePage):
    """Page object for Profile Edit screen"""

    # Locators
    PAGE_TITLE = "Edit Profile"
    FIRST_NAME_FIELD = "First Name"
    LAST_NAME_FIELD = "Last Name"
    MOBILE_FIELD = "Mobile Number"
    ADDRESS_FIELD = "Street Address"
    CITY_FIELD = "City"
    STATE_FIELD = "State"
    ZIP_CODE_FIELD = "ZIP Code"
    COUNTRY_FIELD = "Country"
    SAVE_BUTTON = "Save Changes"

    def is_profile_edit_screen_displayed(self) -> bool:
        """Check if profile edit screen is displayed"""
        return self.is_any_text_present(
            self.PAGE_TITLE, self.FIRST_NAME_FIELD, self.SAVE_BUTTON, "Profile", timeout=5
        )

    def _enter_field(self, field_label: str, value: str):
        """Helper to enter value in a field"""
        self.tap_by_text(field_label)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(value)
        self.hide_keyboard()
        return self

    def enter_first_name(self, name: str):
        """Enter first name"""
        return self._enter_field(self.FIRST_NAME_FIELD, name)

    def enter_last_name(self, name: str):
        """Enter last name"""
        return self._enter_field(self.LAST_NAME_FIELD, name)

    def enter_mobile(self, mobile: str):
        """Enter mobile number"""
        return self._enter_field(self.MOBILE_FIELD, mobile)

    def enter_address(self, address: str):
        """Enter street address"""
        self.scroll_down()
        return self._enter_field(self.ADDRESS_FIELD, address)

    def enter_city(self, city: str):
        """Enter city"""
        return self._enter_field(self.CITY_FIELD, city)

    def enter_state(self, state: str):
        """Enter state"""
        return self._enter_field(self.STATE_FIELD, state)

    def enter_zip_code(self, zip_code: str):
        """Enter ZIP code"""
        return self._enter_field(self.ZIP_CODE_FIELD, zip_code)

    def enter_country(self, country: str):
        """Enter country"""
        return self._enter_field(self.COUNTRY_FIELD, country)

    def tap_save(self):
        """Tap save button"""
        self.scroll_down()
        self.tap_by_text(self.SAVE_BUTTON)
        return self

    def fill_profile(self, first_name: str = None, last_name: str = None,
                     mobile: str = None, address: str = None,
                     city: str = None, state: str = None,
                     zip_code: str = None, country: str = None):
        """Fill profile fields"""
        if first_name:
            self.enter_first_name(first_name)
        if last_name:
            self.enter_last_name(last_name)
        if mobile:
            self.enter_mobile(mobile)
        if address:
            self.enter_address(address)
        if city:
            self.enter_city(city)
        if state:
            self.enter_state(state)
        if zip_code:
            self.enter_zip_code(zip_code)
        if country:
            self.enter_country(country)
        return self

    def is_success_message_displayed(self) -> bool:
        """Check if success message is displayed"""
        return self.is_text_present("Profile updated successfully")

    def go_back(self):
        """Go back to settings"""
        self._back_with_wait()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
