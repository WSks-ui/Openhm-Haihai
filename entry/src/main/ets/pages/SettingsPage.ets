import { ConfigurationConstant } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import preferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import { StorageCleanPanel } from '../components/mine/StorageCleanPanel';
import { DarkModeSettingsPanel } from '../components/mine/DarkModeSettingsPanel';
import { AccountSettingsPanel } from '../components/message/AccountSettingsPanel';
import { PreferencesStorage } from '../utils/PreferencesStorage';
import { SubPageType, SettingItem, getSubPageTitle } from '../types/SettingsTypes';
import { EditProfilePanel } from '../components/settings/EditProfilePanel';
import { PrivacySettingsPanel } from '../components/settings/PrivacySettingsPanel';
import { LiquidGlassSettingsPanel } from '../components/settings/LiquidGlassSettingsPanel';
import { OfflineSettingsPanel, PushSettingsPanel, MessageSettingsPanel } from '../components/settings/NotificationPanels';
import { ChangePasswordPanel, ChangePhonePanel, RealNameAuthPanel, AddEmailPanel, SecurityQuestionPanel } from '../components/settings/SecurityPanels';

@Entry
@Component
struct SettingsPage {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('glassOpacity') glassOpacity: number = 0.4;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State currentSubPage: SubPageType = 'none';
  @State isAnimating: boolean = false;
  @State showSubPage: boolean = false;
  @State animationPhase: 'idle' | 'entering' | 'entered' | 'exiting' = 'idle';
  @State contentOpacity: number = 0;
  @State contentScale: number = 0.92;
  @State contentTranslateX: string = '0';
  @State mainContentOpacity: number = 1;
  @State mainContentTranslateX: string = '0';
  @State mainContentScale: number = 1;

  private readonly ANIMATION_DURATION: number = 250;
  private readonly ENTER_DELAY: number = 10;
  private readonly EXIT_COMPLETE_DELAY: number = 50;

  aboutToAppear() {
  }

  private isLargeScreen(): boolean {
    return this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl';
  }

  private isMediumScreen(): boolean {
    return this.currentBreakpoint === 'md';
  }

  private isSmallScreen(): boolean {
    return this.currentBreakpoint === 'sm';
  }

  private navigateToSubPage(subPage: SubPageType): void {
    if (subPage === 'none' || this.isAnimating || this.animationPhase === 'entering') {
      return;
    }
    this.isAnimating = true;
    this.animationPhase = 'entering';
    this.currentSubPage = subPage;
    this.contentOpacity = 0;
    this.contentScale = this.isSmallScreen() ? 0.95 : 0.9;
    this.contentTranslateX = this.isSmallScreen() ? '100%' : '5%';
    this.mainContentOpacity = 0.7;
    this.mainContentTranslateX = this.isSmallScreen() ? '-2%' : '0%';

    setTimeout(() => {
      this.contentOpacity = 1;
      this.contentScale = 1;
      this.contentTranslateX = '0';
      this.mainContentOpacity = 0;
      this.mainContentTranslateX = '0';
      setTimeout(() => {
        this.isAnimating = false;
        this.animationPhase = 'entered';
      }, this.ANIMATION_DURATION);
    }, 30);
  }

  private navigateBack(): void {
    if (this.isAnimating || this.currentSubPage === 'none' || this.animationPhase === 'exiting') {
      return;
    }
    this.isAnimating = true;
    this.animationPhase = 'exiting';
    this.contentOpacity = 0;
    this.contentScale = this.isSmallScreen() ? 0.95 : 0.9;
    this.contentTranslateX = this.isSmallScreen() ? '100%' : '5%';
    this.mainContentOpacity = 0;
    this.mainContentTranslateX = this.isSmallScreen() ? '-5%' : '0%';
    this.mainContentScale = 0.92;

    setTimeout(() => {
      this.mainContentOpacity = 1;
      this.mainContentTranslateX = '0';
      this.mainContentScale = 1;
    }, 30);

    setTimeout(() => {
      this.currentSubPage = 'none';
      this.isAnimating = false;
      this.animationPhase = 'idle';
      this.contentOpacity = 0;
      this.contentScale = 0.92;
      this.contentTranslateX = '0';
    }, this.ANIMATION_DURATION);
  }

  private async handleLogout(): Promise<void> {
    try {
      const ctx = getContext(this);

      const store = await preferences.getPreferences(ctx, 'users');
      await store.put('isLoggedIn', false);
      await store.flush();

      const prefsStorage = PreferencesStorage.getInstance();
      await prefsStorage.init(ctx);
      await prefsStorage.clearCurrentUser();

      promptAction.showToast({ message: '已退出登录' });

      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      console.error('退出登录失败: ' + JSON.stringify(error));
      promptAction.showToast({ message: '退出登录失败，请重试' });
    }
  }

  private getTextColor(isDark: boolean): string {
    return isDark ? '#FFFFFF' : '#333333';
  }

  private getSecondaryTextColor(isDark: boolean): string {
    return isDark ? '#888888' : '#999999';
  }

  private getDividerColor(isDark: boolean): string {
    return isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)';
  }

  private getCardBackgroundColor(isDark: boolean): string {
    return isDark ? '#1C1C1E' : '#FFFFFF';
  }

  @Builder
  MainSettingsList() {
    Scroll() {
      Column({ space: 16 }) {
        this.SettingsGroupWithDivider([
          { title: '编辑资料', onClick: () => { this.navigateToSubPage('editProfile'); } },
          { title: '账号安全中心', onClick: () => { this.navigateToSubPage('privacy'); } }
        ])

        this.SettingsGroupWithDivider([
          { title: '液态玻璃设置', onClick: () => { this.navigateToSubPage('liquidGlass'); } },
          { title: '深色设置', onClick: () => { this.navigateToSubPage('darkMode'); } }
        ])

        this.SettingsGroupWithDivider([
          { title: '离线设置', onClick: () => { this.navigateToSubPage('offline'); } }
        ])

        this.SettingsGroupWithDivider([
          { title: '推送设置', onClick: () => { this.navigateToSubPage('push'); } },
          { title: '消息设置', onClick: () => { this.navigateToSubPage('message'); } }
        ])

        this.SettingsGroupWithDivider([
          { title: '清理缓存空间', onClick: () => { this.navigateToSubPage('storage'); } }
        ])

        this.SettingsGroupWithDivider([
          { title: '我的客服', onClick: () => { console.info('我的客服'); } },
          { title: '用户协议', onClick: () => { console.info('用户协议'); } },
          { title: '隐私政策', onClick: () => { console.info('隐私政策'); } },
          { title: '隐私权限设置', onClick: () => { console.info('隐私权限设置'); } },
          { title: '关于海海', onClick: () => { console.info('关于海海'); } }
        ], false)

        Column({ space: 0 }) {
          Button('退出登录')
            .width('100%')
            .height(52)
            .fontSize(16)
            .fontColor('#FF3B30')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.handleLogout();
            })
        }
        .width('100%')
        .backgroundColor(this.getCardBackgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
        .borderRadius(16)
        .margin({ top: 16 })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  SettingsGroupWithDivider(items: SettingItem[], showDivider: boolean = true) {
    Column() {
      ForEach(items, (item: SettingItem, index: number) => {
        this.SettingItemRow(item.title, item.onClick)
        if (showDivider && index < items.length - 1) {
          Divider()
            .color(this.getDividerColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
            .margin({ left: 16, right: 16 })
        }
      })
    }
    .width('100%')
    .backgroundColor(this.getCardBackgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
    .borderRadius(16)
  }

  @Builder
  SettingItemRow(title: string, onClick?: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  SubPageContent() {
    Column() {
      Row() {
        if (!this.isSmallScreen()) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
            .onClick(() => {
              this.navigateBack();
            })
        }

        Text(getSubPageTitle(this.currentSubPage))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
          .margin({ left: this.isSmallScreen() ? 0 : 16 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      this.getSubPagePanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  getSubPagePanel() {
    if (this.currentSubPage === 'liquidGlass') {
      LiquidGlassSettingsPanel()
    } else if (this.currentSubPage === 'storage') {
      StorageCleanPanel()
    } else if (this.currentSubPage === 'darkMode') {
      DarkModeSettingsPanel()
    } else if (this.currentSubPage === 'account') {
      AccountSettingsPanel()
    } else if (this.currentSubPage === 'editProfile') {
      EditProfilePanel()
    } else if (this.currentSubPage === 'privacy') {
      PrivacySettingsPanel()
    } else if (this.currentSubPage === 'offline') {
      OfflineSettingsPanel()
    } else if (this.currentSubPage === 'push') {
      PushSettingsPanel()
    } else if (this.currentSubPage === 'message') {
      MessageSettingsPanel()
    } else if (this.currentSubPage === 'changePassword') {
      ChangePasswordPanel()
    } else if (this.currentSubPage === 'changePhone') {
      ChangePhonePanel()
    } else if (this.currentSubPage === 'realNameAuth') {
      RealNameAuthPanel()
    } else if (this.currentSubPage === 'addEmail') {
      AddEmailPanel()
    } else if (this.currentSubPage === 'securityQuestion') {
      SecurityQuestionPanel()
    } else {
      this.PlaceholderContent()
    }
  }

  @Builder
  PlaceholderContent() {
    Column() {
      Column() {
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(48)
          .fontColor([this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
          .margin({ bottom: 16 })

        Text(getSubPageTitle(this.currentSubPage))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
          .margin({ bottom: 8 })

        Text('功能开发中，敬请期待')
          .fontSize(14)
          .fontColor(this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
      }
      .padding(32)
      .backgroundColor(this.getCardBackgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }

  @Builder
  MainSettingsHeader() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
        .onClick(() => {
          router.back();
        })

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
        .margin({ left: 16 })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  SmallScreenLayout() {
    Stack({ alignContent: Alignment.Start }) {
      Column() {
        this.MainSettingsHeader()
        this.MainSettingsList()
      }
      .width('100%')
      .height('100%')
      .opacity(this.mainContentOpacity)
      .translate({ x: this.mainContentTranslateX })
      .scale({ x: this.mainContentScale, y: this.mainContentScale })
      .animation({
        duration: this.ANIMATION_DURATION,
        curve: Curve.EaseOut,
        playMode: PlayMode.Normal
      })

      if (this.currentSubPage !== 'none') {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
              .onClick(() => {
                this.navigateBack();
              })

            Text(getSubPageTitle(this.currentSubPage))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
              .margin({ left: 16 })
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })

          Column() {
            this.SubPageContent()
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .opacity(this.contentOpacity)
        .scale({ x: this.contentScale, y: this.contentScale })
        .translate({ x: this.contentTranslateX })
        .animation({
          duration: this.ANIMATION_DURATION,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  MediumScreenLayout() {
    Row() {
      Column() {
        this.MainSettingsHeader()
        this.MainSettingsList()
      }
      .width('50%')
      .height('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')

      Column() {
        if (this.currentSubPage === 'none') {
          Column() {
            SymbolGlyph($r('sys.symbol.rectangle_split_3x1'))
              .fontSize(48)
              .fontColor([this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
              .margin({ bottom: 16 })

            Text('请选择设置项')
              .fontSize(16)
              .fontColor(this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#0D0D0D' : '#F8F8F8')
        } else {
          Column() {
            this.SubPageContent()
          }
          .width('100%')
          .height('100%')
          .opacity(this.contentOpacity)
          .scale({ x: this.contentScale, y: this.contentScale })
          .animation({
            duration: this.ANIMATION_DURATION,
            curve: Curve.EaseOut,
            playMode: PlayMode.Normal
          })
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  LargeScreenLayout() {
    Row() {
      Column() {
        this.MainSettingsHeader()
        this.MainSettingsList()
      }
      .width('33.33%')
      .height('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')

      Column() {
        if (this.currentSubPage === 'none') {
          Column() {
            SymbolGlyph($r('sys.symbol.rectangle_split_3x1'))
              .fontSize(48)
              .fontColor([this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)])
              .margin({ bottom: 16 })

            Text('请选择设置项')
              .fontSize(16)
              .fontColor(this.getSecondaryTextColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#0D0D0D' : '#F8F8F8')
        } else {
          Column() {
            this.SubPageContent()
          }
          .width('100%')
          .height('100%')
          .opacity(this.contentOpacity)
          .scale({ x: this.contentScale, y: this.contentScale })
          .animation({
            duration: this.ANIMATION_DURATION,
            curve: Curve.EaseOut,
            playMode: PlayMode.Normal
          })
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  build() {
    if (this.isLargeScreen()) {
      this.LargeScreenLayout()
    } else if (this.isMediumScreen()) {
      this.MediumScreenLayout()
    } else {
      this.SmallScreenLayout()
    }
  }
}
