import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import { PreferencesStorage } from '../utils/PreferencesStorage';

const DOMAIN = 0x0000;

/**
 * EntryAbility - 应用入口能力类
 * 
 * 沉浸式效果实现说明：
 * 1. setWindowLayoutFullScreen(true): 设置窗口全屏布局，内容延伸到状态栏和导航栏区域
 * 2. 获取安全区域(AvoidArea)并存储到AppStorage，供全局组件使用
 * 3. 监听系统栏变化，动态更新安全区域信息
 * 4. 完全隐藏状态栏和系统导航条，实现真正的全屏沉浸式体验
 * 
 * 系统栏隐藏说明：
 * - setWindowSystemBarEnable([]): 禁用所有系统栏（状态栏+导航栏）
 * - 用户可通过从屏幕边缘滑动临时显示系统栏
 * 
 * 参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-develop-apply-immersive-effects
 */
export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | null = null;
  // 系统栏是否可见（用于控制临时显示）
  private systemBarsVisible: boolean = false;

  private isTabletDevice(): boolean {
    const type = deviceInfo.deviceType;
    return type === 'tablet' || type === '2in1';
  }

  /**
   * 设置沉浸式效果 - 核心方法
   * 实现步骤：
   * 1. 设置窗口全屏布局模式
   * 2. 完全隐藏状态栏和导航栏
   * 3. 获取并存储安全区域信息
   * 4. 监听系统栏状态变化
   */
  private async setupImmersiveMode(windowStage: window.WindowStage): Promise<void> {
    try {
      this.mainWindow = await windowStage.getMainWindow();
      if (this.mainWindow) {
        // 步骤1: 设置全屏布局，使内容延伸到状态栏和导航栏区域
        await this.mainWindow.setWindowLayoutFullScreen(true);
        hilog.info(DOMAIN, 'testTag', 'Immersive mode enabled: setWindowLayoutFullScreen(true)');

        // 步骤2: 完全隐藏状态栏和系统导航栏
        // 传入空数组表示禁用所有系统栏
        await this.hideSystemBars();
        hilog.info(DOMAIN, 'testTag', 'System bars hidden: status bar and navigation bar disabled');

        // 步骤3: 获取安全区域并存储到全局状态
        await this.updateSafeAreaInsets();

        // 步骤4: 监听系统栏变化（状态栏显示/隐藏、旋转等）
        this.mainWindow.on('avoidAreaChange', (data) => {
          hilog.info(DOMAIN, 'testTag', 'Avoid area changed, type: %{public}d', data.type);
          this.updateSafeAreaInsets();
        });

        // 监听窗口尺寸变化（设备旋转、分屏等场景）
        this.mainWindow.on('windowSizeChange', () => {
          this.updateSafeAreaInsets();
        });

        // 存储系统栏控制方法到全局，供页面调用
        AppStorage.setOrCreate('toggleSystemBars', () => this.toggleSystemBars());
        AppStorage.setOrCreate('hideSystemBars', () => this.hideSystemBars());
        AppStorage.setOrCreate('showSystemBars', () => this.showSystemBars());
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to setup immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 隐藏系统栏（状态栏 + 导航栏）
   * 使用空数组参数完全禁用所有系统栏
   */
  private async hideSystemBars(): Promise<void> {
    if (!this.mainWindow) return;
    
    try {
      // 完全隐藏状态栏和导航栏
      await this.mainWindow.setWindowSystemBarEnable([]);
      this.systemBarsVisible = false;
      AppStorage.setOrCreate('systemBarsVisible', false);
      hilog.info(DOMAIN, 'testTag', 'System bars hidden successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to hide system bars. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 显示系统栏（状态栏 + 导航栏）
   * 可用于需要临时显示系统UI的场景
   */
  private async showSystemBars(): Promise<void> {
    if (!this.mainWindow) return;
    
    try {
      // 显示状态栏和导航栏
      await this.mainWindow.setWindowSystemBarEnable(['status', 'navigation']);
      this.systemBarsVisible = true;
      AppStorage.setOrCreate('systemBarsVisible', true);
      hilog.info(DOMAIN, 'testTag', 'System bars shown successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to show system bars. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 切换系统栏显示/隐藏状态
   * 可用于用户交互控制
   */
  private async toggleSystemBars(): Promise<void> {
    if (this.systemBarsVisible) {
      await this.hideSystemBars();
    } else {
      await this.showSystemBars();
    }
  }

  /**
   * 更新安全区域信息到全局存储
   * 安全区域包括：状态栏高度、导航栏高度、刘海屏区域等
   * 组件通过 @StorageProp 获取这些值来调整布局
   */
  private async updateSafeAreaInsets(): Promise<void> {
    if (!this.mainWindow) return;

    try {
      // 获取系统类型的安全区域（状态栏、导航栏）
      const systemAvoidArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      // 获取刘海屏/挖孔屏的安全区域
      const cutoutAvoidArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);

      // 顶部安全区域高度（状态栏 + 刘海屏）
      const safeAreaTop = Math.max(
        px2vp(systemAvoidArea.topRect.height),
        px2vp(cutoutAvoidArea.topRect.height)
      );

      // 底部安全区域高度（导航栏/手势条）
      const safeAreaBottom = px2vp(systemAvoidArea.bottomRect.height);

      // 存储到全局状态，供所有页面使用
      AppStorage.setOrCreate('safeAreaTop', safeAreaTop);
      AppStorage.setOrCreate('safeAreaBottom', safeAreaBottom);

      hilog.info(DOMAIN, 'testTag', 'Safe area updated - Top: %{public}f, Bottom: %{public}f', safeAreaTop, safeAreaBottom);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to update safe area. Cause: %{public}s', JSON.stringify(err));
      // 设置默认值，确保UI不会崩溃
      AppStorage.setOrCreate('safeAreaTop', 36);
      AppStorage.setOrCreate('safeAreaBottom', 28);
    }
  }

  private async setLandscapeOrientation(windowStage: window.WindowStage): Promise<void> {
    try {
      const mainWindow = await windowStage.getMainWindow();
      if (mainWindow) {
        await mainWindow.setPreferredOrientation(window.Orientation.LANDSCAPE);
        await mainWindow.setLayoutFullScreen(true);
        mainWindow.on('freeWindowModeChange', async () => {
          if (this.isTabletDevice()) {
            await mainWindow.setPreferredOrientation(window.Orientation.LANDSCAPE);
          }
        });
        hilog.info(DOMAIN, 'testTag', 'Landscape orientation locked successfully for tablet');
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set landscape orientation. Cause: %{public}s', JSON.stringify(err));
    }
  }

  private async getInitialBreakpoint(windowStage: window.WindowStage): Promise<string> {
    try {
      const mainWindow = await windowStage.getMainWindow();
      if (mainWindow) {
        const properties = mainWindow.getWindowProperties();
        const windowWidth = properties.windowRect.width;
        if (windowWidth >= 1200) {
          return 'xl';
        } else if (windowWidth >= 840) {
          return 'lg';
        } else if (windowWidth >= 600) {
          return 'md';
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to get window size. Cause: %{public}s', JSON.stringify(err));
    }
    return 'sm';
  }

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    AppStorage.setOrCreate('deviceType', deviceInfo.deviceType);
    AppStorage.setOrCreate('isSidebarOpen', false);
    
    // 初始化 PreferencesStorage
    const prefsStorage = PreferencesStorage.getInstance();
    await prefsStorage.init(this.context);
    
    // 尝试从持久化存储读取颜色模式，默认使用系统设置
    const savedColorMode = await prefsStorage.getColorMode(-1);
    let initialColorMode: number;
    
    if (savedColorMode === -1) {
      // 没有保存的设置，使用系统默认
      initialColorMode = this.context.config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      hilog.info(DOMAIN, 'testTag', 'No saved color mode, using system default: %{public}d', initialColorMode);
    } else {
      // 使用保存的设置
      initialColorMode = savedColorMode;
      hilog.info(DOMAIN, 'testTag', 'Using saved color mode: %{public}d', initialColorMode);
    }
    
    AppStorage.setOrCreate('currentColorMode', initialColorMode);
    
    // 初始化灰色模式
    const savedGrayscaleMode = await prefsStorage.getGrayscaleMode(false);
    AppStorage.setOrCreate('currentGrayscaleMode', savedGrayscaleMode);
    hilog.info(DOMAIN, 'testTag', 'Grayscale mode initialized: %{public}s', savedGrayscaleMode);
    
    // 设置应用的颜色模式
    try {
      if (initialColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      } else {
        this.context.getApplicationContext().setColorMode(initialColorMode);
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    
    // 初始化系统栏可见状态
    AppStorage.setOrCreate('systemBarsVisible', false);
    
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  async onConfigurationUpdate(newConfig: Configuration): Promise<void> {
    // 只有在用户选择跟随系统时才响应系统配置变化
    const prefsStorage = PreferencesStorage.getInstance();
    const savedColorMode = await prefsStorage.getColorMode(-1);
    
    if (savedColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET || savedColorMode === -1) {
      // 用户选择跟随系统或没有保存设置，跟随系统变化
      AppStorage.setOrCreate('currentColorMode', newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      hilog.info(DOMAIN, 'testTag', 'onConfigurationUpdate, following system colorMode: %{public}d', newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } else {
      // 用户选择了固定模式，不跟随系统变化
      hilog.info(DOMAIN, 'testTag', 'onConfigurationUpdate, ignoring system change, using saved mode: %{public}d', savedColorMode);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    if (this.isTabletDevice()) {
      windowStage.loadContent('pages/Index', async (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the content.');
        const breakpoint = await this.getInitialBreakpoint(windowStage);
        AppStorage.setOrCreate('currentBreakpoint', breakpoint);
        // 设置沉浸式效果
        await this.setupImmersiveMode(windowStage);
        await this.setLandscapeOrientation(windowStage);
      });
    } else {
      windowStage.loadContent('pages/Index', async (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the content.');
        const breakpoint = await this.getInitialBreakpoint(windowStage);
        AppStorage.setOrCreate('currentBreakpoint', breakpoint);
        // 设置沉浸式效果
        await this.setupImmersiveMode(windowStage);
      });
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    
    // 确保应用回到前台时系统栏保持隐藏
    if (this.mainWindow && !this.systemBarsVisible) {
      this.hideSystemBars();
    }
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}