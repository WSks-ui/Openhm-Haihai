import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';

@Component
export struct OfflineSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  ToggleItem(title: string, value: boolean, onChange: (val: boolean) => void) {
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
  ArrowItem(title: string, onClick: () => void) {
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleItem('离线模式', false, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('缓存管理', () => { promptAction.showToast({ message: '缓存管理' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('离线下载', () => { promptAction.showToast({ message: '离线下载' }); })
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
}

@Component
export struct PushSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  ToggleItem(title: string, value: boolean, onChange: (val: boolean) => void) {
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleItem('允许推送', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleItem('消息通知', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleItem('消息声音', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
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
}

@Component
export struct MessageSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  ToggleItem(title: string, value: boolean, onChange: (val: boolean) => void) {
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
  ArrowItem(title: string, onClick: () => void) {
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          this.ToggleItem('消息已读回执', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ToggleItem('输入状态显示', true, (val) => { promptAction.showToast({ message: val ? '已开启' : '已关闭' }); })
          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .margin({ left: 20 })
          this.ArrowItem('消息提醒设置', () => { promptAction.showToast({ message: '消息提醒设置' }); })
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
}
