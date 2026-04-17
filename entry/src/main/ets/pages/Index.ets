// 主页面代码

import { MineSidebar } from '../components/common/MineSidebar';
import { HomeComponent } from '../components/home/HomeComponent';
import { DiscoverComponent } from '../components/discover/DiscoverComponent';
import { MessageComponent } from '../components/message/MessageComponent';
import { MineComponent } from '../components/mine/MineComponent';
import { PublishMenu } from '../components/common/PublishMenu';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { HoldingHandManager, HoldingHandStatus } from '../utils/HoldingHandManager';
import { GlobalAnimationManager } from '../utils/GlobalAnimationManager';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { UserManager } from '../model/UserModel';
import { PreferencesStorage } from '../utils/PreferencesStorage';

/**
 * Index - 应用主页面入口
 *
 * 【设计哲学与HarmonyOS优势】
 * 1. 响应式布局：基于设备类型(phone/tablet)和断点(sm/md/lg/xl)自动切换底部导航与侧边导航，
 *    充分利用HarmonyOS多设备协同能力，一套代码适配手机、平板、折叠屏。
 * 2. 沉浸式适配：通过expandSafeArea系统级API处理刘海屏、状态栏和导航栏遮挡，
 *    无需手动计算安全区域，保证内容在不同设备上正确绘制。
 * 3. 全局状态管理：使用@StorageLink/@StorageProp与AppStorage绑定，实现跨组件高效状态同步，
 *    基于HarmonyOS的分布式数据管理框架，为后续多设备协同打下基础。
 * 4. 性能优化：动态背景采用属性动画而非重绘，降低CPU占用；握持手势监听器单例管理，避免重复创建。
 * 5. 用户体验：根据握持状态自动调整悬浮球位置，体现HarmonyOS对多样化交互场景的支持。
 */

// ============================================================================
// 常量定义
// ============================================================================
const ACTIVE_COLOR = '#7B68EE';       // 选中态颜色 (中型紫色) — 采用品牌主色，提升视觉识别度
const INACTIVE_COLOR = '#999999';     // 未选中图标颜色 — 灰色弱化，符合视觉层级
const INACTIVE_TEXT_COLOR = '#999999'; // 未选中文字颜色 — 保持一致性

interface TabItemConfig {
  index: number;
  title: string;
  icon: string;
}

@Entry
@Component
struct Index {
  // ---------------- 状态变量 ----------------
  @State currentIndex: number = 0;          // 当前选中的 Tab 索引 — 驱动UI变化
  @State private currentTabIndex: number = 0; // Tabs 组件内部索引 — 与currentIndex同步，避免状态不一致

  // Tabs 控制器，用于编程式切换 Tab — HarmonyOS Tabs提供controller属性，实现灵活控制
  private controller: TabsController = new TabsController();

  // ---------------- 全局存储链接 (双向绑定) ----------------
  @StorageLink('isSidebarOpen') isSidebarOpen: boolean = false; // 侧边栏开关 — 通过AppStorage跨组件共享，避免层层传递

  // ---------------- 全局存储属性 (单向读取) ----------------
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'; // 当前响应式断点 — 从BreakpointSystem写入
  @StorageProp('deviceType') deviceType: string = 'phone';          // 设备类型: phone, tablet, wearable — 用于布局决策
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT; // 深色/浅色模式

  @StorageProp('safeAreaTop') safeAreaTop: number = 0;      // 顶部安全区域高度 — 由系统计算，用于精确留白
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0; // 底部安全区域高度

  // ---------------- 工具类实例 ----------------
  private breakpointSystem: BreakpointSystem = BreakpointSystem.getInstance(); // 断点监听系统 — 单例模式
  private holdingHandManager: HoldingHandManager = HoldingHandManager.getInstance(); // 握持手势管理器 — 单例模式，节省资源

  @State private holdingHandStatus: HoldingHandStatus = HoldingHandStatus.UNKNOWN_STATUS; // 当前握持状态 — 用于UI调整
  @StorageLink('showTopicList') showTopicList: boolean = false; // 控制发现页话题列表显示 — 全局状态，便于子组件响应

  // ---------------- 握持手势监听回调（存为成员变量以便正确移除） ----------------
  private handListener = (status: HoldingHandStatus) => {
    this.holdingHandStatus = status;
  };

  // ---------------- 动态背景动画变量 ----------------
  @State lightX: string = '50%'; // 光效中心 X 坐标 — 动态绑定，实现漂浮效果
  @State lightY: string = '50%'; // 光效中心 Y 坐标
  private animationManager: GlobalAnimationManager = GlobalAnimationManager.getInstance();
  private animationUnsubscribe: (() => void) | null = null; // 动画取消订阅函数

  // 底部导航栏配置 — 将UI定义与数据分离，便于维护
  private tabItems: TabItemConfig[] = [
    { index: 0, title: '首页', icon: 'app.media.icon_home' },
    { index: 1, title: '发现', icon: 'app.media.icon_find' },
    { index: 2, title: '好友', icon: 'app.media.icon_news' },
    { index: 3, title: '我的', icon: 'app.media.icon_my_copy' }
  ];

  // ---------------- 登录状态标记（用于提前拦截） ----------------
  @State isAuthChecked: boolean = false; // 认证检查是否完成
  @State isLoggedIn: boolean = false; // 当前登录状态

  // ============================================================================
  // 生命周期方法
  // ============================================================================

  /**
   * 组件创建时调用 — HarmonyOS自定义组件生命周期
   * 设计要点：
   * - 注册系统监听器应在aboutToAppear中进行，确保组件已准备好
   * - 异步操作（如数据存储读取）需放在此处，避免阻塞UI渲染
   * - HarmonyOS的preferences API提供轻量级键值存储，适合保存登录态等少量数据
   */
  async aboutToAppear() {
    // 1. 注册响应式断点监听 — BreakpointSystem内部使用媒体查询，通过AppStorage广播变化
    this.breakpointSystem.register();

    // 2. 启动握持状态监听 — 利用传感器数据，提升大屏单手操作体验
    this.startHoldingHandMonitoring();

    // 3. 订阅全局动画管理器 — 统一管理光效动画，节省CPU和电量
    this.animationUnsubscribe = this.animationManager.subscribe('Index_background', (phase) => {
      const pos = this.animationManager.getLissajousPosition(0, 30, 30);
      this.lightX = pos.x;
      this.lightY = pos.y;
    });

    // 4. 检查开发者模式标记（同步获取，避免延迟）
    const isDevMode = AppStorage.get('devModeSession') === true;

    // 5. 登录态校验与用户数据初始化 — 使用preferences和自定义存储类
    const ctx = getContext(this);

    if (isDevMode) {
      // 开发者模式：初始化但不加载用户数据
      this.isAuthChecked = true;
      this.isLoggedIn = true;
      const prefsStorage = PreferencesStorage.getInstance();
      await prefsStorage.init(ctx);
      return;
    }

    try {
      const store = await preferences.getPreferences(ctx, 'users');
      const loggedIn = await store.get('isLoggedIn', false) as boolean;

      if (!loggedIn) {
        // 未登录则强制跳转至登录页，替换当前栈 — 防止用户通过返回键回到未授权页面
        // 注意：先跳转再设置状态，确保在导航完成前一直显示加载页面
        router.replaceUrl({ url: 'pages/LoginPage' }).then(() => {
          this.isLoggedIn = false;
          this.isAuthChecked = true;
        });
        return;
      }

      // 已登录则初始化数据存储服务 — PreferencesStorage封装了preferences操作，支持多用户
      const prefsStorage = PreferencesStorage.getInstance();
      const userManager = UserManager.getInstance();
      await prefsStorage.init(ctx);
      await userManager.init(ctx);

      // 获取当前用户手机号并拉取详细信息 — 用于全局展示
      const userPhone = await prefsStorage.getCurrentUserPhone();
      if (userPhone) {
        const user = await userManager.getUserByPhone(userPhone);
        if (user) {
          // 将用户信息写入AppStorage，供全局组件使用 — 利用AppStorage实现跨页面数据共享
          // HarmonyOS的AppStorage支持分布式同步，为未来多设备协同铺路
          AppStorage.setOrCreate('userName', user.nickname);
          AppStorage.setOrCreate('userAvatar', user.avatar || 'ID_Wa/20260308215703.jpg');
          AppStorage.setOrCreate('userUid', user.uid);
          AppStorage.setOrCreate('userBio', user.bio || '记录生活，发现美好');
          AppStorage.setOrCreate('userGender', user.gender || '保密');
          AppStorage.setOrCreate('userBirthday', user.birthday || '2000-01-01');
          AppStorage.setOrCreate('userPhone', user.phoneNumber);
          AppStorage.setOrCreate('userLevel', user.level || 1);
        }
      }

      // 所有初始化和数据加载完成后才标记认证检查完成
      this.isLoggedIn = true;
      this.isAuthChecked = true;
    } catch (error) {
      // 出错时视为未登录，跳转到登录页
      // 注意：先跳转再设置状态，确保在导航完成前一直显示加载页面
      console.error('登录状态检查失败：' + JSON.stringify(error));
      router.replaceUrl({ url: 'pages/LoginPage' }).then(() => {
        this.isAuthChecked = true;
        this.isLoggedIn = false;
      });
    }
  }

  /**
   * 组件销毁时调用 — 清理资源，防止内存泄漏
   * HarmonyOS组件销毁时会自动释放大部分资源，但手动注册的监听器和定时器需显式清除
   */
  aboutToDisappear() {
    this.breakpointSystem.unregister();   // 注销断点监听
    this.stopHoldingHandMonitoring();     // 停止握持监听
    if (this.animationUnsubscribe) {      // 取消动画订阅
      this.animationUnsubscribe();
      this.animationUnsubscribe = null;
    }
  }

  // ============================================================================
  // 私有辅助方法
  // ============================================================================

  private startHoldingHandMonitoring(): void {
    this.holdingHandManager.addListener(this.handListener);
    this.holdingHandManager.startMonitoring();
  }

  private stopHoldingHandMonitoring(): void {
    this.holdingHandManager.removeListener(this.handListener);
  }

  /**
   * 悬浮球点击事件处理
   * 逻辑分支体现了响应式设计：平板横屏下发现页点击切换话题列表，其他场景展示握持状态
   * HarmonyOS的promptAction提供轻量级提示，不影响用户操作
   */
  private onFloatingBallClick(): void {
    if (this.currentIndex === 1 && this.currentBreakpoint === 'md') {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.showTopicList = !this.showTopicList;
      });
    } else {
      promptAction.showToast({
        message: `当前握持状态：${this.holdingHandStatus}`,
        duration: 2000,
        bottom: 200
      });
    }
  }

  // ============================================================================
  // 发布功能相关
  // ============================================================================

  // 自定义对话框控制器：用于点击 "+" 号时弹出发布菜单
  // HarmonyOS CustomDialogController支持自定义布局和对齐方式，此处采用底部对齐并启用外部取消
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PublishMenu({
      action: (type: string): void => this.handlePublish(type)
    }),
    alignment: DialogAlignment.Bottom, // 底部对齐，符合单手操作习惯
    customStyle: true,                 // 使用自定义样式，可完全控制弹窗外观
    autoCancel: true                   // 点击外部自动取消，提升用户体验
  });

  @State buttonScale: number = 1;      // 中间发布按钮的缩放比例 — 用于入场动画
  @State isFirstShow: boolean = true;  // 标记是否为首次显示页面 — 用于执行一次性动画

  /**
   * 页面显示时调用 (每次切回该页面都会触发) — HarmonyOS页面生命周期
   * 设计要点：
   * - 处理折叠屏/平板布局重建后的Tab状态同步
   * - 发送全局刷新信号，通知子组件重新加载数据（基于时间戳机制）
   * - 播放首次进入动画，增强欢迎感
   */
  onPageShow(): void {
    // 折叠屏/平板特殊处理：非首次显示且设备为平板时，强制同步 Tabs 索引
    // 原因：折叠屏展开/收起时可能会重新创建Tabs组件，导致内部索引重置，需手动恢复
    if (!this.isFirstShow && this.deviceType === 'tablet') {
      this.controller.changeIndex(this.currentIndex);
    }

    // 触发全局刷新信号：利用时间戳让子组件通过@StorageProp监听到变化后重新获取数据
    // HarmonyOS的@StorageProp支持精确更新，只有依赖该属性的组件会刷新，性能高效
    const currentTimestamp = Date.now();
    AppStorage.setOrCreate('refreshHomeData', currentTimestamp);
    AppStorage.setOrCreate('refreshMineData', currentTimestamp);
    AppStorage.setOrCreate('refreshMessageData', currentTimestamp);

    // 中间发布按钮的入场动画 (仅首次执行)
    if (this.isFirstShow) {
      this.isFirstShow = false;
      animateTo({
        duration: 500,
        curve: Curve.EaseInOut,
        iterations: 2,           // 播放 2 次 — 呼吸效果
        playMode: PlayMode.Alternate, // 交替播放 (放大->缩小->放大->缩小)
        onFinish: () => {
          this.buttonScale = 1;  // 动画结束后复位
        }
      }, () => {
        this.buttonScale = 1.1;  // 放大到 1.1 倍
      })
    }
  }

  handlePublish(type: string): void {
    if (type === 'text') {
      // 跳转到图文发布页 — 使用router.pushUrl，保留当前页面栈，便于返回
      router.pushUrl({
        url: 'pages/CreatePostPage'
      });
    } else {
      // 其他类型暂不支持 — 友好提示
      promptAction.showToast({
        message: '功能开发中，敬请期待...',
        duration: 2000,
        bottom: 400
      });
    }
  }

  // ============================================================================
  // UI 构建 (build)
  // ============================================================================

  build() {
    Stack({ alignContent: Alignment.Start }) {
      if (!this.isAuthChecked) {
        this.LoadingView()
      } else {
        this.MainPageContent()
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  LoadingView() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A1E')

      Column({ space: 16 }) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color('#7B68EE')

        Text('加载中...')
          .fontSize(16)
          .fontColor('#A0A0A0')
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  MainPageContent() {
    Stack({ alignContent: Alignment.Start }) {
      // --- 第 1 层：纯色背景 (根据深色/浅色模式切换) ---
      // 使用Column作为底层，通过backgroundColor响应模式变化
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')

      // --- 第 2 层：动态径向渐变光效 (非消息页显示) ---
      // 消息页（索引2）取消光效，避免干扰阅读体验
      if (this.currentIndex !== 2) {
        Column()
          .width('100%')
          .height('100%')
          .radialGradient({
            center: [this.lightX, this.lightY], // 动态绑定的光效中心，实现漂浮感
            radius: '150%',
            colors: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? [
              // 深色模式渐变 — 低饱和度，避免刺眼
              ['rgba(123, 104, 238, 0.4)', 0.0],
              ['rgba(72, 61, 139, 0.2)', 0.4],
              ['rgba(0, 0, 0, 1.0)', 1.0]
            ] : [
              // 浅色模式渐变 — 柔和多彩，提升活力
              ['rgba(123, 104, 238, 0.3)', 0.0],
              ['rgba(255, 182, 193, 0.3)', 0.3],
              ['rgba(173, 216, 230, 0.2)', 0.6],
              ['rgba(255, 255, 255, 1.0)', 1.0]
            ]
          })
          // HarmonyOS属性动画：直接对radialGradient参数应用animation，系统会自动插值
          .animation({
            duration: 1000,
            curve: Curve.Linear
          })
          // 切换页面时淡入淡出 — 使用TransitionEffect，由系统接管动画，性能优于手动控制
          .transition(TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut }))
      }

      // --- 第 3 层：主内容区域 (响应式布局核心) ---
      // 通过断点判断使用平板模式（侧边导航+内容）还是手机模式（内容+底部导航）
      if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
        // 【平板/大屏模式】：侧边导航 + 内容区域 (左右结构)
        Row() {
          this.SideNavigation()   // 左侧导航栏
          this.MainContent(true)  // 右侧内容区 (isSideBar=true)
        }
        .width('100%')
        .height('100%')
      } else {
        // 【手机/小屏模式】：内容区域 + 底部导航 (上下结构)
        Stack({ alignContent: Alignment.Bottom }) {
          // 主要内容区
          this.MainContent(false)

          // 自定义底部导航栏 (悬浮于内容之上)
          // 采用Stack叠加，使导航栏始终可见，且可添加毛玻璃效果
          Stack({ alignContent: Alignment.Top }) {
            // 导航栏背景：磨砂玻璃效果 — backdropBlur是HarmonyOS特有属性，性能优异且视觉效果佳
            Row() {
              ForEach(this.tabItems, (item: TabItemConfig) => {
                if (item.index === 2) {
                  // 索引 2 的位置留空，预留给中间的浮动发布按钮
                  Column()
                    .width('20%')
                    .height('100%')
                }
                // 渲染普通 Tab 项
                this.CommonTabItem(item.index, item.title, item.icon, false)
              })
            }
            .width('100%')
            .height(60)
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(28, 28, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)')
            .backdropBlur(20) // 毛玻璃模糊半径 — 使用系统级实时模糊，性能优化
            .border({
              width: { top: 0.5 },
              color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)'
            })
            .margin({ top: 30 }) // 距离底部一定距离，形成悬浮感 — 视觉层次分明

            // 中间浮动发布按钮 (+)
            Column() {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                // SymbolGlyph使用系统符号，支持动态着色和深色模式自动适配 — HarmonyOS特有
                SymbolGlyph($r('sys.symbol.plus'))
                  .fontSize(30)
                  .fontColor([Color.White])
                  .fontWeight(FontWeight.Bold)
              }
              .width(56)
              .height(56)
              .backgroundColor(ACTIVE_COLOR)
              .shadow({
                radius: 12,
                color: 'rgba(123, 104, 238, 0.4)',
                offsetY: 6
              })
              .onClick(() => {
                this.dialogController.open(); // 打开发布菜单弹窗
              })
              .scale({ x: this.buttonScale, y: this.buttonScale }) // 绑定入场动画
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .touchable(true)
          }
          .width('100%')
          .height(90)
          // 【关键】扩展安全区域到底部，确保在全面屏设备上不被导航条遮挡
          // expandSafeArea是HarmonyOS提供的系统级API，自动适配挖孔屏、刘海屏和手势导航条
          // 相较于手动计算，此方式更简洁且适配未来新设备
          .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.BOTTOM])
          .zIndex(100)
        }
        .width('100%')
        .height('100%')
      }

      // --- 第 4 层：侧边栏遮罩 (半透明黑色背景) ---
      // 点击遮罩关闭侧边栏，符合主流交互模式
      if (this.isSidebarOpen) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000') // 50% 透明度黑色
          .onClick(() => {
            // 点击遮罩关闭侧边栏，带动画 — 使用animateTo实现平滑过渡
            animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
              this.isSidebarOpen = false;
            })
          })
          .transition(TransitionEffect.OPACITY) // 淡入淡出效果
          .zIndex(299)
      }

      // --- 第 5 层：侧边栏内容 (MineSidebar) ---
      if (this.isSidebarOpen) {
        Column() {
          MineSidebar()
        }
        // 宽度自适应：手机端 80%，其他 300vp — 兼顾小屏和大屏的可读性
        .width(this.currentBreakpoint === 'sm' || this.deviceType === 'wearable' ? '80%' : '300vp')
        .height('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
        // 从左侧滑入的过渡效果 — TransitionEffect.move由系统实现高性能侧滑动画
        .transition(TransitionEffect.move(TransitionEdge.START))
        .zIndex(300)
      }

      // --- 第 6 层：握持手势浮动面板 (根据握持状态改变位置) ---
      this.FloatingPanel()
    }
    .width('100%')
    .height('100%')
  }

  // ============================================================================
  // @Builder 自定义构建函数
  // ============================================================================

  /**
   * 握持手势浮动面板
   * 功能：根据左手/右手握持状态，自动切换屏幕左右侧位置
   * HarmonyOS传感器能力结合UI响应，体现智能交互
   */
  @Builder
  FloatingPanel() {
    Column({ space: 12 }) {
      Button({ type: ButtonType.Circle }) {
        // 根据当前页面和断点动态切换图标 — 发现页+平板显示列表图标，其余显示手型图标
        if (this.currentIndex === 1 && this.currentBreakpoint === 'md') {
          SymbolGlyph($r('sys.symbol.list_bullet')) // 列表图标
            .fontSize(20)
            .fontColor([Color.White])
        } else {
          SymbolGlyph($r('sys.symbol.hand_draw')) // 握持图标
            .fontSize(20)
            .fontColor([Color.White])
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(this.currentIndex === 1 && this.currentBreakpoint === 'md' ? ACTIVE_COLOR : ACTIVE_COLOR)
      .onClick(() => {
        this.onFloatingBallClick();
      })
    }
    .padding(8)
    .borderRadius(36)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
    .shadow({ radius: 16, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0, 0, 0, 0.5)' : 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    // 动态位置：左手握持在左侧 (16vp)，否则在右侧 — 提升单手可达性
    .position({
      x: this.holdingHandStatus === HoldingHandStatus.LEFT_HAND_HELD ? 16 : 'calc(100% - 72vp)',
      y: '75%'
    })
    // HarmonyOS属性动画：对position变化应用缓动曲线，实现平滑移动
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
    .zIndex(400)
  }

  /**
   * 主内容区域构建器
   * @param isSideBar 是否为侧边栏模式 (影响 Tabs 的方向和样式)
   *
   * Tabs组件是HarmonyOS容器，支持水平和垂直布局，且内置切换动画。
   * 我们隐藏默认tabBar，完全自定义导航UI，但保留Tabs的页面切换能力。
   */
  @Builder
  MainContent(isSideBar: boolean) {
    Tabs({
      barPosition: isSideBar ? BarPosition.Start : BarPosition.End, // 侧边模式 Tab 栏在左侧，否则在底部
      controller: this.controller,
      index: this.currentTabIndex
    }) {
      ForEach([0, 1, 2, 3], (index: number) => {
        TabContent() {
          // 根据索引渲染不同的页面组件 — 每个页面独立，通过AppStorage共享数据
          if (index === 0) {
            HomeComponent()
          } else if (index === 1) {
            DiscoverComponent()
          } else if (index === 2) {
            MessageComponent()
          } else if (index === 3) {
            MineComponent()
          }
        }
        .tabBar(null) // 隐藏 Tabs 默认的选项卡栏，使用自定义的导航 UI
      })
    }
    .vertical(isSideBar) // 侧边模式下垂直排列 — 平板模式下导航在左侧，内容在右侧
    .barWidth(isSideBar ? 0 : undefined)   // 隐藏默认栏宽
    .barHeight(!isSideBar ? 0 : undefined) // 隐藏默认栏高
    .scrollable(false) // 禁止手指滑动切换 Tab，强制点击切换 — 避免与页面内滑动冲突
    .animationDuration(300) // 切换动画时长
    .onChange((index: number) => {
      // Tab 切换回调
      this.currentIndex = index;
      this.currentTabIndex = index;
      // 切出"发现"页时，自动隐藏话题列表 — 保持界面整洁
      if (index !== 1) {
        this.showTopicList = false;
      }
    })
    .layoutWeight(isSideBar ? 1 : 0) // 侧边模式下占据剩余空间 — Row布局中权重分配
    .width('100%')
    .height('100%')
    .padding({ bottom: 0 })
  }

  /**
   * 通用 Tab 选项卡项构建器
   * @param index 索引
   * @param title 标题
   * @param icon 图标资源
   * @param isVertical 是否为垂直布局 (侧边栏用)
   *
   * 使用Image的fillColor动态着色，配合选中态放大效果和弹簧动画，提升交互反馈。
   * curves.springMotion()是HarmonyOS提供的高质量物理动画曲线，模拟真实弹簧效果。
   */
  @Builder
  CommonTabItem(index: number, title: string, icon: string, isVertical: boolean = false) {
    Column() {
      Image($r(icon))
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? ACTIVE_COLOR : INACTIVE_COLOR)
        // 选中态放大效果 + 弹簧动画
        .scale({ x: this.currentIndex === index ? 1.2 : 1.0, y: this.currentIndex === index ? 1.2 : 1.0 })
        .animation({ duration: 300, curve: curves.springMotion() }) // springMotion提供过冲效果，更生动
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? ACTIVE_COLOR : INACTIVE_TEXT_COLOR)
        .margin({ top: 4 })
        .animation({ duration: 300 })
    }
    .width(isVertical ? '100%' : '20%') // 垂直布局占满宽，水平布局占 20%
    .height(isVertical ? 80 : '100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击切换 Tab — 更新状态并通知Tabs控制器
      this.currentIndex = index;
      this.controller.changeIndex(index);
    })
  }

  /**
   * 侧边导航栏构建器 (平板/大屏专用)
   * 包含顶部安全区域留白、发布按钮和普通导航项
   * expandSafeArea在此处实现沉浸式侧边栏，使背景延伸至状态栏，内容不重叠
   */
  @Builder
  SideNavigation() {
    Column() {
      // 顶部安全区域留白 (避开状态栏，防止内容被遮挡)
      // 使用从AppStorage获取的safeAreaTop，而非固定数值，确保适配所有设备
      Column().height(this.safeAreaTop)

      // 主导航选项列表
      ForEach(this.tabItems, (item: TabItemConfig) => {
        if (item.index === 2) {
          // 索引 2 替换为发布按钮 — 将发布功能放在侧边栏，突出核心操作
          Column() {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Text('+')
                .fontSize(30)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width(50)
            .height(50)
            .backgroundColor(ACTIVE_COLOR)
            .onClick(() => {
              this.dialogController.open();
            })
          }
          .margin({ top: 20, bottom: 20 })
        }
        // 渲染普通 Tab 项 (垂直模式)
        this.CommonTabItem(item.index, item.title, item.icon, true)
      })
    }
    .width(80)
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
    .shadow({ radius: 10, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0, 0, 0, 0.5)' : '#1A000000', offsetX: 2 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .padding({ top: 20 })
    // 【关键】扩展到顶部安全区域，实现沉浸式侧边栏
    // HarmonyOS的expandSafeArea确保背景填满，同时内容区域自动避开状态栏（通过上方留白）
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP])
    .zIndex(200)
  }
}