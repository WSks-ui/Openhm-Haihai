import { Post, mockPosts, Comment } from '../model/Post';

export class LikeManager {
  private static instance: LikeManager;
  private likedPostIds: Set<string> = new Set();
  private likedCommentIds: Set<string> = new Set();

  private constructor() {
    this.loadLikedPosts();
    this.loadLikedComments();
  }

  static getInstance(): LikeManager {
    if (!LikeManager.instance) {
      LikeManager.instance = new LikeManager();
    }
    return LikeManager.instance;
  }

  private loadLikedPosts() {
    try {
      const stored = AppStorage.Get('likedPostIds') as string;
      if (stored) {
        const ids = JSON.parse(stored) as string[];
        this.likedPostIds = new Set(ids);
        this.syncMockPosts();
      }
    } catch (e) {
      console.error('Failed to load liked posts:', e);
    }
  }

  private saveLikedPosts() {
    try {
      const ids = Array.from(this.likedPostIds);
      AppStorage.SetOrCreate('likedPostIds', JSON.stringify(ids));
    } catch (e) {
      console.error('Failed to save liked posts:', e);
    }
  }

  private loadLikedComments() {
    try {
      const stored = AppStorage.Get('likedCommentIds') as string;
      if (stored) {
        const ids = JSON.parse(stored) as string[];
        this.likedCommentIds = new Set(ids);
      }
    } catch (e) {
      console.error('Failed to load liked comments:', e);
    }
  }

  private saveLikedComments() {
    try {
      const ids = Array.from(this.likedCommentIds);
      AppStorage.SetOrCreate('likedCommentIds', JSON.stringify(ids));
    } catch (e) {
      console.error('Failed to save liked comments:', e);
    }
  }

  private syncMockPosts() {
    mockPosts.forEach(post => {
      post.isLiked = this.likedPostIds.has(post.id);
    });
  }

  isPostLiked(postId: string): boolean {
    return this.likedPostIds.has(postId);
  }

  toggleLike(post: Post): boolean {
    const isLiked = this.likedPostIds.has(post.id);
    if (isLiked) {
      this.likedPostIds.delete(post.id);
      post.likes = Math.max(0, post.likes - 1);
      post.isLiked = false;
    } else {
      this.likedPostIds.add(post.id);
      post.likes += 1;
      post.isLiked = true;
    }
    this.saveLikedPosts();
    return !isLiked;
  }

  getLikedPosts(): Post[] {
    return mockPosts.filter(post => this.likedPostIds.has(post.id));
  }

  getLikeCount(): number {
    return this.likedPostIds.size;
  }

  isCommentLiked(commentId: string): boolean {
    return this.likedCommentIds.has(commentId);
  }

  toggleCommentLike(comment: Comment): boolean {
    const isLiked = this.likedCommentIds.has(comment.id);
    if (isLiked) {
      this.likedCommentIds.delete(comment.id);
      comment.likes = Math.max(0, comment.likes - 1);
    } else {
      this.likedCommentIds.add(comment.id);
      comment.likes += 1;
    }
    this.saveLikedComments();
    return !isLiked;
  }
}

PersistentStorage.persistProp('likedPostIds', '[]');
PersistentStorage.persistProp('likedCommentIds', '[]');
