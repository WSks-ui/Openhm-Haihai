import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct AccountSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State nickname: string = '用户昵称';
  @State gender: string = '未设置';
  @State birthday: string = '未设置';
  @State signature: string = '这个人很懒，什么都没写~';
  @State uid: string = '123456789';

  @Builder
  InfoItem(title: string, value: string, hasArrow: boolean = true, onClick?: () => void) {
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

      if (hasArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  AvatarSection() {
    Column({ space: 16 }) {
      Stack() {
        Column()
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#E5E5EA')

        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(48)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#C7C7CC'])
      }
      .onClick(() => {})

      Text(this.nickname)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')

      Text(`UID: ${this.uid}`)
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
    }
    .width('100%')
    .padding({ top: 32, bottom: 24 })
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column() {
          this.AvatarSection()
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(20)

        Column({ space: 0 }) {
          this.InfoItem('昵称', this.nickname, true, () => {})

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })

          this.InfoItem('性别', this.gender, true, () => {})

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })

          this.InfoItem('出生年月', this.birthday, true, () => {})

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })

          this.InfoItem('个性签名', this.signature, true, () => {})
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(20)
      }
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }
}