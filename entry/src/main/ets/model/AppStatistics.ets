export class AppStatistics {
  private static instance: AppStatistics;
  private _noteCount: number = 0;
  private _likeCount: number = 0;
  private _followCount: number = 0;
  private _followerCount: number = 0;

  private constructor() {
    this.loadFromStorage();
  }

  public static getInstance(): AppStatistics {
    if (!AppStatistics.instance) {
      AppStatistics.instance = new AppStatistics();
    }
    return AppStatistics.instance;
  }

  public get noteCount(): number {
    return this._noteCount;
  }

  public get likeCount(): number {
    return this._likeCount;
  }

  public get followCount(): number {
    return this._followCount;
  }

  public get followerCount(): number {
    return this._followerCount;
  }

  public incrementNoteCount(): void {
    this._noteCount++;
    this.saveToStorage();
    this.notifyUpdate();
  }

  public incrementLikeCount(): void {
    this._likeCount++;
    this.saveToStorage();
    this.notifyUpdate();
  }

  public incrementFollowCount(): void {
    this._followCount++;
    this.saveToStorage();
    this.notifyUpdate();
  }

  public decrementFollowCount(): void {
    if (this._followCount > 0) {
      this._followCount--;
      this.saveToStorage();
      this.notifyUpdate();
    }
  }

  public incrementFollowerCount(): void {
    this._followerCount++;
    this.saveToStorage();
    this.notifyUpdate();
  }

  private saveToStorage(): void {
    try {
      AppStorage.setOrCreate('statistics_noteCount', this._noteCount);
      AppStorage.setOrCreate('statistics_likeCount', this._likeCount);
      AppStorage.setOrCreate('statistics_followCount', this._followCount);
      AppStorage.setOrCreate('statistics_followerCount', this._followerCount);
    } catch (e) {
      console.error('Failed to save statistics:', JSON.stringify(e));
    }
  }

  private loadFromStorage(): void {
    try {
      const noteCount: number | undefined = AppStorage.get('statistics_noteCount');
      const likeCount: number | undefined = AppStorage.get('statistics_likeCount');
      const followCount: number | undefined = AppStorage.get('statistics_followCount');
      const followerCount: number | undefined = AppStorage.get('statistics_followerCount');

      if (noteCount !== undefined) this._noteCount = noteCount;
      if (likeCount !== undefined) this._likeCount = likeCount;
      if (followCount !== undefined) this._followCount = followCount;
      if (followerCount !== undefined) this._followerCount = followerCount;
    } catch (e) {
      console.error('Failed to load statistics:', JSON.stringify(e));
    }
  }

  private notifyUpdate(): void {
    try {
      AppStorage.setOrCreate('statistics_updated', Date.now());
    } catch (e) {
      console.error('Failed to notify statistics update:', JSON.stringify(e));
    }
  }

  public reset(): void {
    this._noteCount = 0;
    this._likeCount = 0;
    this._followCount = 0;
    this._followerCount = 0;
    this.saveToStorage();
    this.notifyUpdate();
  }
}
