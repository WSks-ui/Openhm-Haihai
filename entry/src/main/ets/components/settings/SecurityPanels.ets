import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { SettingsConstants } from '../../types/SettingsTypes';

@Component
export struct ChangePasswordPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State passwordStrength: string = '';

  private checkPasswordStrength(password: string): void {
    if (password.length < SettingsConstants.PASSWORD_MIN_LENGTH) {
      this.passwordStrength = '弱：密码长度不足8位';
    } else if (!/[a-zA-Z]/.test(password) || !/[0-9]/.test(password)) {
      this.passwordStrength = '弱：需包含字母和数字';
    } else if (password.length >= 12 && /[a-zA-Z]/.test(password) && /[0-9]/.test(password) && /[^a-zA-Z0-9]/.test(password)) {
      this.passwordStrength = '强：密码安全性高';
    } else {
      this.passwordStrength = '中：密码安全性一般';
    }
  }

  private getPasswordStrengthColor(): string {
    if (this.passwordStrength.startsWith('强')) {
      return '#34C759';
    } else if (this.passwordStrength.startsWith('中')) {
      return '#FF9500';
    } else {
      return '#FF3B30';
    }
  }

  private handleChangePassword(): void {
    if (!this.oldPassword) {
      promptAction.showToast({ message: '请输入旧密码' });
      return;
    }
    if (!this.newPassword) {
      promptAction.showToast({ message: '请输入新密码' });
      return;
    }
    if (this.newPassword.length < SettingsConstants.PASSWORD_MIN_LENGTH || this.newPassword.length > SettingsConstants.PASSWORD_MAX_LENGTH) {
      promptAction.showToast({ message: `密码长度需为${SettingsConstants.PASSWORD_MIN_LENGTH}-${SettingsConstants.PASSWORD_MAX_LENGTH}位` });
      return;
    }
    if (!/[a-zA-Z]/.test(this.newPassword) || !/[0-9]/.test(this.newPassword)) {
      promptAction.showToast({ message: '密码需包含字母和数字' });
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }
    promptAction.showToast({ message: '密码修改成功' });
    this.oldPassword = '';
    this.newPassword = '';
    this.confirmPassword = '';
    this.passwordStrength = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('旧密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入旧密码', text: this.oldPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.oldPassword = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('新密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入新密码', text: this.newPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.newPassword = value;
                this.checkPasswordStrength(value);
              })
            if (this.passwordStrength) {
              Text(this.passwordStrength)
                .fontSize(12)
                .fontColor(this.getPasswordStrengthColor())
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('确认新密码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('确认修改')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleChangePassword();
          })

        Column() {
          Text('密码要求：长度8-20位，需包含字母和数字')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}

@Component
export struct ChangePhonePanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('userPhone') userPhone: string = '';

  @State newPhone: string = '';
  @State verifyCode: string = '';
  @State countdown: number = 0;

  private sendVerifyCode(): void {
    if (!this.newPhone) {
      promptAction.showToast({ message: '请输入新手机号' });
      return;
    }
    if (!SettingsConstants.PHONE_REGEX.test(this.newPhone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    promptAction.showToast({ message: '验证码已发送' });
    this.countdown = 60;
    this.startCountdown();
  }

  private startCountdown(): void {
    if (this.countdown > 0) {
      this.countdown--;
      setTimeout(() => {
        this.startCountdown();
      }, 1000);
    }
  }

  private handleChangePhone(): void {
    if (!this.newPhone) {
      promptAction.showToast({ message: '请输入新手机号' });
      return;
    }
    if (!SettingsConstants.PHONE_REGEX.test(this.newPhone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (!this.verifyCode || this.verifyCode.length !== SettingsConstants.VERIFY_CODE_LENGTH) {
      promptAction.showToast({ message: `请输入${SettingsConstants.VERIFY_CODE_LENGTH}位验证码` });
      return;
    }
    promptAction.showToast({ message: '手机号更换成功' });
    this.newPhone = '';
    this.verifyCode = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('当前绑定手机号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Text(this.userPhone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2'))
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('新手机号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入新手机号', text: this.newPhone })
              .type(InputType.PhoneNumber)
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(11)
              .onChange((value: string) => {
                this.newPhone = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('验证码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入验证码', text: this.verifyCode })
                .type(InputType.Number)
                .height(48)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .layoutWeight(1)
                .maxLength(6)
                .onChange((value: string) => {
                  this.verifyCode = value;
                })
              Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                .width(110)
                .height(48)
                .backgroundColor(this.countdown > 0 ? '#CCCCCC' : '#7B68EE')
                .fontColor('#FFFFFF')
                .fontSize(14)
                .borderRadius(12)
                .margin({ left: 12 })
                .enabled(this.countdown === 0)
                .onClick(() => {
                  this.sendVerifyCode();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('确认更换')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleChangePhone();
          })

        Column() {
          Text('更换手机号后，原手机号将无法用于登录，请妥善保管新手机号')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}

@Component
export struct RealNameAuthPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State realName: string = '';
  @State idCard: string = '';

  private handleRealNameAuth(): void {
    if (!this.realName) {
      promptAction.showToast({ message: '请输入真实姓名' });
      return;
    }
    if (!this.idCard) {
      promptAction.showToast({ message: '请输入身份证号' });
      return;
    }
    if (!SettingsConstants.ID_CARD_REGEX.test(this.idCard)) {
      promptAction.showToast({ message: '请输入正确的身份证号' });
      return;
    }
    promptAction.showToast({ message: '实名认证提交成功' });
    this.realName = '';
    this.idCard = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('真实姓名')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入真实姓名', text: this.realName })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(20)
              .onChange((value: string) => {
                this.realName = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('身份证号')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入身份证号', text: this.idCard })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(18)
              .onChange((value: string) => {
                this.idCard = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('提交认证')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleRealNameAuth();
          })

        Column() {
          Text('实名认证信息仅用于身份验证，我们将严格保护您的隐私安全')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}

@Component
export struct AddEmailPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State email: string = '';
  @State emailVerifyCode: string = '';
  @State countdown: number = 0;

  private sendEmailVerifyCode(): void {
    if (!this.email) {
      promptAction.showToast({ message: '请输入邮箱地址' });
      return;
    }
    if (!SettingsConstants.EMAIL_REGEX.test(this.email)) {
      promptAction.showToast({ message: '请输入正确的邮箱地址' });
      return;
    }
    promptAction.showToast({ message: '验证码已发送至邮箱' });
    this.countdown = 60;
    this.startCountdown();
  }

  private startCountdown(): void {
    if (this.countdown > 0) {
      this.countdown--;
      setTimeout(() => {
        this.startCountdown();
      }, 1000);
    }
  }

  private handleAddEmail(): void {
    if (!this.email) {
      promptAction.showToast({ message: '请输入邮箱地址' });
      return;
    }
    if (!SettingsConstants.EMAIL_REGEX.test(this.email)) {
      promptAction.showToast({ message: '请输入正确的邮箱地址' });
      return;
    }
    if (!this.emailVerifyCode || this.emailVerifyCode.length !== SettingsConstants.VERIFY_CODE_LENGTH) {
      promptAction.showToast({ message: `请输入${SettingsConstants.VERIFY_CODE_LENGTH}位验证码` });
      return;
    }
    promptAction.showToast({ message: '邮箱添加成功' });
    this.email = '';
    this.emailVerifyCode = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('邮箱地址')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入邮箱地址', text: this.email })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.email = value;
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('验证码')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入验证码', text: this.emailVerifyCode })
                .type(InputType.Number)
                .height(48)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .layoutWeight(1)
                .maxLength(6)
                .onChange((value: string) => {
                  this.emailVerifyCode = value;
                })
              Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
                .width(110)
                .height(48)
                .backgroundColor(this.countdown > 0 ? '#CCCCCC' : '#7B68EE')
                .fontColor('#FFFFFF')
                .fontSize(14)
                .borderRadius(12)
                .margin({ left: 12 })
                .enabled(this.countdown === 0)
                .onClick(() => {
                  this.sendEmailVerifyCode();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('添加邮箱')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleAddEmail();
          })

        Column() {
          Text('绑定邮箱可用于找回密码和接收重要通知')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}

@Component
export struct SecurityQuestionPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State securityQuestion: string = '';
  @State securityAnswer: string = '';

  private handleSecurityQuestion(): void {
    if (!this.securityQuestion) {
      promptAction.showToast({ message: '请选择密保问题' });
      return;
    }
    if (!this.securityAnswer) {
      promptAction.showToast({ message: '请输入答案' });
      return;
    }
    promptAction.showToast({ message: '密保问题设置成功' });
    this.securityQuestion = '';
    this.securityAnswer = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 0 }) {
          Column() {
            Text('选择密保问题')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            Select([
              { value: '您的出生地是？' },
              { value: '您母亲的姓名是？' },
              { value: '您最喜欢的颜色是？' },
              { value: '您第一只宠物的名字是？' },
              { value: '您小学的名称是？' }
            ])
              .selected(0)
              .value(this.securityQuestion || '请选择密保问题')
              .font({ size: 16 })
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
              .selectedOptionFont({ size: 16 })
              .optionFont({ size: 16 })
              .width('100%')
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .onSelect((index: number) => {
                this.securityQuestion = SettingsConstants.SECURITY_QUESTIONS[index];
              })
          }
          .width('100%')
          .padding(20)

          Divider()
            .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')

          Column() {
            Text('答案')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
              .margin({ bottom: 8 })
            TextInput({ placeholder: '请输入答案', text: this.securityAnswer })
              .height(48)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F2F2F7')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .maxLength(50)
              .onChange((value: string) => {
                this.securityAnswer = value;
              })
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius(16)

        Button('保存设置')
          .width('100%')
          .height(50)
          .backgroundColor('#7B68EE')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.handleSecurityQuestion();
          })

        Column() {
          Text('密保问题可用于找回密码，请牢记您设置的答案')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
            .lineHeight(20)
        }
        .width('100%')
        .padding(16)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .layoutWeight(1)
  }
}
