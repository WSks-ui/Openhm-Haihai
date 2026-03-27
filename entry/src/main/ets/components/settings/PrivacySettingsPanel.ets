import { ConfigurationConstant } from '@kit.AbilityKit';
import { SubPageType } from '../../types/SettingsTypes';

@Component
export struct PrivacySettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  @StorageLink('userPhone') userPhone: string = '';

  private navigateToSubPage(subPage: SubPageType): void {
    AppStorage.setOrCreate('pendingSubPage', subPage);
  }

  @Builder
  ArrowItem(title: string, subPage: SubPageType) {
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
      this.navigateToSubPage(subPage);
    })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ArrowItem('修改账号密码', 'changePassword')
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('更换绑定的手机号', 'changePhone')
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('实名认证', 'realNameAuth')
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('邮箱添加', 'addEmail')
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('密保问题', 'securityQuestion')
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
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .padding({ top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}
