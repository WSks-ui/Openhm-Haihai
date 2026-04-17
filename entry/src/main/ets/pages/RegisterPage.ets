import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import display from '@ohos.display';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { UserManager, CheckResult } from '../model/UserModel';
import { VerifyCodeManager, VerifyResult, SendCodeResult } from '../utils/VerifyCodeManager';
import { SliderCaptchaDialog } from '../components/dialogs/SliderCaptchaDialog';
import { LiquidGlass } from '../components/common/LiquidGlass';
import { AnimatedBackground } from '../components/common/AnimatedBackground';

interface ThemeColors {
  bgColor: string;
  textColor: string;
  subTextColor: string;
  inputBg: string;
  inputBorder: string;
  cardBg: string;
  cardBorder: string;
  glassColor: string;
}

@Entry
@Component
struct RegisterPage {
  @State phoneNumber: string = '';
  @State nickname: string = '';
  @State customUid: string = '';
  @State verifyCode: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';

  @State phoneValid: boolean = false;
  @State phoneCheckResult: CheckResult = { isValid: false, message: '' };

  @State nicknameValid: boolean = false;
  @State nicknameCheckResult: CheckResult = { isValid: false, message: '' };

  @State uidValid: boolean = true;
  @State uidCheckResult: CheckResult = { isValid: true, message: '' };

  @State passwordValid: boolean = false;
  @State passwordCheckResult: CheckResult = { isValid: false, message: '' };

  @State confirmPasswordValid: boolean = false;
  @State confirmPasswordCheckResult: CheckResult = { isValid: false, message: '' };

  @State isSliderVerified: boolean = false;
  @State isSendingCode: boolean = false;
  @State countdown: number = 0;
  @State isRegistering: boolean = false;
  @State screenWidth: number = 0;
  @State isLargeScreen: boolean = false;

  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  private userManager: UserManager = UserManager.getInstance();
  private verifyCodeManager: VerifyCodeManager = VerifyCodeManager.getInstance();
  private sliderCaptchaDialogController: CustomDialogController | null = null;

  async aboutToAppear() {
    try {
      const ctx = getContext(this);
      await this.userManager.init(ctx);
      await this.verifyCodeManager.init(ctx);

      this.screenWidth = px2vp(display.getDefaultDisplaySync().width);
      this.isLargeScreen = this.screenWidth >= 600;
    } catch (error) {
      console.error('初始化失败：' + JSON.stringify(error));
    }
  }

  private async checkPhoneNumber() {
    if (this.phoneNumber.length === 0) {
      this.phoneValid = false;
      this.phoneCheckResult = { isValid: false, message: '' };
      return;
    }

    const result = await this.userManager.checkPhoneNumber(this.phoneNumber);
    this.phoneCheckResult = result;
    this.phoneValid = result.isValid;

    if (result.isValid && (await this.userManager.isPhoneRegistered(this.phoneNumber))) {
      this.phoneValid = false;
      this.phoneCheckResult = { isValid: false, message: '该手机号已注册，请直接登录' };
    }
  }

  private async checkNickname() {
    if (this.nickname.length === 0) {
      this.nicknameValid = false;
      this.nicknameCheckResult = { isValid: false, message: '' };
      return;
    }

    const result = await this.userManager.checkNickname(this.nickname);
    this.nicknameCheckResult = result;
    this.nicknameValid = result.isValid;
  }

  private async checkUID() {
    if (this.customUid.length === 0) {
      this.uidValid = true;
      this.uidCheckResult = { isValid: true, message: '' };
      return;
    }

    const result = await this.userManager.checkUID(this.customUid);
    this.uidCheckResult = result;
    this.uidValid = result.isValid;
  }

  private checkPassword() {
    if (this.password.length === 0) {
      this.passwordValid = false;
      this.passwordCheckResult = { isValid: false, message: '' };
      return;
    }

    const result = this.userManager.checkPassword(this.password);
    this.passwordCheckResult = result;
    this.passwordValid = result.isValid;

    this.checkConfirmPassword();
  }

  private checkConfirmPassword() {
    if (this.confirmPassword.length === 0) {
      this.confirmPasswordValid = false;
      this.confirmPasswordCheckResult = { isValid: false, message: '' };
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.confirmPasswordValid = false;
      this.confirmPasswordCheckResult = { isValid: false, message: '两次输入的密码不一致' };
    } else {
      this.confirmPasswordValid = true;
      this.confirmPasswordCheckResult = { isValid: true, message: '密码匹配' };
    }
  }

  private openSliderCaptchaDialog() {
    this.sliderCaptchaDialogController = new CustomDialogController({
      builder: SliderCaptchaDialog({
        onVerifySuccess: () => {
          this.isSliderVerified = true;
        },
        onVerifyFailed: () => {
          this.isSliderVerified = false;
        },
        onClose: () => {
          this.sliderCaptchaDialogController = null;
        }
      }),
      cancel: () => {
        this.sliderCaptchaDialogController = null;
      },
      autoCancel: true,
      customStyle: true
    });

    this.sliderCaptchaDialogController.open();
  }

  private async sendVerifyCode() {
    if (!this.phoneValid) {
      this.showError(this.phoneCheckResult.message || '请输入正确的手机号');
      return;
    }

    if (this.countdown > 0 || this.isSendingCode) {
      return;
    }

    this.isSendingCode = true;
    const result: SendCodeResult = await this.verifyCodeManager.sendVerifyCode(this.phoneNumber);

    if (result.success) {
      this.showSuccess('验证码已发送');
      this.startCountdown();
    } else {
      this.showError(result.message || '发送验证码失败');
    }
    this.isSendingCode = false;
  }

  private startCountdown() {
    this.countdown = 60;
    const timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(timer);
      }
    }, 1000);
  }

  private async completeRegistration() {
    if (!this.canSubmit()) {
      return;
    }

    this.isRegistering = true;
    try {
      const verifyResult: VerifyResult = await this.verifyCodeManager.verifyCode(this.phoneNumber, this.verifyCode);
      if (!verifyResult.success) {
        this.showError(verifyResult.message);
        this.isRegistering = false;
        return;
      }

      await this.userManager.createUser(this.phoneNumber, this.nickname, this.password, this.customUid || undefined);

      this.showSuccess('注册成功，请登录');

      setTimeout(() => {
        router.replaceUrl({ url: 'pages/LoginPage', params: { phoneNumber: this.phoneNumber } });
      }, 1500);
    } catch (error) {
      this.showError('注册失败：' + (error as Error).message);
    }
    this.isRegistering = false;
  }

  private canSubmit(): boolean {
    return this.phoneValid &&
           this.nicknameValid &&
           this.uidValid &&
           this.passwordValid &&
           this.confirmPasswordValid &&
           this.verifyCode.length >= 4 &&
           this.isSliderVerified &&
           !this.isRegistering;
  }

  private showSuccess(message: string) {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  private showError(message: string) {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  private getThemeColors(): ThemeColors {
    const isDark = this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    return {
      bgColor: isDark ? '#1A1A1E' : '#F5F5F7',
      textColor: isDark ? '#FFFFFF' : '#1A1A1E',
      subTextColor: isDark ? '#A0A0A0' : '#666666',
      inputBg: isDark ? 'rgba(45, 50, 55, 0.85)' : 'rgba(255, 255, 255, 0.9)',
      inputBorder: isDark ? '#2A2A2A' : '#E0E0E0',
      cardBg: isDark ? 'rgba(30, 30, 35, 0.95)' : 'rgba(255, 255, 255, 0.95)',
      cardBorder: isDark ? 'rgba(123, 104, 238, 0.2)' : 'rgba(123, 104, 238, 0.15)',
      glassColor: isDark ? 'rgba(40, 40, 40, 0.6)' : 'rgba(255, 255, 255, 0.7)'
    };
  }

  @Builder headerSection() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(this.isLargeScreen ? 28 : 24)
        .fontColor([this.getThemeColors().subTextColor])
        .onClick(() => {
          router.back();
        });
      Text('注册账号')
        .fontSize(this.isLargeScreen ? 24 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().textColor)
        .margin({ left: this.isLargeScreen ? 16 : 12 });
    }
    .width('100%')
    .height(this.isLargeScreen ? 64 : 56)
    .padding({ left: this.isLargeScreen ? 24 : 16, right: this.isLargeScreen ? 24 : 16 })
    .margin({ top: this.isLargeScreen ? 20 : 0 });
  }

  @Builder scrollContent() {
    Column({ space: this.isLargeScreen ? 24 : 20 }) {
      Text('创建新账号')
        .fontSize(this.isLargeScreen ? 36 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().textColor)
        .width('100%')
        .margin({ top: this.isLargeScreen ? 24 : 20, bottom: this.isLargeScreen ? 12 : 8 });

      Text('手机号快速注册，登录更便捷')
        .fontSize(this.isLargeScreen ? 16 : 14)
        .fontColor(this.getThemeColors().subTextColor)
        .width('100%')
        .margin({ bottom: this.isLargeScreen ? 32 : 24 });

      LiquidGlass({
        glassWidth: this.isLargeScreen ? 520 : '92%',
        glassRadius: 24,
        blurRadius: 30,
        glassPadding: this.isLargeScreen ? 48 : 20,
        glassColor: this.getThemeColors().glassColor
      }) {
        Column({ space: this.isLargeScreen ? 20 : 16 }) {
          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('手机号')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            TextInput({ text: this.phoneNumber, placeholder: '请输入手机号' })
              .type(InputType.PhoneNumber)
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .backgroundColor(this.getThemeColors().inputBg)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
              .fontSize(this.isLargeScreen ? 18 : 16)
              .fontColor(this.getThemeColors().textColor)
              .placeholderColor(this.getThemeColors().subTextColor)
              .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
              .backdropBlur(10)
              .onChange((value: string) => {
                this.phoneNumber = value;
                this.checkPhoneNumber();
              });

            if (this.phoneCheckResult.message) {
              Text(this.phoneCheckResult.message)
                .fontSize(this.isLargeScreen ? 14 : 12)
                .fontColor(this.phoneValid ? '#52C41A' : '#FF4444')
                .width('100%');
            }
          }

          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('昵称')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            TextInput({ text: this.nickname, placeholder: '请输入昵称（2-20个字符）' })
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .backgroundColor(this.getThemeColors().inputBg)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
              .fontSize(this.isLargeScreen ? 18 : 16)
              .fontColor(this.getThemeColors().textColor)
              .placeholderColor(this.getThemeColors().subTextColor)
              .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
              .backdropBlur(10)
              .onChange((value: string) => {
                this.nickname = value;
                this.checkNickname();
              });

            if (this.nicknameCheckResult.message) {
              Text(this.nicknameCheckResult.message)
                .fontSize(this.isLargeScreen ? 14 : 12)
                .fontColor(this.nicknameValid ? '#52C41A' : '#FF4444')
                .width('100%');
            }
          }

          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('UID（可选）')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            TextInput({ text: this.customUid, placeholder: '自定义UID（4-16位字母数字下划线）' })
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .backgroundColor(this.getThemeColors().inputBg)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
              .fontSize(this.isLargeScreen ? 18 : 16)
              .fontColor(this.getThemeColors().textColor)
              .placeholderColor(this.getThemeColors().subTextColor)
              .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
              .backdropBlur(10)
              .onChange((value: string) => {
                this.customUid = value;
                this.checkUID();
              });

            if (this.uidCheckResult.message && this.customUid.length > 0) {
              Text(this.uidCheckResult.message)
                .fontSize(this.isLargeScreen ? 14 : 12)
                .fontColor(this.uidValid ? '#52C41A' : '#FF4444')
                .width('100%');
            }
          }

          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('密码')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            TextInput({ text: this.password, placeholder: '请设置密码（6-20位，含字母和数字）' })
              .type(InputType.Password)
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .backgroundColor(this.getThemeColors().inputBg)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
              .fontSize(this.isLargeScreen ? 18 : 16)
              .fontColor(this.getThemeColors().textColor)
              .placeholderColor(this.getThemeColors().subTextColor)
              .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
              .backdropBlur(10)
              .onChange((value: string) => {
                this.password = value;
                this.checkPassword();
              });

            if (this.passwordCheckResult.message) {
              Text(this.passwordCheckResult.message)
                .fontSize(this.isLargeScreen ? 14 : 12)
                .fontColor(this.passwordValid ? '#52C41A' : '#FF4444')
                .width('100%');
            }
          }

          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('确认密码')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
              .type(InputType.Password)
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .backgroundColor(this.getThemeColors().inputBg)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
              .fontSize(this.isLargeScreen ? 18 : 16)
              .fontColor(this.getThemeColors().textColor)
              .placeholderColor(this.getThemeColors().subTextColor)
              .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
              .backdropBlur(10)
              .onChange((value: string) => {
                this.confirmPassword = value;
                this.checkConfirmPassword();
              });

            if (this.confirmPasswordCheckResult.message) {
              Text(this.confirmPasswordCheckResult.message)
                .fontSize(this.isLargeScreen ? 14 : 12)
                .fontColor(this.confirmPasswordValid ? '#52C41A' : '#FF4444')
                .width('100%');
            }
          }

          Column({ space: this.isLargeScreen ? 10 : 8 }) {
            Text('验证码')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            Row({ space: this.isLargeScreen ? 12 : 0 }) {
              TextInput({ text: this.verifyCode, placeholder: '请输入验证码' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(this.isLargeScreen ? 56 : 50)
                .backgroundColor(this.getThemeColors().inputBg)
                .borderRadius(this.isLargeScreen ? 12 : 8)
                .padding({ left: this.isLargeScreen ? 20 : 16, right: this.isLargeScreen ? 20 : 16 })
                .fontSize(this.isLargeScreen ? 18 : 16)
                .fontColor(this.getThemeColors().textColor)
                .placeholderColor(this.getThemeColors().subTextColor)
                .border({ width: this.isLargeScreen ? 1 : 0, color: this.getThemeColors().inputBorder })
                .backdropBlur(10)
                .onChange((value: string) => {
                  this.verifyCode = value;
                });

              Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                .fontSize(this.isLargeScreen ? 16 : 14)
                .fontColor(this.countdown > 0 || !this.phoneValid ? '#808080' : '#FFFFFF')
                .backgroundColor(this.countdown > 0 || !this.phoneValid ? 'rgba(160, 160, 160, 0.5)' : '#7B68EE')
                .height(this.isLargeScreen ? 56 : 50)
                .width(this.isLargeScreen ? 140 : 110)
                .borderRadius(this.isLargeScreen ? 12 : 8)
                .margin({ left: this.isLargeScreen ? 0 : 12 })
                .enabled(this.countdown <= 0 && this.phoneValid && !this.isSendingCode)
                .onClick(() => {
                  this.sendVerifyCode();
                });
            }
            .width('100%');
          }

          Column({ space: this.isLargeScreen ? 16 : 16 }) {
            Text('安全验证')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.getThemeColors().subTextColor)
              .width('100%');

            Button(this.isSliderVerified ? '已验证 ✓' : '点击进行验证')
              .fontSize(this.isLargeScreen ? 16 : 14)
              .fontColor(this.isSliderVerified ? '#52C41A' : '#FFFFFF')
              .backgroundColor(this.isSliderVerified ? '#F6FFED' : '#7B68EE')
              .width('100%')
              .height(this.isLargeScreen ? 56 : 50)
              .borderRadius(this.isLargeScreen ? 12 : 8)
              .enabled(!this.isSliderVerified)
              .onClick(() => {
                this.openSliderCaptchaDialog();
              });
          }
        }
      }

      Button('完成注册')
        .fontSize(this.isLargeScreen ? 18 : 16)
        .fontColor(this.canSubmit() ? '#FFFFFF' : '#808080')
        .backgroundColor(this.canSubmit() ? '#7B68EE' : 'rgba(160, 160, 160, 0.5)')
        .width(this.isLargeScreen ? 520 : '90%')
        .height(this.isLargeScreen ? 56 : 50)
        .borderRadius(this.isLargeScreen ? 28 : 25)
        .enabled(this.canSubmit())
        .margin({ top: this.isLargeScreen ? 0 : 20, bottom: this.isLargeScreen ? 24 : 40 })
        .onClick(() => {
          this.completeRegistration();
        });

      Row() {
        Text('已有账号？')
          .fontSize(this.isLargeScreen ? 16 : 14)
          .fontColor(this.getThemeColors().subTextColor);

        Text('去登录')
          .fontSize(this.isLargeScreen ? 16 : 14)
          .fontColor('#7B68EE')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            router.replaceUrl({ url: 'pages/LoginPage' });
          });
      }
      .margin({ bottom: 40 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  build() {
    Stack() {
      AnimatedBackground() {
        if (this.isLargeScreen) {
          Row() {
            Blank();
            Column() {
              this.headerSection();
              Scroll() {
                this.scrollContent();
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)
              .width(600);
            }
            .width(600)
            .height('100%')
            .alignItems(HorizontalAlign.Center);
            Blank();
          }
        } else {
          Column() {
            this.headerSection();
            Scroll() {
              this.scrollContent();
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off);
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.SpaceBetween);
        }
      }
    }
  }
}
