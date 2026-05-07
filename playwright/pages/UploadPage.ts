import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class UploadPage extends BasePage {
  private readonly baseUrl: string;

  readonly FILE_INPUT = "[data-testid='file-input'], input[type='file'], input[accept*='image']";
  readonly DROPZONE = "[data-testid='dropzone'], .dropzone, [class*='drop-zone'], [class*='upload-area']";
  readonly GENERATE_BUTTON = "[data-testid='generate-button'], button:has-text('Generate'), button:has-text('Create Listing')";
  readonly CANCEL_BUTTON = "[data-testid='cancel-button'], button:has-text('Cancel'), a:has-text('Cancel')";
  readonly IMAGE_PREVIEW = "[data-testid='image-preview'], .preview, .image-preview, img[class*='preview']";
  readonly LOADING_INDICATOR = "[data-testid='loading'], .loading, .spinner, [class*='loading']";
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']";
  readonly PRODUCT_NAME_INPUT = "[data-testid='product-name'], input[name='productName'], input[placeholder*='product name' i], input[aria-label*='product' i]";
  readonly CATEGORY_SELECT = "[data-testid='category-select'], select[name='category'], [aria-label='Category']";
  readonly KEY_FEATURES_INPUT = "[data-testid='key-features'], textarea[name='keyFeatures'], textarea[placeholder*='features' i]";
  readonly TONE_SELECT = "[data-testid='tone-select'], select[name='tone'], [aria-label='Tone']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/upload`);
  }

  async isUploadScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isVisible(this.FILE_INPUT, 5000)) ||
      (await this.isVisible(this.DROPZONE, 3000)) ||
      (await this.isTextPresent('Upload', 3000))
    );
  }

  async uploadImage(filePath: string): Promise<void> {
    await this.page.setInputFiles(this.FILE_INPUT, filePath);
  }

  async isImageUploaded(): Promise<boolean> {
    return this.isVisible(this.IMAGE_PREVIEW, 5000);
  }

  async fillProductDetails(opts: {
    productName?: string;
    category?: string;
    keyFeatures?: string;
    tone?: string;
  }): Promise<void> {
    if (opts.productName && (await this.isVisible(this.PRODUCT_NAME_INPUT, 3000))) {
      await this.fill(this.PRODUCT_NAME_INPUT, opts.productName);
    }
    if (opts.category && (await this.isVisible(this.CATEGORY_SELECT, 3000))) {
      await this.page.selectOption(this.CATEGORY_SELECT, opts.category);
    }
    if (opts.keyFeatures && (await this.isVisible(this.KEY_FEATURES_INPUT, 3000))) {
      await this.fill(this.KEY_FEATURES_INPUT, opts.keyFeatures);
    }
    if (opts.tone && (await this.isVisible(this.TONE_SELECT, 3000))) {
      await this.page.selectOption(this.TONE_SELECT, opts.tone);
    }
  }

  async clickGenerate(): Promise<void> {
    await this.click(this.GENERATE_BUTTON);
  }

  async waitForGeneration(timeout = 60_000): Promise<void> {
    await this.page.waitForSelector(this.LOADING_INDICATOR, { state: 'hidden', timeout });
  }

  async isErrorDisplayed(): Promise<boolean> {
    return this.isVisible(this.ERROR_MESSAGE, 3000);
  }
}
