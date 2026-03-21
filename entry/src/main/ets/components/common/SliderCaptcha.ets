interface SliderCaptchaResult {
  success: boolean;
  message: string;
}

@Component
export struct SliderCaptcha {
  @State sliderPosition: number = 0;
  @State isDragging: boolean = false;
  @State isVerified: boolean = false;
  @State containerWidth: number = 300;

  private SLIDER_SIZE: number = 50;
  private lastX: number = 0;

  onVerifySuccess?: () => void;
  onVerifyFailed?: () => void;

  reset(): void {
    this.sliderPosition = 0;
    this.isDragging = false;
    this.isVerified = false;
    this.lastX = 0;
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Start }) {
        Row() {
          Text(this.isVerified ? '验证成功 ✓' : '请向右滑动完成验证')
            .fontSize(14)
            .fontColor(this.isVerified ? '#52C41A' : '#999')
        }
        .width('100%')
        .height(this.SLIDER_SIZE)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isVerified ? '#F6FFED' : '#F5F5F5')
        .borderRadius(4)

        Stack({ alignContent: Alignment.Start }) {
          Column()
            .width(this.sliderPosition)
            .height(this.SLIDER_SIZE)
            .backgroundColor(this.isVerified ? '#52C41A' : '#7B68EE')
            .borderRadius(4)

          Row() {
            if (this.isVerified) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(24)
                .fontColor(['#FFF'])
            } else {
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(20)
                .fontColor([this.isDragging ? '#7B68EE' : '#CCC'])
            }
          }
          .width(this.SLIDER_SIZE)
          .height(this.SLIDER_SIZE)
          .backgroundColor(this.isVerified ? '#52C41A' : '#FFF')
          .border({
            width: 1,
            color: this.isVerified ? '#52C41A' : '#DDD'
          })
          .borderRadius(4)
          .justifyContent(FlexAlign.Center)
          .shadow({
            radius: this.isDragging ? 10 : 0,
            color: this.isDragging ? 'rgba(0, 0, 0, 0.2)' : 'transparent',
            offsetX: 0,
            offsetY: this.isDragging ? 5 : 0
          })
          .position({ x: this.sliderPosition, y: 0 })
          .onTouch((event: TouchEvent) => {
            if (this.isVerified) return;
            
            if (event.type === TouchType.Down) {
              this.isDragging = true;
              this.lastX = event.touches[0].x;
            } else if (event.type === TouchType.Move) {
              if (!this.isDragging) return;
              
              const maxWidth = this.containerWidth - this.SLIDER_SIZE;
              const currentX = event.touches[0].x;
              const deltaX = currentX - this.lastX;
              let newPosition = this.sliderPosition + deltaX;
              
              if (newPosition < 0) {
                newPosition = 0;
              } else if (newPosition > maxWidth) {
                newPosition = maxWidth;
              }
              
              this.sliderPosition = newPosition;
              this.lastX = currentX;
            } else if (event.type === TouchType.Up) {
              if (!this.isDragging) return;
              this.isDragging = false;
              
              const maxWidth = this.containerWidth - this.SLIDER_SIZE;
              const tolerance = 10;
              
              if (Math.abs(this.sliderPosition - maxWidth) <= tolerance) {
                this.sliderPosition = maxWidth;
                this.isVerified = true;
                if (this.onVerifySuccess) {
                  this.onVerifySuccess();
                }
              } else {
                if (this.onVerifyFailed) {
                  this.onVerifyFailed();
                }
                this.reset();
              }
            }
          })
        }
        .width('100%')
        .height(this.SLIDER_SIZE)
      }
      .width('100%')
      .height(this.SLIDER_SIZE)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        this.containerWidth = Number(newArea.width);
      })
    }
    .width('100%')
  }
}
