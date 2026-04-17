/**
 * BasicDataSource - LazyForEach 通用数据源基类
 *
 * 实现 IDataSource 接口，支持数据变更通知
 * 用于长列表懒加载，滚动时自动回收不可见组件
 */

import { Post } from '../model/Post';
import { LikeManager } from './LikeManager';

export interface IDataSource {
  totalCount(): number;
  getData(index: number): Object | undefined;
  registerDataChangeListener(listener: DataChangeListener): void;
  unregisterDataChangeListener(listener: DataChangeListener): void;
}

export interface DataChangeListener {
  onDataReloaded(): void;
  onDataAdded(index: number): void;
  onDataMoved(from: number, to: number): void;
  onDataDeleted(index: number): void;
  onDataChanged(index: number): void;
}

/**
 * 通用列表数据源
 * 支持任意类型的数组数据
 */
export class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private data: T[] = [];

  constructor(initialData: T[] = []) {
    this.data = initialData;
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): Object | undefined {  
    return this.data[index] as Object;
  }

  getItem(index: number): T | undefined {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  // 通知数据重新加载
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }

  // 通知数据添加
  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdded(index);
    });
  }

  // 通知数据删除
  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDeleted(index);
    });
  }

  // 通知数据变更
  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChanged(index);
    });
  }

  // 更新所有数据
  setData(newData: T[]): void {
    this.data = newData;
    this.notifyDataReload();
  }

  // 获取所有数据
  getAllData(): T[] {
    return this.data;
  }

  // 添加单条数据
  addItem(item: T, index?: number): void {
    if (index !== undefined) {
      this.data.splice(index, 0, item);
      this.notifyDataAdd(index);
    } else {
      this.data.push(item);
      this.notifyDataAdd(this.data.length - 1);
    }
  }

  // 删除单条数据
  removeItem(index: number): void {
    this.data.splice(index, 1);
    this.notifyDataDelete(index);
  }

  // 更新单条数据
  updateItem(index: number, item: T): void {
    this.data[index] = item;
    this.notifyDataChange(index);
  }
}

/**
 * Post 数据源 - 专门用于帖子列表
 * 支持点赞状态同步
 */
export class PostDataSource extends BasicDataSource<Post> {
  private likeManager: LikeManager | null = null;

  constructor(initialData: Post[] = [], likeManager?: LikeManager) {
    super(initialData);
    this.likeManager = likeManager || null;
  }

  // 切换点赞状态
  toggleLike(index: number): void {
    const post = this.getItem(index);
    if (post) {
      post.isLiked = !post.isLiked;
      post.likes += post.isLiked ? 1 : -1;
      this.notifyDataChange(index);
    }
  }

  // 同步点赞状态（从 LikeManager）
  syncLikeStatus(likeManager: LikeManager): void {
    const data = this.getAllData();
    data.forEach((post: Post, index: number) => {
      const isLiked: boolean = likeManager.isPostLiked(post.id);
      if (post.isLiked !== isLiked) {
        post.isLiked = isLiked;
        this.notifyDataChange(index);
      }
    });
  }
}
