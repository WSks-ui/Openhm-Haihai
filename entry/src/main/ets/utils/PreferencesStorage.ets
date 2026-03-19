import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const STORE_NAME = 'app_preferences';
const KEY_COLOR_MODE = 'color_mode';
const KEY_GRAYSCALE_MODE = 'grayscale_mode';
const KEY_CURRENT_USER_PHONE = 'current_user_phone';

export class PreferencesStorage {
  private static instance: PreferencesStorage | null = null;
  private preferences: preferences.Preferences | null = null;

  private constructor() {
  }

  public static getInstance(): PreferencesStorage {
    if (!PreferencesStorage.instance) {
      PreferencesStorage.instance = new PreferencesStorage();
    }
    return PreferencesStorage.instance;
  }

  public async init(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(DOMAIN, 'PreferencesStorage', 'Preferences initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to initialize preferences: %{public}s', JSON.stringify(err));
    }
  }

  public async getColorMode(defaultValue: number = -1): Promise<number> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized, returning default value');
      return defaultValue;
    }
    try {
      const value = await this.preferences.get(KEY_COLOR_MODE, defaultValue);
      hilog.info(DOMAIN, 'PreferencesStorage', 'Get color mode: %{public}d', value as number);
      return value as number;
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to get color mode: %{public}s', JSON.stringify(err));
      return defaultValue;
    }
  }

  public async setColorMode(colorMode: number): Promise<void> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized');
      return;
    }
    try {
      await this.preferences.put(KEY_COLOR_MODE, colorMode);
      await this.preferences.flush();
      hilog.info(DOMAIN, 'PreferencesStorage', 'Set color mode: %{public}d', colorMode);
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to set color mode: %{public}s', JSON.stringify(err));
    }
  }

  public async getGrayscaleMode(defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized, returning default value');
      return defaultValue;
    }
    try {
      const value = await this.preferences.get(KEY_GRAYSCALE_MODE, defaultValue);
      hilog.info(DOMAIN, 'PreferencesStorage', 'Get grayscale mode: %{public}s', value as boolean);
      return value as boolean;
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to get grayscale mode: %{public}s', JSON.stringify(err));
      return defaultValue;
    }
  }

  public async setGrayscaleMode(grayscaleMode: boolean): Promise<void> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized');
      return;
    }
    try {
      await this.preferences.put(KEY_GRAYSCALE_MODE, grayscaleMode);
      await this.preferences.flush();
      hilog.info(DOMAIN, 'PreferencesStorage', 'Set grayscale mode: %{public}s', grayscaleMode);
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to set grayscale mode: %{public}s', JSON.stringify(err));
    }
  }

  public async getCurrentUserPhone(): Promise<string> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized, returning default value');
      return '';
    }
    try {
      const value = await this.preferences.get(KEY_CURRENT_USER_PHONE, '');
      return value as string;
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to get current user phone: %{public}s', JSON.stringify(err));
      return '';
    }
  }

  public async setCurrentUserPhone(phoneNumber: string): Promise<void> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized');
      return;
    }
    try {
      await this.preferences.put(KEY_CURRENT_USER_PHONE, phoneNumber);
      await this.preferences.flush();
      hilog.info(DOMAIN, 'PreferencesStorage', 'Set current user phone: %{public}s', phoneNumber);
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to set current user phone: %{public}s', JSON.stringify(err));
    }
  }

  public async clearCurrentUser(): Promise<void> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'PreferencesStorage', 'Preferences not initialized');
      return;
    }
    try {
      await this.preferences.delete(KEY_CURRENT_USER_PHONE);
      await this.preferences.flush();
      hilog.info(DOMAIN, 'PreferencesStorage', 'Current user cleared');
    } catch (err) {
      hilog.error(DOMAIN, 'PreferencesStorage', 'Failed to clear current user: %{public}s', JSON.stringify(err));
    }
  }
}
