import { ConfigurationConstant } from '@kit.AbilityKit';
import { GlobalAnimationManager } from '../../utils/GlobalAnimationManager';

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

// 生成唯一ID
let glassIdCounter = 0;
function generateGlassId(): string {
  return `LiquidGlass_${glassIdCounter++}_${Date.now()}`;
}

@Component
export struct LiquidGlass {
  @BuilderParam content: () => void;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('glassOpacity') glassOpacity: number = 0.4;

  // 布局属性
  glassWidth: Length | string = '100%';
  glassHeight: Length | undefined = undefined;
  glassPadding: Padding | Length = 0;
  glassRadius: number | Resource = 24;
  @Prop glassColor: ResourceColor | undefined = undefined;
  blurRadius: number = 40;
  animCurve: Curve | string | ICurve | object = Curve.Smooth;
  animDuration: number = 300;
  showBorder: boolean = true;

  // 交互状态
    @State rotateX: number = 0;
    @State rotateY: number = 0;
    @State lightX: string = '50%';
    @State lightY: string = '50%';
    @State scaleValue: number = 1;
    @State componentWidth: number = 0;
    @State componentHeight: number = 0;

    // 使用全局动画管理器
    private glassId: string = generateGlassId();
    private animationManager: GlobalAnimationManager = GlobalAnimationManager.getInstance();
    private animationUnsubscribe: (() => void) | null = null;
    private isInteracting: boolean = false;

  aboutToAppear() {
    // 订阅全局动画管理器
    this.animationUnsubscribe = this.animationManager.subscribe(this.glassId, (phase) => {
      if (!this.isInteracting) {
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
  }

  build() {
    Stack() {
      this.content()
    }
    .width(this.glassWidth)
    .height(this.glassHeight) // 应用高度属性 (undefined 时自适应)
    .padding(this.glassPadding)
    .borderRadius(this.glassRadius)
    // 1. 玻璃基底 (Frosted Base)
    .backgroundColor(this.glassColor ?? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
      ? 'rgba(255, 255, 255, 0.05)' 
      : 'rgba(255, 255, 255, 0.4)')) // 优先使用自定义颜色，否则使用默认逻辑
    .backdropBlur(this.blurRadius) // 使用自定义模糊半径
    
    // 2. 动态光源 (Specular Highlight / Refraction)
    // 使用径向渐变模拟光源，跟随手指或自动漂浮
    .radialGradient({
      center: [this.lightX, this.lightY],
      radius: '120%', // 较大的光晕
      colors: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? [
        ['rgba(255, 255, 255, 0.15)', 0.0], // 中心高光
        ['rgba(255, 255, 255, 0.0)', 0.6]  // 边缘消散
      ] : [
        ['rgba(255, 255, 255, 0.7)', 0.0], // 强高光
        ['rgba(255, 255, 255, 0.0)', 0.6]
      ]
    })
    
    // 3. 玻璃边缘光 (Rim Light)
    .border(this.showBorder ? { 
      width: 1, 
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK 
        ? 'rgba(255, 255, 255, 0.15)' 
        : 'rgba(255, 255, 255, 0.6)' 
    } : undefined)
    
    // 4. 3D 物理反馈 (Tilt & Scale)
    .rotate({ x: 1, y: 0, z: 0, angle: this.rotateX })
    .rotate({ x: 0, y: 1, z: 0, angle: this.rotateY })
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .shadow({ 
      radius: 30, 
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)', 
      offsetY: 10 
    })
    
    // 5. 交互逻辑
    .onAreaChange((oldArea, newArea) => {
      this.componentWidth = Number(newArea.width);
      this.componentHeight = Number(newArea.height);
    })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.isInteracting = true;
        const x = event.touches[0].x;
        const y = event.touches[0].y;

        animateTo({ curve: Curve.FastOutSlowIn, duration: 200 }, () => {
           this.scaleValue = 0.98;
        });

        animateTo({ curve: Curve.FastOutSlowIn, duration: 300 }, () => {
          this.lightX = `${x}px`;
          this.lightY = `${y}px`;
        });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
         this.isInteracting = false;
         // 光源位置会在下一次动画回调中自动更新为椭圆轨迹
         animateTo({ curve: Curve.FastOutSlowIn, duration: 500 }, () => {
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

           animateTo({ curve: Curve.FastOutSlowIn, duration: 300 }, () => {
             this.rotateX = newRotateX;
             this.rotateY = newRotateY;
           });

           animateTo({ curve: Curve.FastOutSlowIn, duration: 300 }, () => {
             this.lightX = `${x}px`;
             this.lightY = `${y}px`;
           });
         }
      }
    })
  }
}
