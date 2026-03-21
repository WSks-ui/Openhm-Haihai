import { Post } from '../../../model/Post';
import { LiquidGlass } from '../../common/LiquidGlass';
import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';

@Component
export struct KeplerResultView {
  @Prop post: Post;
  @Prop keyword: string;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State scrollY: number = 0;
  
  @State isRegenerating: boolean = false;
  @State copySuccess: boolean = false;
  
  // 背景动画相关状态
  @State lightX: string = '50%';
  @State lightY: string = '50%';
  private bgTimer: number = -1;
  private bgPhase: number = 0;
  
  onRegenerate: () => void = () => {};

  aboutToAppear() {
    // 启动背景流光动画
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

  async copyToClipboard() {
    if (!this.post || !this.post.content) {
      promptAction.showToast({ message: '复制失败：内容为空' });
      return;
    }

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createPlainTextData(this.post.content);
      await systemPasteboard.setData(pasteData);
      
      this.copySuccess = true;
      promptAction.showToast({ message: '已复制到剪贴板' });
      
      setTimeout(() => {
        this.copySuccess = false;
      }, 2000);
    } catch (err) {
      promptAction.showToast({ message: '复制失败，请重试' });
    }
  }

  async handleRegenerate() {
    if (this.isRegenerating) {
      return;
    }

    this.isRegenerating = true;
    
    try {
      await this.onRegenerate();
    } catch (err) {
      promptAction.showToast({ message: '重新生成失败，请检查网络连接' });
    } finally {
      this.isRegenerating = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 标题栏 (悬浮) - 使用 GridRow 实现响应式布局，遵循一多开发规范
      GridRow({
        columns: { sm: 4, md: 8, lg: 12 },
        gutter: 24
      }) {
        GridCol({
          span: { sm: 4, md: 6, lg: 8 },
          offset: { sm: 0, md: 1, lg: 2 }
        }) {
          Row() {
            Column() {
              LiquidGlass({
                glassWidth: 'auto', // 自适应宽度
                glassPadding: { left: 24, right: 24, top: 12, bottom: 12 },
                glassRadius: 32
              }) {
                Row() {
                  Column() {
                    Text('Kepler')
                      .fontSize(14)
                      .fontColor('#7B68EE')
                      .fontWeight(FontWeight.Bold)
                      .letterSpacing(1)
                      .shadow({ radius: 2, color: 'rgba(123, 104, 238, 0.3)', offsetY: 1 })

                    Text('智能总结')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
                      .margin({ top: 2 })
                      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)

                  Image($r('app.media.icon_ai'))
                    .width(28)
                    .height(28)
                    .fillColor('#7B68EE')
                    .borderRadius(14)
                    .padding(4)
                    .margin({ left: 16 })
                }
                .alignItems(VerticalAlign.Center)
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 48 }) // 统一的外部间距
      .zIndex(10)
      .hitTestBehavior(HitTestMode.Transparent)
      .opacity(Math.max(0, 1 - this.scrollY / 100))
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .visibility(this.scrollY > 100 ? Visibility.Hidden : Visibility.Visible)

      Scroll() {
        Column() {
          Blank().height(130)

          // 主内容区 - 使用 GridRow 实现响应式布局
          GridRow({
            columns: { sm: 4, md: 8, lg: 12 },
            gutter: 24
          }) {
            GridCol({
              span: { sm: 4, md: 6, lg: 8 },
              offset: { sm: 0, md: 1, lg: 2 }
            }) {
              LiquidGlass({
                glassWidth: '100%', // 填满 GridCol
                glassPadding: 24,
                glassRadius: 24
              }) {
                Column() {
                  // 关键词标签
                  Row() {
                    Text('#')
                      .fontSize(18)
                      .fontColor('#7B68EE')
                      .fontWeight(FontWeight.Bold)
                      .margin({ right: 4 })
                      .shadow({ radius: 2, color: 'rgba(123, 104, 238, 0.4)', offsetY: 0 })
                    
                    Text(this.keyword)
                      .fontSize(18)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
                      .fontWeight(FontWeight.Medium)
                      .shadow({ radius: 1, color: 'rgba(0,0,0,0.1)', offsetY: 1 })
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                  .backgroundColor('rgba(123, 104, 238, 0.15)')
                  .borderRadius(16)
                  .border({ width: 1, color: 'rgba(123, 104, 238, 0.3)' })
                  .margin({ bottom: 24 })
                  .backdropBlur(10)

                  // 装饰线条
                  Row()
                    .width(40)
                    .height(4)
                    .backgroundColor('#7B68EE')
                    .borderRadius(2)
                    .margin({ bottom: 24 })
                    .shadow({ radius: 4, color: 'rgba(123, 104, 238, 0.5)', offsetY: 1 })

                  // 正文内容
                  Text(this.post.content)
                    .fontSize(16)
                    .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#444')
                    .lineHeight(32)
                    .fontWeight(FontWeight.Regular)
                    .textAlign(TextAlign.Start)
                    .width('100%')
                    .padding({ left: 8, right: 8 })
                    .margin({ bottom: 32 })

                  // 底部作者信息
                  Row() {
                    Image($r('app.media.icon_ai'))
                      .width(20)
                      .height(20)
                      .borderRadius(10)
                      .margin({ right: 8 })
                      .fillColor('#7B68EE')
                      .opacity(0.8)
                    
                    Text(`由 Kepler 生成`)
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#888')
                  }
                  .padding({ left: 10, right: 14, top: 6, bottom: 6 })
                  .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
                  .borderRadius(20)
                  .alignSelf(ItemAlign.Start)
                }
                .width('100%')
              }
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12 }) // 统一的外部间距

          // 底部操作区 - 同样遵循 Grid 布局
          GridRow({
            columns: { sm: 4, md: 8, lg: 12 },
            gutter: 24
          }) {
            GridCol({
              span: { sm: 4, md: 6, lg: 8 },
              offset: { sm: 0, md: 1, lg: 2 }
            }) {
              LiquidGlass({
                 glassWidth: '100%',
                 glassPadding: { top: 16, bottom: 16, left: 20, right: 20 },
                 glassRadius: 24
              }) {
                Row() {
                   // 重新生成按钮
                   Button({ type: ButtonType.Normal, stateEffect: true }) {
                     Column() {
                       if (this.isRegenerating) {
                         LoadingProgress()
                           .width(20)
                           .height(20)
                           .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
                           .margin({ bottom: 4 })
                       } else {
                         Image($r('app.media.icon_refresh')) 
                           .width(20)
                           .height(20)
                           .fillColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
                           .margin({ bottom: 4 })
                       }
                       Text(this.isRegenerating ? '生成中...' : '重新生成')
                         .fontSize(12)
                         .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
                     }
                     .width('100%')
                     .alignItems(HorizontalAlign.Center)
                   }
                   .backgroundColor('rgba(255,255,255,0.0)')
                   .layoutWeight(1)
                   .enabled(!this.isRegenerating)
                   .onClick(() => {
                      this.handleRegenerate();
                   })

                   // 分割线
                   Divider()
                     .vertical(true)
                     .height(24)
                     .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.1)')

                   // 复制结果按钮
                   Button({ type: ButtonType.Normal, stateEffect: true }) {
                     Column() {
                       if (this.copySuccess) {
                         Image($r('app.media.icon_check')) 
                           .width(20)
                           .height(20)
                           .fillColor('#4CAF50')
                           .margin({ bottom: 4 })
                       } else {
                         Image($r('app.media.icon_my_copy')) 
                           .width(20)
                           .height(20)
                           .fillColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
                           .margin({ bottom: 4 })
                       }
                       Text(this.copySuccess ? '已复制' : '复制结果')
                         .fontSize(12)
                         .fontColor(this.copySuccess ? '#4CAF50' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666'))
                     }
                     .width('100%')
                     .alignItems(HorizontalAlign.Center)
                   }
                   .backgroundColor('rgba(255,255,255,0.0)')
                   .layoutWeight(1)
                   .onClick(() => {
                      this.copyToClipboard();
                   })
                }
                .width('100%')
              }
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .margin({ top: 20, bottom: 40 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .onScroll((xOffset: number, yOffset: number) => {
        this.scrollY += yOffset;
      })
    }
    .width('100%')
    .layoutWeight(1)
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
