import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

export enum HoldingHandStatus {
  NOT_HELD = 0,
  LEFT_HAND_HELD = 1,
  RIGHT_HAND_HELD = 2,
  BOTH_HANDS_HELD = 3,
  UNKNOWN_STATUS = 16
}

export class HoldingHandManager {
  private static instance: HoldingHandManager | null = null;
  private isMonitoring: boolean = false;
  private currentStatus: HoldingHandStatus = HoldingHandStatus.UNKNOWN_STATUS;
  private listeners: Array<(status: HoldingHandStatus) => void> = [];

  private constructor() {}

  static getInstance(): HoldingHandManager {
    if (!HoldingHandManager.instance) {
      HoldingHandManager.instance = new HoldingHandManager();
    }
    return HoldingHandManager.instance;
  }

  startMonitoring(): void {
    if (this.isMonitoring) {
      console.info('握持手状态监听已在运行中');
      return;
    }

    try {
      motion.on('holdingHandChanged', (data: number) => {
        const status = data as HoldingHandStatus;
        console.info(`握持手状态变化: ${status}`);

        if (this.currentStatus !== status) {
          this.currentStatus = status;
          this.notifyListeners(status);
        }

        this.logStatus(status);
      });
      this.isMonitoring = true;
      console.info('握持手状态监听已启用');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`启动监听失败: ${error.code}, ${error.message}`);
    }
  }

  stopMonitoring(): void {
    if (!this.isMonitoring) {
      return;
    }

    try {
      motion.off('holdingHandChanged');
      this.isMonitoring = false;
      console.info('已停止握持手状态监听');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`停止监听失败: ${error.code}, ${error.message}`);
    }
  }

  getCurrentStatus(): HoldingHandStatus {
    return this.currentStatus;
  }

  isCurrentlyMonitoring(): boolean {
    return this.isMonitoring;
  }

  addListener(callback: (status: HoldingHandStatus) => void): void {
    this.listeners.push(callback);
  }

  removeListener(callback: (status: HoldingHandStatus) => void): void {
    const index = this.listeners.indexOf(callback);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(status: HoldingHandStatus): void {
    this.listeners.forEach(callback => {
      try {
        callback(status);
      } catch (err) {
        console.error(`监听器回调执行失败: ${err}`);
      }
    });
  }

  private logStatus(status: HoldingHandStatus): void {
    switch (status) {
      case HoldingHandStatus.LEFT_HAND_HELD:
        console.info('左手握持');
        break;
      case HoldingHandStatus.RIGHT_HAND_HELD:
        console.info('右手握持');
        break;
      case HoldingHandStatus.BOTH_HANDS_HELD:
        console.info('双手握持');
        break;
      case HoldingHandStatus.NOT_HELD:
        console.info('未握持');
        break;
      default:
        break;
    }
  }

  destroy(): void {
    this.stopMonitoring();
    this.listeners = [];
    HoldingHandManager.instance = null;
  }
}
