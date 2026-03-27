import { ConfigurationConstant } from '@kit.AbilityKit';
import { GLASS_OPACITY_PRESETS, GlassOpacityPreset } from '../common/LiquidGlass';

@Component
export struct LiquidGlassSettingsPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('glassOpacity') glassOpacity: number = 0.4;

  @State selectedPresetIndex: number = 1;
  @State previewOpacity: number = 0.4;

  aboutToAppear() {
    this.previewOpacity = this.glassOpacity;
    this.selectedPresetIndex = GLASS_OPACITY_PRESETS.findIndex(p => p.value === this.glassOpacity);
    if (this.selectedPresetIndex < 0) {
      this.selectedPresetIndex = 1;
    }
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

  build() {
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
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .padding({ bottom: 32 })
    }
    .layoutWeight(1)
  }
}
