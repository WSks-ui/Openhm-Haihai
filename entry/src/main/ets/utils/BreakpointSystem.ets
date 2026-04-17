// 短点系统 - 单例模式
import mediaQuery from '@ohos.mediaquery';

export class BreakpointSystem {
  private static instance: BreakpointSystem | null = null;
  private isRegistered: boolean = false;

  private smListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(320vp<=width<600vp)');
  private mdListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(600vp<=width<840vp)');
  private lgListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(840vp<=width<1200vp)');
  private xlListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(1200vp<=width)');

  private constructor() {}

  static getInstance(): BreakpointSystem {
    if (!BreakpointSystem.instance) {
      BreakpointSystem.instance = new BreakpointSystem();
    }
    return BreakpointSystem.instance;
  }

  public register() {
    // 防止重复注册
    if (this.isRegistered) {
      return;
    }
    this.isRegistered = true;

    this.smListener.on('change', this.isBreakpointSM);
    this.mdListener.on('change', this.isBreakpointMD);
    this.lgListener.on('change', this.isBreakpointLG);
    this.xlListener.on('change', this.isBreakpointXL);

    if (this.smListener.matches) {
      this.updateCurrentBreakpoint('sm');
    } else if (this.mdListener.matches) {
      this.updateCurrentBreakpoint('md');
    } else if (this.lgListener.matches) {
      this.updateCurrentBreakpoint('lg');
    } else if (this.xlListener.matches) {
      this.updateCurrentBreakpoint('xl');
    }
  }

  private updateCurrentBreakpoint(breakpoint: string) {
    AppStorage.SetOrCreate('currentBreakpoint', breakpoint);
  }

  public unregister() {
    // 只有真正注册过才注销
    if (!this.isRegistered) {
      return;
    }
    this.isRegistered = false;

    this.smListener.off('change', this.isBreakpointSM);
    this.mdListener.off('change', this.isBreakpointMD);
    this.lgListener.off('change', this.isBreakpointLG);
    this.xlListener.off('change', this.isBreakpointXL);
  }

  private isBreakpointSM = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint('sm');
    }
  }

  private isBreakpointMD = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint('md');
    }
  }

  private isBreakpointLG = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint('lg');
    }
  }

  private isBreakpointXL = (mediaQueryResult: mediaQuery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint('xl');
    }
  }

  /**
   * 检查是否已注册
   */
  public isRegisteredState(): boolean {
    return this.isRegistered;
  }
}
