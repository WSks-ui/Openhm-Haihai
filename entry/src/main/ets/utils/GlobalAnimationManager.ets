/**
 * GlobalAnimationManager - 全局动画管理器
 *
 * 解决问题：
 * 1. 多个50ms定时器同时运行浪费CPU和电量
 * 2. 统一管理所有光效动画，使用单一requestAnimationFrame风格的定时器
 * 3. 支持可见性检测，不可见的组件暂停动画更新
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
  private timer: number = -1;
  private globalPhase: number = 0;
  private isRunning: boolean = false;
  private lastUpdateTime: number = 0;

  private constructor() {}

  static getInstance(): GlobalAnimationManager {
    if (!GlobalAnimationManager.instance) {
      GlobalAnimationManager.instance = new GlobalAnimationManager();
    }
    return GlobalAnimationManager.instance;
  }

  /**
   * 订阅动画更新
   * @param id 唯一标识符
   * @param onUpdate 更新回调，接收当前相位值
   * @returns 取消订阅函数
   */
  subscribe(id: string, onUpdate: (phase: number) => void): () => void {
    this.subscribers.set(id, {
      id,
      onUpdate,
      isVisible: true
    });

    // 首次订阅时启动定时器
    if (!this.isRunning) {
      this.startAnimation();
    }

    // 返回取消订阅函数
    return () => this.unsubscribe(id);
  }

  /**
   * 取消订阅
   */
  unsubscribe(id: string): void {
    this.subscribers.delete(id);

    // 没有订阅者时停止定时器
    if (this.subscribers.size === 0) {
      this.stopAnimation();
    }
  }

  /**
   * 更新订阅者可见性状态
   * 不可见的订阅者不会被更新，节省CPU
   */
  setVisible(id: string, isVisible: boolean): void {
    const subscriber = this.subscribers.get(id);
    if (subscriber) {
      subscriber.isVisible = isVisible;
    }
  }

  /**
   * 获取当前相位值（供直接查询使用）
   */
  getPhase(): number {
    return this.globalPhase;
  }

  /**
   * 获取Lissajous曲线位置（常用于光效动画）
   * @param phaseOffset 相位偏移，用于创建不同轨迹
   * @param xAmplitude X轴振幅百分比
   * @param yAmplitude Y轴振幅百分比
   */
  getLissajousPosition(
    phaseOffset: number = 0,
    xAmplitude: number = 30,
    yAmplitude: number = 30
  ): PositionResult {
    const phase = this.globalPhase + phaseOffset;
    const x = 50 + Math.sin(phase) * xAmplitude;
    const y = 50 + Math.cos(phase * 0.8) * yAmplitude;
    const result: PositionResult = {
      x: `${x}%`,
      y: `${y}%`
    };
    return result;
  }

  /**
   * 获取椭圆运动位置（用于LiquidGlass等组件）
   */
  getEllipsePosition(
    phaseOffset: number = 0,
    xAmplitude: number = 20,
    yAmplitude: number = 20
  ): PositionResult {
    const phase = this.globalPhase + phaseOffset;
    const x = 50 + Math.cos(phase) * xAmplitude;
    const y = 50 + Math.sin(phase * 0.7) * yAmplitude;
    const result: PositionResult = {
      x: `${x}%`,
      y: `${y}%`
    };
    return result;
  }

  private startAnimation(): void {
    if (this.isRunning) return;

    this.isRunning = true;
    this.lastUpdateTime = Date.now();

    // 使用50ms间隔，约20fps，适合光效动画
    this.timer = setInterval(() => {
      this.globalPhase += 0.02;
      this.notifySubscribers();
    }, 50);
  }

  private stopAnimation(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    this.isRunning = false;
  }

  private notifySubscribers(): void {
    this.subscribers.forEach((subscriber) => {
      // 只更新可见的订阅者
      if (subscriber.isVisible) {
        try {
          subscriber.onUpdate(this.globalPhase);
        } catch (err) {
          console.warn(`Animation subscriber ${subscriber.id} error:`, err);
        }
      }
    });
  }

  /**
   * 销毁管理器（通常在应用退出时调用）
   */
  destroy(): void {
    this.stopAnimation();
    this.subscribers.clear();
    GlobalAnimationManager.instance = null;
  }

  /**
   * 获取当前订阅者数量（调试用）
   */
  getSubscriberCount(): number {
    return this.subscribers.size;
  }

  /**
   * 检查动画是否正在运行
   */
  isActive(): boolean {
    return this.isRunning;
  }
}
