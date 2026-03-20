import { ConfigurationConstant } from '@kit.AbilityKit';
import { SuggestionCard } from './types';

@Component
export struct SuggestionCards {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  onSuggestionClick: (desc: string) => void = () => {};

  private suggestions: SuggestionCard[] = [
    { title: '科技总结', desc: 'iPhone 17 系列有什么新功能', icon: 'app.media.startIcon' },
    { title: '周末去哪', desc: '帮我规划本地温泉2日游', icon: 'app.media.startIcon' }
  ];

  build() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.suggestions, (item: SuggestionCard) => {
          Column() {
            Text(item.title)
              .fontSize(15)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' :
                '#222')
            Text(item.desc)
              .fontSize(13)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' :
                '#555')
              .margin({ top: 6 })
              .maxLines(2)
          }
          .width(160)
          .padding(16)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
            '#F8F9FA')
          .borderRadius(16)
          .onClick(() => {
            this.onSuggestionClick(item.desc);
          })
        })
      }
      .padding({ left: 16, right: 16, bottom: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }
}
