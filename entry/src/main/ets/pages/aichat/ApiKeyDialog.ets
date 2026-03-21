import { ConfigurationConstant } from '@kit.AbilityKit';
import { LiquidGlass } from '../../components/common/LiquidGlass';

@CustomDialog
export struct ApiKeyDialog {
  @Link tempApiKey: string;
  @Link tempTavilyKey: string;
  controller: CustomDialogController;
  onCancel: () => void = () => {};
  onSave: (key: string, tavilyKey: string) => void = (key: string, tavilyKey: string) => {};
  onDelete: () => void = () => {};
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  DeleteMenu() {
    Menu() {
      MenuItem({ content: '删除 API Key' })
        .contentFontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' :
          '#F53F3F')
        .onClick(() => {
          this.onDelete();
          this.controller.close();
        })
    }
  }

  build() {
    Column() {
      LiquidGlass({
        glassWidth: '100%',
        glassPadding: 24,
        glassRadius: 24
      }) {
        Column() {
          Row() {
            Text('设置 API 密钥')
              .fontSize(18)
              .fontWeight(600)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            Blank()

            if (this.tempApiKey) {
              SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                .fontSize(20)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129'])
                .bindMenu(this.DeleteMenu())
            }
          }
          .width('100%')
          .margin({ bottom: 20 })
          .alignItems(VerticalAlign.Center)

          this.DeepSeekKeyInput()
          this.TavilyKeyInput()

          Text('试用测试 Key')
            .fontSize(14)
            .fontColor('#165DFF')
            .margin({ top: 12 })
            .alignSelf(ItemAlign.End)
            .onClick(() => {
              this.onSave('sk-7e10c498229248a1a71b41e02c57267e', this.tempTavilyKey);
              this.controller.close();
            })

          this.ActionButtons()
        }
      }
    }
    .width('90%')
    .constraintSize({ maxWidth: 480 })
    .backgroundColor(Color.Transparent)
  }

  @Builder
  DeepSeekKeyInput() {
    Column({ space: 8 }) {
      Text('DeepSeek API Key')
        .fontSize(14)
        .fontWeight(500)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

      TextInput({ placeholder: '请输入 DeepSeek Key (sk-...)', text: $$this.tempApiKey })
        .type(InputType.Normal)
        .height(44)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          'rgba(255, 255, 255, 0.1)' : 'rgba(242, 243, 245, 0.2)')
        .borderRadius(6)
        .border({
          width: 1,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.2)' :
            'rgba(229, 230, 235, 0.5)'
        })
        .padding({ left: 12, right: 12 })
        .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#86909C')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  TavilyKeyInput() {
    Column({ space: 8 }) {
      Text('Tavily API Key (可选)')
        .fontSize(14)
        .fontWeight(500)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

      TextInput({ placeholder: '请输入 Tavily Key (tvly-...)', text: $$this.tempTavilyKey })
        .type(InputType.Normal)
        .height(44)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          'rgba(255, 255, 255, 0.1)' : 'rgba(242, 243, 245, 0.2)')
        .borderRadius(6)
        .border({
          width: 1,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.2)' :
            'rgba(229, 230, 235, 0.5)'
        })
        .padding({ left: 12, right: 12 })
        .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#86909C')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 16 })
  }

  @Builder
  ActionButtons() {
    Row({ space: 12 }) {
      Button('取消')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          'rgba(255, 255, 255, 0.15)' : 'rgba(242, 243, 245, 0.4)')
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
        .fontSize(14)
        .height(36)
        .onClick(() => {
          this.onCancel();
          this.controller.close();
        })
        .layoutWeight(1)

      Button('保存并使用')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#165DFF')
        .fontColor(Color.White)
        .fontSize(14)
        .height(36)
        .shadow({ radius: 8, color: 'rgba(22, 93, 255, 0.3)', offsetY: 2 })
        .onClick(() => {
          this.onSave(this.tempApiKey, this.tempTavilyKey);
          this.controller.close();
        })
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 32 })
  }
}
