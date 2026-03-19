import router from '@ohos.router';
import { ConfigurationConstant } from '@kit.AbilityKit';

interface PageHeaderProps {
  title: string;
  showBack?: boolean;
}

@Component
export struct PageHeader {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Prop title: string = '';
  @Prop showBack: boolean = true;

  build() {
    Row() {
      if (this.showBack) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
          .onClick(() => router.back())
      }
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
        .margin({ left: this.showBack ? 12 : 0 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.9)')
    .zIndex(10)
  }
}
