"""
Upload Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class UploadPage(BasePage):
    """Page object for Upload/Create Listing screen"""

    UPLOAD_IMAGES_BUTTON_ID = "upload-images-button"
    CONTINUE_BUTTON_ID = "continue-button"
    SKIP_UPLOAD_BUTTON_ID = "skip-upload-button"

    def is_upload_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if upload screen is displayed"""
        return self.is_present(self.by_id(self.UPLOAD_IMAGES_BUTTON_ID), timeout)

    def is_continue_displayed(self) -> bool:
        """Check if the Continue button is displayed"""
        return self.is_present(self.by_id(self.CONTINUE_BUTTON_ID))

    def tap_upload_images(self):
        """Open the image picker"""
        return self.tap(self.by_id(self.UPLOAD_IMAGES_BUTTON_ID))

    def tap_continue(self):
        """Tap Continue (needs at least one image)"""
        return self.tap(self.by_id(self.CONTINUE_BUTTON_ID))

    def tap_skip(self):
        """Tap 'Skip this step' (enabled only before any image is added)"""
        return self.tap(self.by_id(self.SKIP_UPLOAD_BUTTON_ID))

    def go_back(self):
        """Go back to home via the AppBar back button"""
        self.tap_back()
        from .home_page import HomePage
        return HomePage(self.driver)
