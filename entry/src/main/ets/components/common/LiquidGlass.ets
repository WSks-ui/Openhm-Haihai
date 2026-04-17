import { ConfigurationConstant } from '@kit.AbilityKit';
import { GlobalAnimationManager } from '../../utils/GlobalAnimationManager';
import { ANIM_INSTANT, ANIM_FAST, ANIM_NORMAL, ANIM_PAGE, CURVE_TRANSITION } from '../../constants/ThemeTokens';

export interface GlassOpacityPreset {
  name: string;
  value: number;
  description: string;
}

export const GLASS_OPACITY_PRESETS: GlassOpacityPreset[] = [
  { name: '轻盈', value: 0.2, description: '高度透明，背景清晰可见' },
  { name: '标准', value: 0.4, description: '平衡透明度，推荐使用' },
  { name: '浓郁', value: 0.6, description: '较低透明度，玻璃感更强' }
];

interface ICurve {
  interpolate(fraction: number): number;
}

let glassIdCounter = 0;
function generateGlassId(): string {
  return `LiquidGlass_${glassIdCounter++}_${Date.now()}`;
}

@Component
export struct LiquidGlass {
  @BuilderParam content: () => void;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('glassOpacity') glassOpacity: number = 0.4;

  glassWidth: Length | string = '100%';
  glassHeight: Length | undefined = undefined;
  glassPadding: Padding | Length = 0;
  glassRadius: number | Resource = 24;
  @Prop glassColor: ResourceColor | undefined = undefined;
  blurRadius: number = 40;
  useBlur: boolean = true;
  animCurve: Curve | string | ICurve | object = Curve.Smooth;
  animDuration: number = 300;
  showBorder: boolean = true;

  @State rotateX: number = 0;
  @State rotateY: number = 0;
  @State lightX: string = '50%';
  @State lightY: string = '50%';
  @State scaleValue: number = 1;
  @State componentWidth: number = 0;
  @State componentHeight: number = 0;
  @State isVisible: boolean = true;
  @State isScrolling: boolean = false;

  private glassId: string = generateGlassId();
  private animationManager: GlobalAnimationManager = GlobalAnimationManager.getInstance();
  private animationUnsubscribe: (() => void) | null = null;
  private isInteracting: boolean = false;
  private scrollTimeout: number = -1;

  aboutToAppear() {
    this.animationUnsubscribe = this.animationManager.subscribe(this.glassId, (phase) => {
      if (!this.isInteracting && this.isVisible && !this.isScrolling) {
        const pos = this.animationManager.getEllipsePosition(0, 20, 20);
        this.lightX = pos.x;
        this.lightY = pos.y;
      }
    });
  }

  aboutToDisappear() {
    if (this.animationUnsubscribe) {
      this.animationUnsubscribe();
      this.animationUnsubscribe = null;
    }
    if (this.scrollTimeout !== -1) {
      clearTimeout(this.scrollTimeout);
    }
  }

  private notifyScrollStart() {
    this.isScrolling = true;
    this.animationManager.setVisible(this.glassId, false);
    if (this.scrollTimeout !== -1) {
      clearTimeout(this.scrollTimeout);
    }
  }

  private notifyScrollEnd() {
    if (this.scrollTimeout !== -1) {
      clearTimeout(this.scrollTimeout);
    }
    this.scrollTimeout = setTimeout(() => {
      this.isScrolling = false;
      this.animationManager.setVisible(this.glassId, this.isVisible);
    }, 150);
  }

  build() {
    Stack() {
      this.content()
    }
    .width(this.glassWidth)
    .height(this.glassHeight)
    .padding(this.glassPadding)
    .borderRadius(this.glassRadius)
    .backgroundColor(this.glassColor ?? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? 'rgba(255, 255, 255, 0.05)'
      : 'rgba(255, 255, 255, 0.4)'))
    .backdropBlur(this.useBlur && !this.isScrolling ? this.blurRadius : 0)
    .radialGradient({
      center: [this.lightX, this.lightY],
      radius: '120%',
      colors: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? [
        ['rgba(255, 255, 255, 0.15)', 0.0],
        ['rgba(255, 255, 255, 0.0)', 0.6]
      ] : [
        ['rgba(255, 255, 255, 0.7)', 0.0],
        ['rgba(255, 255, 255, 0.0)', 0.6]
      ]
    })
    .border(this.showBorder ? {
      width: 1,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        ? 'rgba(255, 255, 255, 0.15)'
        : 'rgba(255, 255, 255, 0.6)'
    } : undefined)
    .rotate({ x: 1, y: 0, z: 0, angle: this.rotateX })
    .rotate({ x: 0, y: 1, z: 0, angle: this.rotateY })
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .shadow({
      radius: 30,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)',
      offsetY: 10
    })
    .onAreaChange((oldArea, newArea) => {
      this.componentWidth = Number(newArea.width);
      this.componentHeight = Number(newArea.height);
    })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      this.isVisible = isVisible;
      this.animationManager.setVisible(this.glassId, isVisible);
    })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.isInteracting = true;
        const x = event.touches[0].x;
        const y = event.touches[0].y;

        animateTo({ curve: CURVE_TRANSITION, duration: ANIM_FAST }, () => {
          this.scaleValue = 0.98;
        });

        animateTo({ curve: CURVE_TRANSITION, duration: ANIM_NORMAL }, () => {
          this.lightX = `${x}px`;
          this.lightY = `${y}px`;
        });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isInteracting = false;
        animateTo({ curve: CURVE_TRANSITION, duration: ANIM_PAGE }, () => {
          this.scaleValue = 1;
          this.rotateX = 0;
          this.rotateY = 0;
        });
      } else if (event.type === TouchType.Move) {
        const x = event.touches[0].x;
        const y = event.touches[0].y;

        if (this.componentWidth > 0 && this.componentHeight > 0) {
          const centerX = this.componentWidth / 2;
          const centerY = this.componentHeight / 2;

          const normX = (x - centerX) / centerX;
          const normY = (y - centerY) / centerY;

          const newRotateX = -Math.max(-1, Math.min(1, normY)) * 5;
          const newRotateY = Math.max(-1, Math.min(1, normX)) * 5;

          animateTo({ curve: CURVE_TRANSITION, duration: ANIM_NORMAL }, () => {
            this.rotateX = newRotateX;
            this.rotateY = newRotateY;
          });

          animateTo({ curve: CURVE_TRANSITION, duration: ANIM_NORMAL }, () => {
            this.lightX = `${x}px`;
            this.lightY = `${y}px`;
          });
        }
      }
    })
  }
}
