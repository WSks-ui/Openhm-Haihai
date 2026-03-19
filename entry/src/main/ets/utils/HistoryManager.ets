import { Post, mockPosts, currentKeplerPost } from '../model/Post';

export class HistoryManager {
  removeFromHistory(id: string) {
    throw new Error('Method not implemented.');
  }
  private static instance: HistoryManager;
  private historyPostIds: string[] = [];
  private readonly MAX_HISTORY = 20;

  private constructor() {
    this.loadHistory();
  }

  static getInstance(): HistoryManager {
    if (!HistoryManager.instance) {
      HistoryManager.instance = new HistoryManager();
    }
    return HistoryManager.instance;
  }

  private loadHistory() {
    try {
      const stored = AppStorage.Get('historyPostIds') as string;
      if (stored) {
        this.historyPostIds = JSON.parse(stored) as string[];
      }
    } catch (e) {
      console.error('Failed to load history:', e);
    }
  }

  private saveHistory() {
    try {
      AppStorage.SetOrCreate('historyPostIds', JSON.stringify(this.historyPostIds));
    } catch (e) {
      console.error('Failed to save history:', e);
    }
  }

  addToHistory(postId: string) {
    const index = this.historyPostIds.indexOf(postId);
    if (index !== -1) {
      this.historyPostIds.splice(index, 1);
    }
    this.historyPostIds.unshift(postId);
    
    if (this.historyPostIds.length > this.MAX_HISTORY) {
      this.historyPostIds = this.historyPostIds.slice(0, this.MAX_HISTORY);
    }
    
    this.saveHistory();
  }

  getHistoryPosts(): Post[] {
    const posts: Post[] = [];
    this.historyPostIds.forEach(id => {
      let post = mockPosts.find(p => p.id === id);
      if (!post && currentKeplerPost && currentKeplerPost.id === id) {
        post = currentKeplerPost;
      }
      if (post) {
        posts.push(post);
      }
    });
    return posts;
  }

  clearHistory() {
    this.historyPostIds = [];
    this.saveHistory();
  }
}

PersistentStorage.persistProp('historyPostIds', '[]');
