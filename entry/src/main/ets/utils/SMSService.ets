export interface SMSResult {
  success: boolean;
  code?: string;
  message?: string;
}

export class SMSService {
  private static readonly TEST_MODE: boolean = true;
  private static readonly TEST_CODE: string = '123456';

  static generateVerifyCode(length: number): string {
    let code = '';
    for (let i = 0; i < length; i++) {
      code += Math.floor(Math.random() * 10);
    }
    return code;
  }

  static async sendVerifyCode(phoneNumber: string): Promise<SMSResult> {
    try {
      if (SMSService.TEST_MODE) {
        console.info('【测试模式】使用固定验证码：' + SMSService.TEST_CODE);
        await new Promise<void>((resolve) => {
          setTimeout(() => {
            resolve();
          }, 500);
        });
        return {
          success: true,
          code: SMSService.TEST_CODE,
          message: '测试模式：验证码为 ' + SMSService.TEST_CODE
        };
      }

      const verifyCode = SMSService.generateVerifyCode(6);
      console.info('验证码已生成：' + verifyCode);
      return { success: true, code: verifyCode, message: '验证码发送成功' };
    } catch {
      console.error('发送验证码失败');
      return { success: false, message: '发送验证码异常' };
    }
  }
}
