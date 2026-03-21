import { ConfigurationConstant } from '@kit.AbilityKit';

interface ThemeColors {
  textColor: string;
  subTextColor: string;
}

@CustomDialog
export struct AgreementDialog {
  @State scaleValue: number = 0.8;
  @State opacityValue: number = 0;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  controller: CustomDialogController;
  title: string = '';
  content: string = '';

  aboutToAppear() {
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.scaleValue = 1;
      this.opacityValue = 1;
    });
  }

  private getThemeColors(): ThemeColors {
    const isDark = this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    return {
      textColor: isDark ? '#FFFFFF' : '#1A1A1E',
      subTextColor: isDark ? '#A0A0A0' : '#666666'
    };
  }

  private closeDialog() {
    animateTo({
      duration: 200,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.scaleValue = 0.8;
      this.opacityValue = 0;
    });
    setTimeout(() => {
      this.controller.close();
    }, 200);
  }

  build() {
    Stack() {
      Column() {
        Blank();

        Stack() {
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.chevron_left'))
                .fontSize(24)
                .fontColor([this.getThemeColors().subTextColor])
                .onClick(() => {
                  this.closeDialog();
                })

              Text(this.title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getThemeColors().textColor)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Blank()
                .width(24)
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })

            Scroll() {
              Text(this.content)
                .fontSize(14)
                .fontColor(this.getThemeColors().subTextColor)
                .width('100%')
                .lineHeight(24)
                .padding({ left: 20, right: 20, top: 16, bottom: 32 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            .height('100%')
            .constraintSize({ maxHeight: '80%' })
          }
          .width('100%')
        }
        .width('90%')
        .borderRadius(24)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
          ? 'rgba(30, 30, 35, 0.95)' 
          : 'rgba(255, 255, 255, 0.95)')
        .backdropBlur(20)
        .border({
          width: 1,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
            ? 'rgba(255, 255, 255, 0.1)' 
            : 'rgba(0, 0, 0, 0.1)'
        })
        .shadow({
          radius: 30,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
            ? 'rgba(0, 0, 0, 0.4)' 
            : 'rgba(0, 0, 0, 0.15)',
          offsetY: 10
        })
        .opacity(this.opacityValue)
        .scale({ x: this.scaleValue, y: this.scaleValue })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.6)')
    .onClick(() => {
      this.closeDialog();
    })
  }
}
