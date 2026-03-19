import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface Draft {
  id: string;
  content: string;
  images: string[];
  createdAt: number;
  updatedAt: number;
}

const DOMAIN = 0x0001;
const STORE_NAME = 'draft_preferences';
const KEY_DRAFTS = 'drafts_list';

export class DraftManager {
  private static instance: DraftManager | null = null;
  private preferences: preferences.Preferences | null = null;

  private constructor() {
  }

  public static getInstance(): DraftManager {
    if (!DraftManager.instance) {
      DraftManager.instance = new DraftManager();
    }
    return DraftManager.instance;
  }

  public async init(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(DOMAIN, 'DraftManager', 'DraftManager initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'DraftManager', 'Failed to initialize DraftManager: %{public}s', JSON.stringify(err));
    }
  }

  public async saveDraft(content: string, images: string[]): Promise<Draft> {
    const drafts = await this.getDrafts();
    const now = Date.now();
    const newDraft: Draft = {
      id: `draft_${now}`,
      content: content,
      images: images,
      createdAt: now,
      updatedAt: now
    };
    drafts.unshift(newDraft);
    await this.saveDrafts(drafts);
    return newDraft;
  }

  public async updateDraft(id: string, content: string, images: string[]): Promise<Draft | null> {
    const drafts = await this.getDrafts();
    const index = drafts.findIndex(draft => draft.id === id);
    if (index !== -1) {
      drafts[index].content = content;
      drafts[index].images = images;
      drafts[index].updatedAt = Date.now();
      await this.saveDrafts(drafts);
      return drafts[index];
    }
    return null;
  }

  public async deleteDraft(id: string): Promise<boolean> {
    const drafts = await this.getDrafts();
    const initialLength = drafts.length;
    const filteredDrafts = drafts.filter(draft => draft.id !== id);
    if (filteredDrafts.length !== initialLength) {
      await this.saveDrafts(filteredDrafts);
      return true;
    }
    return false;
  }

  public async getDrafts(): Promise<Draft[]> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'DraftManager', 'Preferences not initialized, returning empty array');
      return [];
    }
    try {
      const value = await this.preferences.get(KEY_DRAFTS, '[]');
      const drafts: Draft[] = JSON.parse(value as string);
      hilog.info(DOMAIN, 'DraftManager', 'Get drafts: %{public}d items', drafts.length);
      return drafts;
    } catch (err) {
      hilog.error(DOMAIN, 'DraftManager', 'Failed to get drafts: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  public async getDraft(id: string): Promise<Draft | null> {
    const drafts = await this.getDrafts();
    return drafts.find(draft => draft.id === id) || null;
  }

  private async saveDrafts(drafts: Draft[]): Promise<void> {
    if (!this.preferences) {
      hilog.warn(DOMAIN, 'DraftManager', 'Preferences not initialized');
      return;
    }
    try {
      await this.preferences.put(KEY_DRAFTS, JSON.stringify(drafts));
      await this.preferences.flush();
      hilog.info(DOMAIN, 'DraftManager', 'Saved drafts: %{public}d items', drafts.length);
    } catch (err) {
      hilog.error(DOMAIN, 'DraftManager', 'Failed to save drafts: %{public}s', JSON.stringify(err));
    }
  }
}
