"""
Upload Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class UploadPage(BasePage):
    """Page object for Upload/Create Listing screen"""

    # Locators
    PAGE_TITLE = "Upload Product Images"
    ADD_PHOTOS_TEXT = "Add Product Photos"
    UPLOAD_PROMPT = "Click to upload images"
    CONTINUE_BUTTON = "Continue"
    SKIP_BUTTON = "Skip this step"
    TAKE_PHOTO_BUTTON = "Take Photo"
    CHOOSE_GALLERY_BUTTON = "Choose from Gallery"
    GENERATE_BUTTON = "Generate Listing"
    CLEAR_IMAGES_BUTTON = "Clear"
    IMAGE_PREVIEW = "image_preview"

    # Generated listing elements
    TITLE_FIELD = "Title"
    DESCRIPTION_FIELD = "Description"
    PRICE_FIELD = "Price"
    COPY_BUTTON = "Copy"
    SHARE_BUTTON = "Share"
    SAVE_BUTTON = "Save"

    def is_upload_screen_displayed(self) -> bool:
        """Check if upload screen is displayed"""
        return (self.is_text_present(self.PAGE_TITLE) or
                self.is_text_present(self.ADD_PHOTOS_TEXT) or
                self.is_text_present("Upload"))

    def tap_take_photo(self):
        """Tap take photo button"""
        self.tap_by_text(self.TAKE_PHOTO_BUTTON)
        return self

    def tap_choose_gallery(self):
        """Tap choose from gallery button"""
        self.tap_by_text(self.CHOOSE_GALLERY_BUTTON)
        return self

    def tap_generate_listing(self):
        """Tap generate listing button"""
        self.tap_by_text(self.GENERATE_BUTTON)
        return self

    def wait_for_generation_complete(self, timeout: int = 60):
        """Wait for AI generation to complete"""
        # Wait for title field to appear (indicates generation is done)
        self.wait_for_text(self.TITLE_FIELD, timeout=timeout)
        return self

    def has_images_selected(self) -> bool:
        """Check if images are selected"""
        try:
            self.find_by_content_desc(self.IMAGE_PREVIEW)
            return True
        except:
            return False

    def clear_images(self):
        """Clear selected images"""
        if self.is_text_present(self.CLEAR_IMAGES_BUTTON, timeout=2):
            self.tap_by_text(self.CLEAR_IMAGES_BUTTON)
        return self

    def get_generated_title(self) -> str:
        """Get generated listing title"""
        try:
            element = self.find_by_text(self.TITLE_FIELD, exact=False)
            # Find the input field associated with the label
            return element.text
        except:
            return ""

    def get_generated_description(self) -> str:
        """Get generated listing description"""
        try:
            element = self.find_by_text(self.DESCRIPTION_FIELD, exact=False)
            return element.text
        except:
            return ""

    def get_generated_price(self) -> str:
        """Get generated price"""
        try:
            element = self.find_by_text(self.PRICE_FIELD, exact=False)
            return element.text
        except:
            return ""

    def tap_copy(self):
        """Tap copy button"""
        self.tap_by_text(self.COPY_BUTTON)
        return self

    def tap_share(self):
        """Tap share button"""
        self.tap_by_text(self.SHARE_BUTTON)
        return self

    def tap_save(self):
        """Tap save listing button"""
        self.scroll_down()
        self.tap_by_text(self.SAVE_BUTTON)
        return self

    def is_success_message_displayed(self) -> bool:
        """Check if success message is displayed"""
        return (self.is_text_present("Listing saved") or
                self.is_text_present("Successfully"))

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_text_present("Error") or self.is_text_present("Failed")

    def is_no_credits_message_displayed(self) -> bool:
        """Check if no credits message is displayed"""
        return (self.is_text_present("No credits") or
                self.is_text_present("insufficient credits"))

    def go_back(self):
        """Go back to home"""
        self.driver.back()
        from .home_page import HomePage
        return HomePage(self.driver)
