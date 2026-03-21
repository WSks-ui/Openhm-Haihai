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

  /**
   * 检查手机号
   */
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

  /**
   * 检查昵称
   */
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

  /**
   * 检查UID
   */
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

  /**
   * 检查密码
   */
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

  /**
   * 检查确认密码
   */
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

  /**
   * 打开滑块验证弹窗
   */
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

  /**
   * 发送验证码
   */
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

  /**
   * 开始倒计时
   */
  private startCountdown() {
    this.countdown = 60;
    const timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(timer);
      }
    }, 1000);
  }

  /**
   * 完成注册
   */
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

  /**
   * 检查是否可以提交
   */
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

  /**
   * 显示成功提示
   */
  private showSuccess(message: string) {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  /**
   * 显示错误提示
   */
  private showError(message: string) {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  /**
   * 获取主题颜色
   */
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

  build() {
    Stack() {
      AnimatedBackground() {
        if (this.isLargeScreen) {
          Row() {
            Blank();

            Column() {
              Row() {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([this.getThemeColors().subTextColor])
                  .onClick(() => {
                    router.back();
                  })
                Text('注册账号')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getThemeColors().textColor)
                  .margin({ left: 16 })
              }
              .width('100%')
              .height(64)
              .padding({ left: 24, right: 24 })
              .margin({ top: 20 });

              Scroll() {
                Column({ space: 24 }) {
                  Text('创建新账号')
                    .fontSize(36)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getThemeColors().textColor)
                    .width('100%')
                    .margin({ top: 24, bottom: 12 })

                  Text('手机号快速注册，登录更便捷')
                    .fontSize(16)
                    .fontColor(this.getThemeColors().subTextColor)
                    .width('100%')
                    .margin({ bottom: 32 })

                  LiquidGlass({
                    glassWidth: 520,
                    glassRadius: 24,
                    blurRadius: 30,
                    glassPadding: 48,
                    glassColor: this.getThemeColors().glassColor
                  }) {
                    Column({ space: 20 }) {
                      Column({ space: 10 }) {
                        Text('手机号')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.phoneNumber, placeholder: '请输入手机号' })
                          .type(InputType.PhoneNumber)
                          .width('100%')
                          .height(56)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(12)
                          .padding({ left: 20, right: 20 })
                          .fontSize(18)
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .border({ width: 1, color: this.getThemeColors().inputBorder })
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.phoneNumber = value;
                            this.checkPhoneNumber();
                          })

                        if (this.phoneCheckResult.message) {
                          Text(this.phoneCheckResult.message)
                            .fontSize(14)
                            .fontColor(this.phoneValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 10 }) {
                        Text('昵称')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.nickname, placeholder: '请输入昵称（2-20个字符）' })
                          .width('100%')
                          .height(56)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(12)
                          .padding({ left: 20, right: 20 })
                          .fontSize(18)
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .border({ width: 1, color: this.getThemeColors().inputBorder })
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.nickname = value;
                            this.checkNickname();
                          })

                        if (this.nicknameCheckResult.message) {
                          Text(this.nicknameCheckResult.message)
                            .fontSize(14)
                            .fontColor(this.nicknameValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 10 }) {
                        Text('UID（可选）')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.customUid, placeholder: '自定义UID（4-16位字母数字下划线）' })
                          .width('100%')
                          .height(56)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(12)
                          .padding({ left: 20, right: 20 })
                          .fontSize(18)
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .border({ width: 1, color: this.getThemeColors().inputBorder })
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.customUid = value;
                            this.checkUID();
                          })

                        if (this.uidCheckResult.message && this.customUid.length > 0) {
                          Text(this.uidCheckResult.message)
                            .fontSize(14)
                            .fontColor(this.uidValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 10 }) {
                        Text('密码')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.password, placeholder: '请设置密码（6-20位，含字母和数字）' })
                          .type(InputType.Password)
                          .width('100%')
                          .height(56)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(12)
                          .padding({ left: 20, right: 20 })
                          .fontSize(18)
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .border({ width: 1, color: this.getThemeColors().inputBorder })
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.password = value;
                            this.checkPassword();
                          })

                        if (this.passwordCheckResult.message) {
                          Text(this.passwordCheckResult.message)
                            .fontSize(14)
                            .fontColor(this.passwordValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 10 }) {
                        Text('确认密码')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
                          .type(InputType.Password)
                          .width('100%')
                          .height(56)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(12)
                          .padding({ left: 20, right: 20 })
                          .fontSize(18)
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .border({ width: 1, color: this.getThemeColors().inputBorder })
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.confirmPassword = value;
                            this.checkConfirmPassword();
                          })

                        if (this.confirmPasswordCheckResult.message) {
                          Text(this.confirmPasswordCheckResult.message)
                            .fontSize(14)
                            .fontColor(this.confirmPasswordValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 10 }) {
                        Text('验证码')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        Row({ space: 12 }) {
                          TextInput({ text: this.verifyCode, placeholder: '请输入验证码' })
                            .type(InputType.Number)
                            .layoutWeight(1)
                            .height(56)
                            .backgroundColor(this.getThemeColors().inputBg)
                            .borderRadius(12)
                            .padding({ left: 20, right: 20 })
                            .fontSize(18)
                            .fontColor(this.getThemeColors().textColor)
                            .placeholderColor(this.getThemeColors().subTextColor)
                            .border({ width: 1, color: this.getThemeColors().inputBorder })
                            .backdropBlur(10)
                            .onChange((value: string) => {
                              this.verifyCode = value;
                            })

                          Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                            .fontSize(16)
                            .fontColor(this.countdown > 0 || !this.phoneValid ? '#808080' : '#FFFFFF')
                            .backgroundColor(this.countdown > 0 || !this.phoneValid ? 'rgba(160, 160, 160, 0.5)' :
                              '#7B68EE')
                            .height(56)
                            .width(140)
                            .borderRadius(12)
                            .enabled(this.countdown <= 0 && this.phoneValid && !this.isSendingCode)
                            .onClick(() => {
                              this.sendVerifyCode();
                            })
                        }
                        .width('100%')
                      }

                      Column({ space: 16 }) {
                        Text('安全验证')
                          .fontSize(16)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        Button(this.isSliderVerified ? '已验证 ✓' : '点击进行验证')
                          .fontSize(16)
                          .fontColor(this.isSliderVerified ? '#52C41A' : '#FFFFFF')
                          .backgroundColor(this.isSliderVerified ? '#F6FFED' : '#7B68EE')
                          .width('100%')
                          .height(56)
                          .borderRadius(12)
                          .enabled(!this.isSliderVerified)
                          .onClick(() => {
                            this.openSliderCaptchaDialog();
                          })
                      }
                    }
                  }

                  Button('完成注册')
                    .fontSize(18)
                    .fontColor(this.canSubmit() ? '#FFFFFF' : '#808080')
                    .backgroundColor(this.canSubmit() ? '#7B68EE' : 'rgba(160, 160, 160, 0.5)')
                    .width(520)
                    .height(56)
                    .borderRadius(28)
                    .enabled(this.canSubmit())
                    .margin({ bottom: 24 })
                    .onClick(() => {
                      this.completeRegistration();
                    })

                  Row() {
                    Text('已有账号？')
                      .fontSize(16)
                      .fontColor(this.getThemeColors().subTextColor)

                    Text('去登录')
                      .fontSize(16)
                      .fontColor('#7B68EE')
                      .fontWeight(FontWeight.Medium)
                      .onClick(() => {
                        router.replaceUrl({ url: 'pages/LoginPage' });
                      })
                  }
                  .margin({ bottom: 40 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)
              .width(600)
            }
            .width(600)
            .height('100%')
            .alignItems(HorizontalAlign.Center);

            Blank();
          }
        } else {
            Column() {
              Row() {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(24)
                  .fontColor([this.getThemeColors().subTextColor])
                  .onClick(() => {
                    router.back();
                  })
                Text('注册账号')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getThemeColors().textColor)
                  .margin({ left: 12 })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Scroll() {
                Column({ space: 20 }) {
                  Text('创建新账号')
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getThemeColors().textColor)
                    .width('100%')
                    .margin({ top: 20, bottom: 8 })

                  Text('手机号快速注册，登录更便捷')
                    .fontSize(14)
                    .fontColor(this.getThemeColors().subTextColor)
                    .width('100%')
                    .margin({ bottom: 24 })

                  LiquidGlass({
                    glassWidth: '92%',
                    glassRadius: 24,
                    blurRadius: 30,
                    glassPadding: 20,
                    glassColor: this.getThemeColors().glassColor
                  }) {
                    Column({ space: 16 }) {
                      Column({ space: 8 }) {
                        Text('手机号')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.phoneNumber, placeholder: '请输入手机号' })
                          .type(InputType.PhoneNumber)
                          .width('100%')
                          .height(50)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(8)
                          .padding({ left: 16, right: 16 })
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.phoneNumber = value;
                            this.checkPhoneNumber();
                          })

                        if (this.phoneCheckResult.message) {
                          Text(this.phoneCheckResult.message)
                            .fontSize(12)
                            .fontColor(this.phoneValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 8 }) {
                        Text('昵称')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.nickname, placeholder: '请输入昵称（2-20个字符）' })
                          .width('100%')
                          .height(50)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(8)
                          .padding({ left: 16, right: 16 })
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.nickname = value;
                            this.checkNickname();
                          })

                        if (this.nicknameCheckResult.message) {
                          Text(this.nicknameCheckResult.message)
                            .fontSize(12)
                            .fontColor(this.nicknameValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 8 }) {
                        Text('UID（可选）')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.customUid, placeholder: '自定义UID（4-16位字母数字下划线）' })
                          .width('100%')
                          .height(50)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(8)
                          .padding({ left: 16, right: 16 })
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.customUid = value;
                            this.checkUID();
                          })

                        if (this.uidCheckResult.message && this.customUid.length > 0) {
                          Text(this.uidCheckResult.message)
                            .fontSize(12)
                            .fontColor(this.uidValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 8 }) {
                        Text('密码')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.password, placeholder: '请设置密码（6-20位，含字母和数字）' })
                          .type(InputType.Password)
                          .width('100%')
                          .height(50)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(8)
                          .padding({ left: 16, right: 16 })
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.password = value;
                            this.checkPassword();
                          })

                        if (this.passwordCheckResult.message) {
                          Text(this.passwordCheckResult.message)
                            .fontSize(12)
                            .fontColor(this.passwordValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 8 }) {
                        Text('确认密码')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
                          .type(InputType.Password)
                          .width('100%')
                          .height(50)
                          .backgroundColor(this.getThemeColors().inputBg)
                          .borderRadius(8)
                          .padding({ left: 16, right: 16 })
                          .fontColor(this.getThemeColors().textColor)
                          .placeholderColor(this.getThemeColors().subTextColor)
                          .backdropBlur(10)
                          .onChange((value: string) => {
                            this.confirmPassword = value;
                            this.checkConfirmPassword();
                          })

                        if (this.confirmPasswordCheckResult.message) {
                          Text(this.confirmPasswordCheckResult.message)
                            .fontSize(12)
                            .fontColor(this.confirmPasswordValid ? '#52C41A' : '#FF4444')
                            .width('100%')
                        }
                      }

                      Column({ space: 8 }) {
                        Text('验证码')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        Row() {
                          TextInput({ text: this.verifyCode, placeholder: '请输入验证码' })
                            .type(InputType.Number)
                            .layoutWeight(1)
                            .height(50)
                            .backgroundColor(this.getThemeColors().inputBg)
                            .borderRadius(8)
                            .padding({ left: 16, right: 16 })
                            .fontColor(this.getThemeColors().textColor)
                            .placeholderColor(this.getThemeColors().subTextColor)
                            .backdropBlur(10)
                            .onChange((value: string) => {
                              this.verifyCode = value;
                            })

                          Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                            .fontSize(14)
                            .fontColor(this.countdown > 0 || !this.phoneValid ? '#808080' : '#FFFFFF')
                            .backgroundColor(this.countdown > 0 || !this.phoneValid ? 'rgba(160, 160, 160, 0.5)' :
                              '#7B68EE')
                            .height(50)
                            .margin({ left: 12 })
                            .enabled(this.countdown <= 0 && this.phoneValid && !this.isSendingCode)
                            .onClick(() => {
                              this.sendVerifyCode();
                            })
                        }
                        .width('100%')
                      }

                      Column({ space: 16 }) {
                        Text('安全验证')
                          .fontSize(14)
                          .fontColor(this.getThemeColors().subTextColor)
                          .width('100%')

                        Button(this.isSliderVerified ? '已验证 ✓' : '点击进行验证')
                          .fontSize(14)
                          .fontColor(this.isSliderVerified ? '#52C41A' : '#FFFFFF')
                          .backgroundColor(this.isSliderVerified ? '#F6FFED' : '#7B68EE')
                          .width('100%')
                          .height(50)
                          .borderRadius(8)
                          .enabled(!this.isSliderVerified)
                          .onClick(() => {
                            this.openSliderCaptchaDialog();
                          })
                      }
                    }
                  }

                  Button('完成注册')
                    .fontSize(16)
                    .fontColor(this.canSubmit() ? '#FFFFFF' : '#808080')
                    .backgroundColor(this.canSubmit() ? '#7B68EE' : 'rgba(160, 160, 160, 0.5)')
                    .width('90%')
                    .height(50)
                    .borderRadius(25)
                    .enabled(this.canSubmit())
                    .margin({ top: 20, bottom: 40 })
                    .onClick(() => {
                      this.completeRegistration();
                    })

                  Row() {
                    Text('已有账号？')
                      .fontSize(14)
                      .fontColor(this.getThemeColors().subTextColor)

                    Text('去登录')
                      .fontSize(14)
                      .fontColor('#7B68EE')
                      .fontWeight(FontWeight.Medium)
                      .onClick(() => {
                        router.replaceUrl({ url: 'pages/LoginPage' });
                      })
                  }
                  .margin({ bottom: 40 })
                }
                .width('100%')
                .padding({ left: 20, right: 20 })
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
        }
      }
    }
  }

