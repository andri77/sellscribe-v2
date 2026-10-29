"""
Details Page Object for SellScribe Mobile App (product details before generating)
"""
from .base_page import BasePage


class DetailsPage(BasePage):
    """Page object for the product Details screen"""

    PRODUCT_NAME_INPUT_ID = "product-name-input"
    KEY_FEATURES_INPUT_ID = "key-features-input"
    TARGET_AUDIENCE_INPUT_ID = "target-audience-input"
    GENERATE_BUTTON_ID = "generate-listing-button"
    BACK_BUTTON_ID = "details-back-button"

    def is_details_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if the details screen is displayed"""
        return self.is_present(self.by_id(self.PRODUCT_NAME_INPUT_ID), timeout)

    def enter_product_name(self, name: str):
        """Enter the product name"""
        return self.type_into(self.PRODUCT_NAME_INPUT_ID, name)
