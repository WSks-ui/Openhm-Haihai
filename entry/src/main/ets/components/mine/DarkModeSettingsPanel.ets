// 亮暗界面设置
import { ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { PreferencesStorage } from '../../utils/PreferencesStorage';
import { BRAND_PRIMARY } from '../../constants/ThemeTokens';

type ColorModeOption = 'system' | 'light' | 'dark';

@Component
export struct DarkModeSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State selectedMode: ColorModeOption = 'light';
  @State isSystemMode: boolean = false;

  aboutToAppear() {
    this.syncCurrentMode();
  }

  private syncCurrentMode(): void {
    if (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      this.selectedMode = 'system';
      this.isSystemMode = true;
    } else if (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      this.selectedMode = 'dark';
      this.isSystemMode = false;
    } else {
      this.selectedMode = 'light';
      this.isSystemMode = false;
    }
  }

  private async applyColorMode(mode: ColorModeOption): Promise<void> {
    try {
      const windowStage = await window.getLastWindow(getContext(this));
      const prefsStorage = PreferencesStorage.getInstance();
      
      let colorModeToSet: number;
      
      switch (mode) {
        case 'system':
          windowStage.setWindowSystemBarProperties({
            statusBarColor: '#00000000'
          });
          colorModeToSet = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
          break;
        case 'light':
          windowStage.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            isStatusBarLightIcon: false
          });
          colorModeToSet = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
          break;
        case 'dark':
          windowStage.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            isStatusBarLightIcon: true
          });
          colorModeToSet = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
          break;
      }

      this.currentMode = colorModeToSet;
      this.selectedMode = mode;
      this.isSystemMode = mode === 'system';
      
      // 保存到持久化存储
      await prefsStorage.setColorMode(colorModeToSet);
      
      // 设置应用上下文的颜色模式
      const context = getContext(this);
      try {
        if (colorModeToSet === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
          context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } else {
          context.getApplicationContext().setColorMode(colorModeToSet);
        }
      } catch (err) {
        console.error('Failed to set application color mode:', err);
      }
      
    } catch (err) {
      console.error('Failed to set color mode:', err);
    }
  }

  private isModeSelected(mode: ColorModeOption): boolean {
    return this.selectedMode === mode;
  }

  @Builder
  ModeOptionCard(mode: ColorModeOption, title: string, subtitle: string, icon: Resource) {
    Column({ space: 12 }) {
      SymbolGlyph(icon)
        .fontSize(28)
        .fontColor([this.isModeSelected(mode) ? '#FFFFFF' : 
                   (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')])

      Text(title)
        .fontSize(16)
        .fontWeight(this.isModeSelected(mode) ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.isModeSelected(mode) ? '#FFFFFF' : 
                   (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333'))

      Text(subtitle)
        .fontSize(12)
        .fontColor(this.isModeSelected(mode) ? 'rgba(255,255,255,0.7)' : 
                   (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'))
    }
    .width('30%')
    .padding({ top: 20, bottom: 20, left: 12, right: 12 })
    .backgroundColor(this.isModeSelected(mode) ? 'BRAND_PRIMARY' : 
                   (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF'))
    .borderRadius(16)
    .shadow(this.isModeSelected(mode) ? { radius: 12, color: 'rgba(0,122,255,0.3)', offsetY: 4 } : { radius: 0 })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .onClick(() => {
      if (this.selectedMode !== mode) {
        this.applyColorMode(mode);
      }
    })
  }

  @Builder
  PreviewCard() {
    Column({ space: 16 }) {
      Text('预览效果')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')
        .width('100%')

      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text('浅色模式')
            .fontSize(12)
            .fontColor('#333333')

          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Column()
                .width(20)
                .height(20)
                .backgroundColor('BRAND_PRIMARY')
                .borderRadius(4)

              Column()
                .layoutWeight(1)
                .height(8)
                .backgroundColor('#E5E5E5')
                .borderRadius(4)
            }
            .width('100%')

            Row({ space: 6 }) {
              Column()
                .width(20)
                .height(20)
                .backgroundColor('#34C759')
                .borderRadius(4)

              Column()
                .layoutWeight(1)
                .height(8)
                .backgroundColor('#E5E5E5')
                .borderRadius(4)
            }
            .width('100%')
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })

        Column({ space: 8 }) {
          Text('深色模式')
            .fontSize(12)
            .fontColor('#E0E0E0')

          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Column()
                .width(20)
                .height(20)
                .backgroundColor('#0A84FF')
                .borderRadius(4)

              Column()
                .layoutWeight(1)
                .height(8)
                .backgroundColor('#38383A')
                .borderRadius(4)
            }
            .width('100%')

            Row({ space: 6 }) {
              Column()
                .width(20)
                .height(20)
                .backgroundColor('#30D158')
                .borderRadius(4)

              Column()
                .layoutWeight(1)
                .height(8)
                .backgroundColor('#38383A')
                .borderRadius(4)
            }
            .width('100%')
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#2C2C2E')
          .borderRadius(8)
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#1C1C1E')
        .borderRadius(12)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)' })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  InfoCard() {
    Row() {
      SymbolGlyph($r('sys.symbol.info_circle'))
        .fontSize(20)
        .fontColor(['BRAND_PRIMARY'])
        .margin({ right: 12 })

      Column() {
        Text('关于深色模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          .margin({ bottom: 4 })

        Text('深色模式可以降低眼睛疲劳，在夜间使用更舒适，同时也能节省设备电量。')
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,122,255,0.1)' : 'rgba(0,122,255,0.05)')
    .borderRadius(12)
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 12 }) {
          Text('选择主题')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
            .width('100%')

          Row({ space: 12 }) {
            this.ModeOptionCard('light', '浅色', '默认模式', $r('sys.symbol.checkmark_circle_fill'))
            this.ModeOptionCard('dark', '深色', '夜间模式', $r('sys.symbol.heart'))
            this.ModeOptionCard('system', '跟随系统', '自动切换', $r('sys.symbol.gearshape'))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }

        this.PreviewCard()

        this.InfoCard()

        Column({ space: 8 }) {
          Text('提示')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
            .width('100%')

          Text('• 选择「跟随系统」时，应用将自动跟随系统深色模式设置')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
            .width('100%')

          Text('• 切换主题时，应用会立即更新界面显示')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
            .width('100%')

          Text('• 部分系统控件需要重启应用才能完全生效')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
            .width('100%')
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }
}