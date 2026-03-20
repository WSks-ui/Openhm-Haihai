import router from '@ohos.router';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { LiquidGlass } from '../../components/LiquidGlass';

@Component
export struct ChatHeaderBar {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  onClearHistory: () => void = () => {};
  onOpenSettings: () => void = () => {};

  build() {
    Column() {
      LiquidGlass({
        glassWidth: '95%',
        glassPadding: { left: 16, right: 16, top: 12, bottom: 12 },
        glassRadius: 32
      }) {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
            .onClick(() => router.back())

          Text('Kepler')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            .margin({ left: 12 })

          Blank()

          Text('清空')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
            .margin({ right: 16 })
            .onClick(() => this.onClearHistory())

          SymbolGlyph($r('sys.symbol.gearshape'))
            .fontSize(24)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
            .onClick(() => this.onOpenSettings())
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .zIndex(10)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
