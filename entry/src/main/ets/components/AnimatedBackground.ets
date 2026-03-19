import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct AnimatedBackground {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @BuilderParam content: () => void;

  @State lightX: string = '50%';
  @State lightY: string = '50%';
  private bgTimer: number = -1;
  private bgPhase: number = 0;

  aboutToAppear() {
    this.bgTimer = setInterval(() => {
      this.bgPhase += 0.02;
      const x = 50 + Math.sin(this.bgPhase) * 30;
      const y = 50 + Math.cos(this.bgPhase * 0.8) * 30;
      this.lightX = `${x}%`;
      this.lightY = `${y}%`;
    }, 50);
  }

  aboutToDisappear() {
    clearInterval(this.bgTimer);
  }

  build() {
    Stack() {
      this.content()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
    .radialGradient({
      center: [this.lightX, this.lightY],
      radius: '150%',
      colors: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? [
        ['rgba(123, 104, 238, 0.4)', 0.0],
        ['rgba(72, 61, 139, 0.2)', 0.4],
        ['rgba(0, 0, 0, 1.0)', 1.0]
      ] : [
        ['rgba(123, 104, 238, 0.3)', 0.0],
        ['rgba(255, 182, 193, 0.3)', 0.3],
        ['rgba(173, 216, 230, 0.2)', 0.6],
        ['rgba(255, 255, 255, 1.0)', 1.0]
      ]
    })
    .animation({
      duration: 1000,
      curve: Curve.Linear
    })
  }
}
