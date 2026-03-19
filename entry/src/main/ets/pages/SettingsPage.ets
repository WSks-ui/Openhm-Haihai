import { ConfigurationConstant } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import preferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import { LiquidGlass, GLASS_OPACITY_PRESETS, GlassOpacityPreset } from '../components/LiquidGlass';
import { StorageCleanPanel } from '../components/StorageCleanPanel';
import { DarkModeSettingsPanel } from '../components/DarkModeSettingsPanel';
import { AccountSettingsPanel } from '../components/AccountSettingsPanel';
import { PreferencesStorage } from '../utils/PreferencesStorage';
import { UserManager } from '../model/UserModel';

interface SettingItem {
  title: string;
  hasArrow?: boolean;
  onClick?: () => void;
}

type SubPageType = 'none' | 'liquidGlass' | 'darkMode' | 'account' | 'privacy' | 'offline' | 'push' | 'message' | 'storage' | 'editProfile' |
  'changePassword' | 'changePhone' | 'realNameAuth' | 'addEmail' | 'securityQuestion';

@Entry
@Component
struct SettingsPage {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('glassOpacity') glassOpacity: number = 0.4;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State currentSubPage: SubPageType = 'none';
  @State selectedPresetIndex: number = 1;
  @State previewOpacity: number = 0.4;
  @State isAnimating: boolean = false;
  @State animationType: 'none' | 'enter' | 'exit' = 'none';
  @State showSubPage: boolean = false;

  // 编辑资料相关状态
  @StorageLink('userName') userName: string = '我的名字';
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';
  @StorageLink('userUid') userUid: string = 'U10001';
  @StorageLink('userBio') userBio: string = '记录生活，发现美好';
  @StorageLink('userGender') userGender: string = '保密';
  @StorageLink('userBirthday') userBirthday: string = '2000-01-01';
  @StorageLink('userPhone') userPhone: string = '';

  private userManager: UserManager = UserManager.getInstance();

  @State privacyEnabled: boolean = true;
  @State offlineMode: boolean = false;
  @State pushEnabled: boolean = true;
  @State messageNotification: boolean = true;
  @State messageSound: boolean = true;

  // 账号安全中心相关状态
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State passwordStrength: string = '';
  @State newPhone: string = '';
  @State verifyCode: string = '';
  @State realName: string = '';
  @State idCard: string = '';
  @State email: string = '';
  @State emailVerifyCode: string = '';
  @State securityQuestion: string = '';
  @State securityAnswer: string = '';
  @State countdown: number = 0;
  @State isVerified: boolean = false;

  aboutToAppear() {
    this.previewOpacity = this.glassOpacity;
    this.selectedPresetIndex = GLASS_OPACITY_PRESETS.findIndex(p => p.value === this.glassOpacity);
    if (this.selectedPresetIndex < 0) {
      this.selectedPresetIndex = 1;
    }
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
    if (subPage === 'none' || this.isAnimating) {
      return;
    }
    this.animationType = 'enter';
    this.isAnimating = true;
    this.currentSubPage = subPage;
    setTimeout(() => {
      this.showSubPage = true;
    }, 50);
    setTimeout(() => {
      this.isAnimating = false;
      this.animationType = 'none';
    }, 300);
  }

  private navigateBack(): void {
    if (this.isAnimating || this.currentSubPage === 'none') {
      return;
    }
    this.animationType = 'exit';
    this.isAnimating = true;
    this.showSubPage = false;
    setTimeout(() => {
      this.currentSubPage = 'none';
      this.isAnimating = false;
      this.animationType = 'none';
    }, 300);
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

  @Builder
  SettingItem(title: string, hasArrow: boolean = true, onClick?: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .layoutWeight(1)

      if (hasArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#CCCCCC'])
      }
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
  SettingGroup(items: SettingItem[]) {
    Column() {
      ForEach(items, (item: SettingItem, index: number) => {
        this.SettingItem(item.title, item.hasArrow !== false, item.onClick)
        if (index < items.length - 1) {
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 16, right: 16 })
        }
      })
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  PreviewCard() {
    Column() {
      Text('预览效果')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')
        .margin({ bottom: 12 })

      Stack() {
        Column() {
          Row() {
            Text('液态玻璃效果')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
            Blank()
            Text(`透明度: ${Math.round(this.previewOpacity * 100)}%`)
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          Row() {
            Text('调整上方滑块或选择预设，实时查看效果变化')
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
      }
      .borderRadius(16)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
        ? `rgba(255, 255, 255, ${this.previewOpacity * 0.125})` 
        : `rgba(255, 255, 255, ${this.previewOpacity})`)
      .backdropBlur(40)
      .border({
        width: 1,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
          ? 'rgba(255, 255, 255, 0.15)' 
          : 'rgba(255, 255, 255, 0.6)'
      })
      .shadow({
        radius: 30,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)',
        offsetY: 10
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  OpacitySlider() {
    Column() {
      Text('透明度调节')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .margin({ bottom: 16 })

      Row() {
        Text('轻盈')
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
        Slider({
          value: this.previewOpacity * 100,
          min: 10,
          max: 80,
          step: 5,
          style: SliderStyle.OutSet
        })
          .blockColor('#7B68EE')
          .trackColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#E0E0E0')
          .selectedColor('#7B68EE')
          .layoutWeight(1)
          .margin({ left: 12, right: 12 })
          .onChange((value: number) => {
            this.previewOpacity = value / 100;
            this.selectedPresetIndex = -1;
          })
        Text('浓郁')
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
    .borderRadius(16)
    .margin({ top: 16 })
  }

  @Builder
  PresetOptions() {
    Column() {
      Text('预设选项')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .margin({ bottom: 16 })

      ForEach(GLASS_OPACITY_PRESETS, (preset: GlassOpacityPreset, index: number) => {
        Row() {
          Column() {
            Text(preset.name)
              .fontSize(14)
              .fontWeight(this.selectedPresetIndex === index ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
            Text(preset.description)
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (this.selectedPresetIndex === index) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(24)
              .fontColor(['#7B68EE'])
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.selectedPresetIndex === index 
          ? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123,104,238,0.2)' : '#E8E4FF')
          : Color.Transparent)
        .borderRadius(12)
        .margin({ bottom: 8 })
        .onClick(() => {
          this.selectedPresetIndex = index;
          this.previewOpacity = preset.value;
        })
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
    .borderRadius(16)
    .margin({ top: 16 })
  }

  @Builder
  MainSettingsList() {
    Scroll() {
      Column({ space: 16 }) {
        this.SettingGroup([
          { title: '编辑资料', onClick: () => { this.navigateToSubPage('editProfile'); } },
          { title: '账号安全中心', onClick: () => { this.navigateToSubPage('privacy'); } }
        ])

        this.SettingGroup([
          { title: '液态玻璃设置', onClick: () => { this.navigateToSubPage('liquidGlass'); } },
          { title: '深色设置', onClick: () => { this.navigateToSubPage('darkMode'); } }
        ])

        this.SettingGroup([
          { title: '离线设置', onClick: () => { this.navigateToSubPage('offline'); } }
        ])

        this.SettingGroup([
          { title: '推送设置', onClick: () => { this.navigateToSubPage('push'); } },
          { title: '消息设置', onClick: () => { this.navigateToSubPage('message'); } }
        ])

        this.SettingGroup([
          { title: '清理缓存空间', onClick: () => { this.navigateToSubPage('storage'); } }
        ])

        Column({ space: 0 }) {
          this.SettingItem('我的客服', true, () => { console.info('我的客服'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 16, right: 16 })
          this.SettingItem('用户协议', true, () => { console.info('用户协议'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 16, right: 16 })
          this.SettingItem('隐私政策', true, () => { console.info('隐私政策'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 16, right: 16 })
          this.SettingItem('隐私权限设置', true, () => { console.info('隐私权限设置'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 16, right: 16 })
          this.SettingItem('关于海海', true, () => { console.info('关于海海'); })
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

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
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)
        .margin({ top: 16 })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  LiquidGlassSettingsPanel() {
    Scroll() {
      Column() {
        this.PreviewCard()
        this.OpacitySlider()
        this.PresetOptions()

        Button('应用设置')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#7B68EE')
          .borderRadius(24)
          .margin({ top: 24, left: 16, right: 16 })
          .onClick(() => {
            this.glassOpacity = this.previewOpacity;
          })
      }
      .padding({ bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  SubPageContent() {
    Column() {
      Row() {
        if (!this.isSmallScreen()) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333'])
            .onClick(() => {
              this.navigateBack();
            })
        }

        Text(this.getSubPageTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          .margin({ left: this.isSmallScreen() ? 0 : 16 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      if (this.currentSubPage === 'liquidGlass') {
        this.LiquidGlassSettingsPanel()
      } else if (this.currentSubPage === 'storage') {
        StorageCleanPanel()
      } else if (this.currentSubPage === 'darkMode') {
        DarkModeSettingsPanel()
      } else if (this.currentSubPage === 'account') {
        AccountSettingsPanel()
      } else if (this.currentSubPage === 'editProfile') {
        this.EditProfileContent()
      } else if (this.currentSubPage === 'privacy') {
        this.PrivacySettingsPanel()
      } else if (this.currentSubPage === 'changePassword') {
        this.ChangePasswordPanel()
      } else if (this.currentSubPage === 'changePhone') {
        this.ChangePhonePanel()
      } else if (this.currentSubPage === 'realNameAuth') {
        this.RealNameAuthPanel()
      } else if (this.currentSubPage === 'addEmail') {
        this.AddEmailPanel()
      } else if (this.currentSubPage === 'securityQuestion') {
        this.SecurityQuestionPanel()
      } else if (this.currentSubPage === 'offline') {
        this.OfflineSettingsPanel()
      } else if (this.currentSubPage === 'push') {
        this.PushSettingsPanel()
      } else if (this.currentSubPage === 'message') {
        this.MessageSettingsPanel()
      } else {
        this.PlaceholderContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  PlaceholderContent() {
    Column() {
      Column() {
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(48)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#CCCCCC'])
          .margin({ bottom: 16 })

        Text(this.getSubPageTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          .margin({ bottom: 8 })

        Text('功能开发中，敬请期待')
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
      }
      .padding(32)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }

  private getSubPageTitle(): string {
    switch (this.currentSubPage) {
      case 'liquidGlass':
        return '液态玻璃设置';
      case 'darkMode':
        return '深色设置';
      case 'account':
        return '账号资料';
      case 'privacy':
        return '账号安全中心';
      case 'changePassword':
        return '修改密码';
      case 'changePhone':
        return '更换手机号';
      case 'realNameAuth':
        return '实名认证';
      case 'addEmail':
        return '邮箱添加';
      case 'securityQuestion':
        return '密保问题';
      case 'offline':
        return '离线设置';
      case 'push':
        return '推送设置';
      case 'message':
        return '消息设置';
      case 'storage':
        return '清理储存空间';
      case 'editProfile':
        return '编辑资料';
      default:
        return '设置';
    }
  }

  @Builder
  MainSettingsHeader() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333'])
        .onClick(() => {
          router.back();
        })

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .margin({ left: 16 })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
  }

  @Builder
  SmallScreenLayout() {
    Column() {
      if (this.currentSubPage === 'none') {
        this.MainSettingsHeader()
        this.MainSettingsList()
      } else {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333'])
              .onClick(() => {
                this.navigateBack();
              })

            Text(this.getSubPageTitle())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
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
          .translate({ x: this.showSubPage ? 0 : '100%' })
          .opacity(this.showSubPage ? 1 : 0)
          .animation({
            duration: 300,
            curve: Curve.EaseInOut
          })
        }
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
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#CCCCCC'])
              .margin({ bottom: 16 })

            Text('请选择设置项')
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
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
          .opacity(this.showSubPage ? 1 : 0)
          .animation({
            duration: 300,
            curve: Curve.EaseInOut
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
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#CCCCCC'])
              .margin({ bottom: 16 })

            Text('请选择设置项')
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
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
          .opacity(this.showSubPage ? 1 : 0)
          .animation({
            duration: 300,
            curve: Curve.EaseInOut
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

  private async saveUserInfo() {
    if (!this.userPhone) {
      promptAction.showToast({ message: '用户信息异常，请重新登录' });
      return;
    }

    const success = await this.userManager.updateUser(this.userPhone, {
      nickname: this.userName,
      avatar: this.userAvatar,
      bio: this.userBio,
      gender: this.userGender,
      birthday: this.userBirthday
    });

    if (success) {
      promptAction.showToast({ message: '保存成功' });
    } else {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  @Builder
  EditProfileContent() {
    Column() {
      Row() {
        Blank()
        Text('保存')
          .fontSize(16)
          .fontColor('#7B68EE')
          .onClick(() => this.saveUserInfo())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 0, bottom: 16 })

      Scroll() {
        Column({ space: 16 }) {
          Column() {
            Column() {
              Stack() {
                if (this.userAvatar.startsWith('app.media.')) {
                  Image($r(this.userAvatar))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                } else {
                  Image($rawfile(this.userAvatar))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                }
                Column() {
                  SymbolGlyph($r('sys.symbol.camera_fill'))
                    .fontSize(20)
                    .fontColor([Color.White])
                }
                .width(100)
                .height(100)
                .borderRadius(50)
                .backgroundColor('rgba(0,0,0,0.4)')
                .justifyContent(FlexAlign.Center)
              }
              .width(100)
              .height(100)
              .margin({ top: 24, bottom: 12 })

              Text('点击更换头像')
                .fontSize(14)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)
          .padding({ bottom: 24 })

          Column({ space: 0 }) {
            this.EditProfileItem('昵称', this.userName, (val) => { this.userName = val; })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileInfoItem('ID', this.userUid)
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileItem('简介', this.userBio, (val) => { this.userBio = val; })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileSelectItem('性别', this.userGender, () => {
              promptAction.showActionMenu({
                title: '选择性别',
                buttons: [
                  { text: '男', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' },
                  { text: '女', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' },
                  { text: '保密', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' }
                ]
              }, (err, data) => {
                if (data.index === 0) this.userGender = '男';
                if (data.index === 1) this.userGender = '女';
                if (data.index === 2) this.userGender = '保密';
              });
            })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileSelectItem('生日', this.userBirthday, () => {
              DatePickerDialog.show({
                start: new Date('1900-01-01'),
                end: new Date('2100-12-31'),
                selected: new Date(this.userBirthday),
                onAccept: (value: DatePickerResult) => {
                  const year = value.year;
                  const month = (value.month ?? 0) + 1;
                  const day = value.day ?? 1;
                  const monthStr = month < 10 ? `0${month}` : `${month}`;
                  const dayStr = day < 10 ? `0${day}` : `${day}`;
                  this.userBirthday = `${year}-${monthStr}-${dayStr}`;
                }
              });
            })
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)

          Column({ space: 0 }) {
            this.EditProfileArrowItem('管理自己的主页', () => {
              promptAction.showToast({ message: '管理主页设置' });
            })
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)

        }
        .padding({ left: 16, right: 16, top: 0, bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  EditProfileItem(title: string, value: string, onChange: (val: string) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      TextInput({ text: value })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .textAlign(TextAlign.End)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .maxLines(1)
        .onChange(onChange)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  EditProfileInfoItem(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      Text(value)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  EditProfileSelectItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      Text(value)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
        .margin({ left: 8 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  EditProfileArrowItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  PrivacySettingsPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ArrowSettingItem('修改账号密码', () => { this.navigateToSubPage('changePassword'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('更换绑定的手机号', () => { this.navigateToSubPage('changePhone'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('实名认证', () => { this.navigateToSubPage('realNameAuth'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('邮箱添加', () => { this.navigateToSubPage('addEmail'); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('密保问题', () => { this.navigateToSubPage('securityQuestion'); })
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Column() {
          Text('账号安全中心用于管理您的账号安全设置，建议定期检查并更新安全信息')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  OfflineSettingsPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleSettingItem('离线模式', this.offlineMode, (val) => { this.offlineMode = val; })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('缓存管理', () => { promptAction.showToast({ message: '缓存管理' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('离线下载', () => { promptAction.showToast({ message: '离线下载' }); })
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Column() {
          Text('离线模式下，您可以查看已缓存的内容，但无法接收新消息和推送通知')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  PushSettingsPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleSettingItem('允许推送', this.pushEnabled, (val) => { this.pushEnabled = val; })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleSettingItem('消息通知', this.messageNotification, (val) => { this.messageNotification = val; })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleSettingItem('消息声音', this.messageSound, (val) => { this.messageSound = val; })
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Column() {
          Text('您可以在此管理应用的推送通知设置，关闭后将不会收到新消息提醒')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  MessageSettingsPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleSettingItem('消息已读回执', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleSettingItem('输入状态显示', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowSettingItem('消息提醒设置', () => { this.navigateToSubPage('push'); })
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Column() {
          Text('消息设置用于管理聊天相关的功能和通知偏好')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  ToggleSettingItem(title: string, value: boolean, onChange: (val: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#7B68EE')
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  ArrowSettingItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  ChangePasswordPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('旧密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入旧密码', text: this.oldPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.oldPassword = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('新密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入新密码', text: this.newPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.newPassword = value;
                this.checkPasswordStrength(value);
              })
            if (this.passwordStrength) {
              Text(this.passwordStrength)
                .fontSize(12)
                .fontColor(this.getPasswordStrengthColor())
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('确认新密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('确认修改')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleChangePassword();
          })

        Column() {
          Text('密码要求：长度8-20位，需包含字母和数字')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  ChangePhonePanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('当前绑定手机号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Text(this.userPhone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2'))
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('新手机号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入新手机号', text: this.newPhone })
              .type(InputType.PhoneNumber)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(11)
              .onChange((value: string) => {
                this.newPhone = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('验证码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入验证码', text: this.verifyCode })
                .type(InputType.Number)
                .height(48)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .layoutWeight(1)
                .maxLength(6)
                .onChange((value: string) => {
                  this.verifyCode = value;
                })
              Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                .width(110)
                .height(48)
                .backgroundColor(this.countdown > 0 ? '#CCCCCC' : '#7B68EE')
                .fontColor('#FFFFFF')
                .fontSize(14)
                .borderRadius(12)
                .margin({ left: 12 })
                .enabled(this.countdown === 0)
                .onClick(() => {
                  this.sendVerifyCode();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('确认更换')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleChangePhone();
          })

        Column() {
          Text('更换手机号后，原手机号将无法用于登录，请妥善保管新手机号')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  RealNameAuthPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('真实姓名')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入真实姓名', text: this.realName })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(20)
              .onChange((value: string) => {
                this.realName = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('身份证号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入身份证号', text: this.idCard })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(18)
              .onChange((value: string) => {
                this.idCard = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('提交认证')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleRealNameAuth();
          })

        Column() {
          Text('实名认证信息仅用于身份验证，我们将严格保护您的隐私安全')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  AddEmailPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('邮箱地址')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入邮箱地址', text: this.email })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.email = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('验证码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入验证码', text: this.emailVerifyCode })
                .type(InputType.Number)
                .height(48)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .layoutWeight(1)
                .maxLength(6)
                .onChange((value: string) => {
                  this.emailVerifyCode = value;
                })
              Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                .width(110)
                .height(48)
                .backgroundColor(this.countdown > 0 ? '#CCCCCC' : '#7B68EE')
                .fontColor('#FFFFFF')
                .fontSize(14)
                .borderRadius(12)
                .margin({ left: 12 })
                .enabled(this.countdown === 0)
                .onClick(() => {
                  this.sendEmailVerifyCode();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('添加邮箱')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleAddEmail();
          })

        Column() {
          Text('绑定邮箱可用于找回密码和接收重要通知')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  @Builder
  SecurityQuestionPanel() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('选择密保问题')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Select([
              { value: '您的出生地是？' },
              { value: '您母亲的姓名是？' },
              { value: '您最喜欢的颜色是？' },
              { value: '您第一只宠物的名字是？' },
              { value: '您小学的名称是？' }
            ])
              .selected(0)
              .value(this.securityQuestion || '请选择密保问题')
              .font({ size: 16 })
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
              .selectedOptionFont({ size: 16 })
              .optionFont({ size: 16 })
              .width('100%')
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .onSelect((index: number) => {
                const questions = ['您的出生地是？', '您母亲的姓名是？', '您最喜欢的颜色是？', '您第一只宠物的名字是？', '您小学的名称是？'];
                this.securityQuestion = questions[index];
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('答案')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入答案', text: this.securityAnswer })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(50)
              .onChange((value: string) => {
                this.securityAnswer = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('保存设置')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleSecurityQuestion();
          })

        Column() {
          Text('密保问题可用于找回密码，请牢记您设置的答案')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }

  private checkPasswordStrength(password: string): void {
    if (password.length < 8) {
      this.passwordStrength = '弱：密码长度不足8位';
    } else if (!/[a-zA-Z]/.test(password) || !/[0-9]/.test(password)) {
      this.passwordStrength = '弱：需包含字母和数字';
    } else if (password.length >= 12 && /[a-zA-Z]/.test(password) && /[0-9]/.test(password) && /[^a-zA-Z0-9]/.test(password)) {
      this.passwordStrength = '强：密码安全性高';
    } else {
      this.passwordStrength = '中：密码安全性一般';
    }
  }

  private getPasswordStrengthColor(): string {
    if (this.passwordStrength.startsWith('强')) {
      return '#34C759';
    } else if (this.passwordStrength.startsWith('中')) {
      return '#FF9500';
    } else {
      return '#FF3B30';
    }
  }

  private handleChangePassword(): void {
    if (!this.oldPassword) {
      promptAction.showToast({ message: '请输入旧密码' });
      return;
    }
    if (!this.newPassword) {
      promptAction.showToast({ message: '请输入新密码' });
      return;
    }
    if (this.newPassword.length < 8 || this.newPassword.length > 20) {
      promptAction.showToast({ message: '密码长度需为8-20位' });
      return;
    }
    if (!/[a-zA-Z]/.test(this.newPassword) || !/[0-9]/.test(this.newPassword)) {
      promptAction.showToast({ message: '密码需包含字母和数字' });
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }
    promptAction.showToast({ message: '密码修改成功' });
    this.oldPassword = '';
    this.newPassword = '';
    this.confirmPassword = '';
    this.passwordStrength = '';
  }

  private sendVerifyCode(): void {
    if (!this.newPhone) {
      promptAction.showToast({ message: '请输入新手机号' });
      return;
    }
    if (!/^1[3-9]\d{9}$/.test(this.newPhone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    promptAction.showToast({ message: '验证码已发送' });
    this.countdown = 60;
    this.startCountdown();
  }

  private startCountdown(): void {
    if (this.countdown > 0) {
      this.countdown--;
      setTimeout(() => {
        this.startCountdown();
      }, 1000);
    }
  }

  private handleChangePhone(): void {
    if (!this.newPhone) {
      promptAction.showToast({ message: '请输入新手机号' });
      return;
    }
    if (!/^1[3-9]\d{9}$/.test(this.newPhone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (!this.verifyCode || this.verifyCode.length !== 6) {
      promptAction.showToast({ message: '请输入6位验证码' });
      return;
    }
    promptAction.showToast({ message: '手机号更换成功' });
    this.newPhone = '';
    this.verifyCode = '';
  }

  private handleRealNameAuth(): void {
    if (!this.realName) {
      promptAction.showToast({ message: '请输入真实姓名' });
      return;
    }
    if (!this.idCard) {
      promptAction.showToast({ message: '请输入身份证号' });
      return;
    }
    if (!/^\d{17}[\dXx]$/.test(this.idCard)) {
      promptAction.showToast({ message: '请输入正确的身份证号' });
      return;
    }
    promptAction.showToast({ message: '实名认证提交成功' });
    this.realName = '';
    this.idCard = '';
  }

  private sendEmailVerifyCode(): void {
    if (!this.email) {
      promptAction.showToast({ message: '请输入邮箱地址' });
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      promptAction.showToast({ message: '请输入正确的邮箱地址' });
      return;
    }
    promptAction.showToast({ message: '验证码已发送至邮箱' });
    this.countdown = 60;
    this.startCountdown();
  }

  private handleAddEmail(): void {
    if (!this.email) {
      promptAction.showToast({ message: '请输入邮箱地址' });
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      promptAction.showToast({ message: '请输入正确的邮箱地址' });
      return;
    }
    if (!this.emailVerifyCode || this.emailVerifyCode.length !== 6) {
      promptAction.showToast({ message: '请输入6位验证码' });
      return;
    }
    promptAction.showToast({ message: '邮箱添加成功' });
    this.email = '';
    this.emailVerifyCode = '';
  }

  private handleSecurityQuestion(): void {
    if (!this.securityQuestion) {
      promptAction.showToast({ message: '请选择密保问题' });
      return;
    }
    if (!this.securityAnswer) {
      promptAction.showToast({ message: '请输入答案' });
      return;
    }
    promptAction.showToast({ message: '密保问题设置成功' });
    this.securityQuestion = '';
    this.securityAnswer = '';
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