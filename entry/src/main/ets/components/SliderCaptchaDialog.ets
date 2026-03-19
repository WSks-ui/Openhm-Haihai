import { SliderCaptcha } from './SliderCaptcha';

@CustomDialog
export struct SliderCaptchaDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: () => {},
    cancel: () => {},
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    customStyle: true
  });

  onVerifySuccess?: () => void;
  onVerifyFailed?: () => void;
  onClose?: () => void;

  build() {
    Column() {
      Column() {
        Text('安全验证')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ top: 20, bottom: 16 });

        SliderCaptcha({
          onVerifySuccess: () => {
            if (this.onVerifySuccess) {
              this.onVerifySuccess();
            }
            this.controller.close();
          },
          onVerifyFailed: () => {
            if (this.onVerifyFailed) {
              this.onVerifyFailed();
            }
          }
        })
        .margin({ left: 20, right: 20, bottom: 20 });

        Button('关闭')
          .width('80%')
          .height(44)
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 20 })
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
            this.controller.close();
          });
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .backdropBlur(10)
    .justifyContent(FlexAlign.Center)
  }
}
