"""
Upload Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage
import os


class UploadPage(BasePage):
    """Page object for Upload/Create Listing screen"""

    # Selectors
    FILE_INPUT = "[data-testid='file-input'], input[type='file'], input[accept*='image']"
    DROPZONE = "[data-testid='dropzone'], .dropzone, [class*='drop-zone'], [class*='upload-area']"
    UPLOAD_BUTTON = "[data-testid='upload-button'], button:has-text('Upload'), label:has-text('Upload')"
    GENERATE_BUTTON = "[data-testid='generate-button'], button:has-text('Generate'), button:has-text('Create Listing')"
    CANCEL_BUTTON = "[data-testid='cancel-button'], button:has-text('Cancel'), a:has-text('Cancel')"
    BACK_BUTTON = "[data-testid='back-button'], button:has-text('Back'), a:has-text('Back'), [aria-label='Back']"
    IMAGE_PREVIEW = "[data-testid='image-preview'], .preview, .image-preview, img[class*='preview']"
    REMOVE_IMAGE = "[data-testid='remove-image'], button:has-text('Remove'), button[aria-label='Remove']"
    LOADING_INDICATOR = "[data-testid='loading'], .loading, .spinner, [class*='loading']"
    ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']"
    SUCCESS_MESSAGE = "[data-testid='success-message'], .success, .alert-success"
    TITLE_INPUT = "[data-testid='title-input'], input[name='title'], input[placeholder*='title' i]"
    DESCRIPTION_INPUT = "[data-testid='description-input'], textarea[name='description'], textarea[placeholder*='description' i]"
    CATEGORY_SELECT = "[data-testid='category-select'], select[name='category'], [aria-label='Category']"
    PRICE_INPUT = "[data-testid='price-input'], input[name='price'], input[placeholder*='price' i]"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.upload_url = f"{base_url}/upload" if base_url else "/upload"

    def navigate_to_upload(self) -> "UploadPage":
        """Navigate to upload page"""
        self.navigate(self.upload_url)
        self.wait_for_load_state()
        return self

    def is_upload_screen_displayed(self) -> bool:
        """Check if upload screen is displayed"""
        return (
            self.is_visible(self.FILE_INPUT, timeout=5000) or
            self.is_visible(self.DROPZONE, timeout=3000) or
            self.is_text_present("Upload", timeout=3000) or
            self.is_text_present("Add Product", timeout=3000)
        )

    def upload_image(self, file_path: str) -> "UploadPage":
        """Upload an image file"""
        if os.path.exists(file_path):
            self.page.set_input_files(self.FILE_INPUT, file_path)
        return self

    def upload_multiple_images(self, file_paths: list) -> "UploadPage":
        """Upload multiple image files"""
        valid_paths = [p for p in file_paths if os.path.exists(p)]
        if valid_paths:
            self.page.set_input_files(self.FILE_INPUT, valid_paths)
        return self

    def click_upload_button(self) -> "UploadPage":
        """Click upload button"""
        if self.is_visible(self.UPLOAD_BUTTON, timeout=3000):
            self.click(self.UPLOAD_BUTTON)
        return self

    def click_generate(self) -> None:
        """Click generate listing button"""
        self.click(self.GENERATE_BUTTON)
        self.wait_for_load_state()

    def click_cancel(self) -> "HomePage":
        """Click cancel button"""
        self.click(self.CANCEL_BUTTON)
        self.wait_for_load_state()
        from .home_page import HomePage
        return HomePage(self.page, self.base_url)

    def go_back(self) -> "HomePage":
        """Go back to home page"""
        if self.is_visible(self.BACK_BUTTON, timeout=2000):
            self.click(self.BACK_BUTTON)
        else:
            self.page.go_back()
        self.wait_for_load_state()
        from .home_page import HomePage
        return HomePage(self.page, self.base_url)

    def is_image_uploaded(self) -> bool:
        """Check if image preview is visible"""
        return self.is_visible(self.IMAGE_PREVIEW, timeout=5000)

    def remove_uploaded_image(self) -> "UploadPage":
        """Remove uploaded image"""
        if self.is_visible(self.REMOVE_IMAGE, timeout=2000):
            self.click(self.REMOVE_IMAGE)
        return self

    def is_generate_enabled(self) -> bool:
        """Check if generate button is enabled"""
        return self.is_enabled(self.GENERATE_BUTTON)

    def is_loading(self) -> bool:
        """Check if loading indicator is visible"""
        return self.is_visible(self.LOADING_INDICATOR, timeout=1000)

    def wait_for_generation(self, timeout: int = 60000) -> None:
        """Wait for listing generation to complete"""
        # Wait for loading to finish
        try:
            self.page.wait_for_selector(
                self.LOADING_INDICATOR,
                state="hidden",
                timeout=timeout
            )
        except:
            pass

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_visible(self.ERROR_MESSAGE, timeout=3000)

    def get_error_message(self) -> str:
        """Get error message text"""
        if self.is_error_displayed():
            return self.get_text(self.ERROR_MESSAGE)
        return ""

    def is_success_displayed(self) -> bool:
        """Check if success message is displayed"""
        return self.is_visible(self.SUCCESS_MESSAGE, timeout=3000)

    def enter_title(self, title: str) -> "UploadPage":
        """Enter listing title"""
        if self.is_visible(self.TITLE_INPUT, timeout=3000):
            self.clear_and_fill(self.TITLE_INPUT, title)
        return self

    def enter_description(self, description: str) -> "UploadPage":
        """Enter listing description"""
        if self.is_visible(self.DESCRIPTION_INPUT, timeout=3000):
            self.clear_and_fill(self.DESCRIPTION_INPUT, description)
        return self

    def select_category(self, category: str) -> "UploadPage":
        """Select listing category"""
        if self.is_visible(self.CATEGORY_SELECT, timeout=3000):
            self.select_option(self.CATEGORY_SELECT, category)
        return self

    def enter_price(self, price: str) -> "UploadPage":
        """Enter listing price"""
        if self.is_visible(self.PRICE_INPUT, timeout=3000):
            self.clear_and_fill(self.PRICE_INPUT, price)
        return self
