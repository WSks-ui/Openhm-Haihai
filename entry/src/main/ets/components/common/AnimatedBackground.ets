import { ConfigurationConstant } from '@kit.AbilityKit';
import { GlobalAnimationManager } from '../../utils/GlobalAnimationManager';

// 生成唯一ID
let bgIdCounter = 0;
function generateBgId(): string {
  return `AnimatedBackground_${bgIdCounter++}_${Date.now()}`;
}

@Component
export struct AnimatedBackground {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @BuilderParam content: () => void;

  @State lightX: string = '50%';
  @State lightY: string = '50%';

  private bgId: string = generateBgId();
  private animationManager: GlobalAnimationManager = GlobalAnimationManager.getInstance();
  private animationUnsubscribe: (() => void) | null = null;

  aboutToAppear() {
    // 订阅全局动画管理器
    this.animationUnsubscribe = this.animationManager.subscribe(this.bgId, (phase) => {
      const pos = this.animationManager.getLissajousPosition(0, 30, 30);
      this.lightX = pos.x;
      this.lightY = pos.y;
    });
  }

  aboutToDisappear() {
    if (this.animationUnsubscribe) {
      this.animationUnsubscribe();
      this.animationUnsubscribe = null;
    }
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
