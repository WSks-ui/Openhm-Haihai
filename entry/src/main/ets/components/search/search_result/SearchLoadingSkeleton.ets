import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct SearchLoadingSkeleton {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State shimmerOffset: number = 0;
  @State isVisible: boolean = true;
  private shimmerTimer: number = -1;

  aboutToAppear() {
    this.shimmerTimer = setInterval(() => {
      if (this.isVisible) {
        this.shimmerOffset = (this.shimmerOffset + 2) % 100;
      }
    }, 50);
  }

  aboutToDisappear() {
    clearInterval(this.shimmerTimer);
  }

  @Builder
  SkeletonCard() {
    Column() {
      Row()
        .width('100%')
        .height(120)
        .borderRadius({ topLeft: 8, topRight: 8 })
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
      
      Column() {
        Row()
          .width('80%')
          .height(16)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
          .margin({ bottom: 8 })
        
        Row()
          .width('100%')
          .height(12)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
          .margin({ bottom: 4 })
        
        Row()
          .width('60%')
          .height(12)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
          .margin({ bottom: 12 })
        
        Row() {
          Row() {
            Row()
              .width(16)
              .height(16)
              .borderRadius(8)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
              .margin({ right: 4 })
            Row()
              .width(60)
              .height(10)
              .borderRadius(4)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
          }
          .layoutWeight(1)
          
          Row() {
            Row()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
              .margin({ right: 4 })
            Row()
              .width(30)
              .height(10)
              .borderRadius(4)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
          }
        }
        .width('100%')
      }
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(8)
    .shadow({ 
      radius: 4, 
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)', 
      offsetY: 2 
    })
  }

  @Builder
  KeplerSkeleton() {
    Column() {
      Row() {
        Text('#')
          .fontSize(18)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#3A3A3A' : '#CCCCCC')
          .fontWeight(FontWeight.Bold)
          .margin({ right: 4 })
        
        Row()
          .width(100)
          .height(18)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E0E0E0')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.1)' : 'rgba(123, 104, 238, 0.08)')
      .borderRadius(16)
      .margin({ bottom: 24 })
      
      Row()
        .width(40)
        .height(4)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#3A3A3A' : '#CCCCCC')
        .borderRadius(2)
        .margin({ bottom: 24 })
      
      Column({ space: 12 }) {
        Row()
          .width('100%')
          .height(14)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
        
        Row()
          .width('90%')
          .height(14)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
        
        Row()
          .width('95%')
          .height(14)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
        
        Row()
          .width('70%')
          .height(14)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
      .margin({ bottom: 32 })
      
      Row() {
        Row()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
          .margin({ right: 8 })
        
        Row()
          .width(80)
          .height(10)
          .borderRadius(4)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
      }
      .padding({ left: 10, right: 14, top: 6, bottom: 6 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)')
      .borderRadius(20)
    }
    .width('100%')
    .padding(24)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.8)')
    .backdropBlur(20)
    .borderRadius(24)
  }

  @Builder
  UserSkeleton() {
    Column() {
      ForEach([1, 2, 3, 4, 5, 6], (_: number, index: number) => {
        Column() {
          Row() {
            Row()
              .width(48)
              .height(48)
              .borderRadius(24)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
            
            Column() {
              Row()
                .width(100)
                .height(14)
                .borderRadius(4)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2A2A2A' : '#E8E8E8')
                .margin({ bottom: 6 })
              
              Row()
                .width(60)
                .height(10)
                .borderRadius(4)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333333' : '#D0D0D0')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            
            Blank()
            
            Row()
              .width(60)
              .height(28)
              .borderRadius(14)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#3A3A3A' : '#E0E0E0')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(12)
        }
        .margin({ bottom: 12 })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8 })
  }

  build() {
    Scroll() {
      Column() {
        Blank().height(60)
        
        if (this.selectedCategoryIndex === 2) {
          GridRow({
            columns: { sm: 4, md: 8, lg: 12 },
            gutter: 24
          }) {
            GridCol({
              span: { sm: 4, md: 6, lg: 8 },
              offset: { sm: 0, md: 1, lg: 2 }
            }) {
              this.KeplerSkeleton()
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
        } else if (this.selectedCategoryIndex === 1) {
          this.UserSkeleton()
        } else {
          WaterFlow() {
            ForEach([1, 2, 3, 4, 5, 6], (_: number, index: number) => {
              FlowItem() {
                this.SkeletonCard()
              }
            })
          }
          .columnsTemplate(this.currentBreakpoint === 'xl' ? "1fr 1fr 1fr 1fr" :
                          (this.currentBreakpoint === 'lg' ? "1fr 1fr 1fr 1fr" :
                          (this.currentBreakpoint === 'md' ? "1fr 1fr 1fr" : "1fr 1fr")))
          .columnsGap(12)
          .rowsGap(12)
          .padding({ left: 12, right: 12, bottom: 20 })
          .layoutWeight(1)
          .constraintSize({ maxWidth: ['lg', 'xl'].includes(this.currentBreakpoint) ? 1200 : '100%' })
        }
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F5F5F5')
  }

  @Prop selectedCategoryIndex: number = 0;
}
