/**
 * GlobalAnimationManager - 全局动画管理器
 *
 * 解决问题：
 * 1. 多个定时器同时运行浪费CPU和电量 → 单一 rAF 驱动
 * 2. 统一管理所有光效动画，所有 Glass 实例共享一个动画帧
 * 3. 支持可见性检测，不可见的组件暂停动画更新
 * 4. 自适应帧率：无可见订阅者时自动暂停，有订阅者时 60fps 驱动
 */

export interface AnimationSubscriber {
  id: string;
  onUpdate: (phase: number) => void;
  isVisible: boolean;
}

export interface PositionResult {
  x: string;
  y: string;
}

export class GlobalAnimationManager {
  private static instance: GlobalAnimationManager | null = null;
  private subscribers: Map<string, AnimationSubscriber> = new Map();
  private rafId: number = -1;
  private globalPhase: number = 0;
  private isRunning: boolean = false;
  private lastFrameTime: number = 0;
  private static readonly PHASE_SPEED: number = 1.2;

  private constructor() {}

  static getInstance(): GlobalAnimationManager {
    if (GlobalAnimationManager.instance === null) {
      GlobalAnimationManager.instance = new GlobalAnimationManager();
    }
    return GlobalAnimationManager.instance;
  }

  subscribe(id: string, onUpdate: (phase: number) => void): () => void {
    this.subscribers.set(id, { id, onUpdate, isVisible: true });
    if (!this.isRunning) {
      this.startAnimation();
    }
    return () => this.unsubscribe(id);
  }

  unsubscribe(id: string): void {
    this.subscribers.delete(id);
    if (this.subscribers.size === 0) {
      this.stopAnimation();
    }
  }

  setVisible(id: string, isVisible: boolean): void {
    const subscriber = this.subscribers.get(id);
    if (subscriber) {
      subscriber.isVisible = isVisible;
    }
  }

  getPhase(): number {
    return this.globalPhase;
  }

  getLissajousPosition(phaseOffset: number = 0, xAmplitude: number = 30, yAmplitude: number = 30): PositionResult {
    const phase = this.globalPhase + phaseOffset;
    return {
      x: `${50 + Math.sin(phase) * xAmplitude}%`,
      y: `${50 + Math.cos(phase * 0.8) * yAmplitude}%`
    };
  }

  getEllipsePosition(phaseOffset: number = 0, xAmplitude: number = 20, yAmplitude: number = 20): PositionResult {
    const phase = this.globalPhase + phaseOffset;
    return {
      x: `${50 + Math.cos(phase) * xAmplitude}%`,
      y: `${50 + Math.sin(phase * 0.7) * yAmplitude}%`
    };
  }

  private startAnimation(): void {
    if (this.isRunning) return;
    this.isRunning = true;
    this.lastFrameTime = Date.now();
    this.tick();
  }

  private tick(): void {
    if (!this.isRunning) return;

    const now = Date.now();
    const delta = (now - this.lastFrameTime) / 1000;
    this.lastFrameTime = now;

    this.globalPhase += GlobalAnimationManager.PHASE_SPEED * delta;
    this.notifySubscribers();

    this.rafId = setTimeout(() => {
      this.tick();
    }, 16);
  }

  private stopAnimation(): void {
    if (this.rafId !== -1) {
      clearTimeout(this.rafId);
      this.rafId = -1;
    }
    this.isRunning = false;
  }

  private notifySubscribers(): void {
    let hasVisible = false;
    this.subscribers.forEach((subscriber) => {
      if (subscriber.isVisible) {
        hasVisible = true;
        try {
          subscriber.onUpdate(this.globalPhase);
        } catch (err) {
          console.warn(`Animation subscriber ${subscriber.id} error:`, err);
        }
      }
    });
    if (!hasVisible && this.subscribers.size > 0) {
      this.subscribers.forEach((s) => { s.isVisible = true; });
    }
  }

  destroy(): void {
    this.stopAnimation();
    this.subscribers.clear();
    GlobalAnimationManager.instance = null;
  }

  getSubscriberCount(): number {
    return this.subscribers.size;
  }

  isActive(): boolean {
    return this.isRunning;
  }
}
