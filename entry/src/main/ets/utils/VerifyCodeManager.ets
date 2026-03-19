import preferences from '@ohos.data.preferences';
import { AliyunSMSService, SMSResult } from './AliyunSMSService';

/**
 * 验证码验证结果接口
 * 用于封装验证码验证的返回结果
 */
export interface VerifyResult {
  success: boolean;       // 是否验证成功
  message: string;         // 验证结果消息
}

/**
 * 验证码发送结果接口
 * 用于封装验证码发送的返回结果
 */
export type SendCodeResult = SMSResult;

/**
 * 验证码数据结构
 * 用于存储验证码的相关信息
 */
interface VerifyCodeData {
  code: string;             // 验证码内容
  expireTime: number;       // 过期时间戳（毫秒）
  sendCount: number;        // 发送次数
  lastSendTime: number;     // 最后发送时间戳（毫秒）
}

/**
 * 验证码管理器类
 * 提供完整的验证码管理功能，包括：
 * - 验证码发送（集成阿里云短信服务）
 * - 验证码存储和时效管理
 * - 验证码验证功能
 * - 防刷机制（发送频率限制）
 */
export class VerifyCodeManager {
  // ==================== 配置常量 ====================
  
  /**
   * 验证码有效期（分钟）
   * 默认5分钟有效期
   */
  private static readonly CODE_EXPIRE_MINUTES: number = 5;
  
  /**
   * 同一手机号最小发送间隔（秒）
   * 默认60秒，防止频繁发送
   */
  private static readonly MIN_SEND_INTERVAL_SECONDS: number = 60;
  
  /**
   * 同一手机号每日最大发送次数
   * 默认10次，防止恶意刷取
   */
  private static readonly MAX_DAILY_SEND_COUNT: number = 10;
  
  /**
   * Preference存储名称
   */
  private static readonly PREFERENCE_NAME: string = 'verify_codes';
  
  /**
   * 单例实例
   */
  private static instance: VerifyCodeManager | null = null;
  
  /**
   * Preference存储对象
   */
  private preferenceStore: preferences.Preferences | null = null;
  
  /**
   * 上下文对象
   */
  private context: Context | null = null;

  // ==================== 单例模式 ====================
  
  /**
   * 获取验证码管理器单例
   * @returns VerifyCodeManager 单例实例
   */
  static getInstance(): VerifyCodeManager {
    if (!VerifyCodeManager.instance) {
      VerifyCodeManager.instance = new VerifyCodeManager();
    }
    return VerifyCodeManager.instance;
  }

  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {}

  // ==================== 初始化方法 ====================
  
  /**
   * 初始化验证码管理器
   * 必须在使用前调用此方法进行初始化
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    try {
      this.context = context;
      this.preferenceStore = await preferences.getPreferences(context, VerifyCodeManager.PREFERENCE_NAME);
      console.info('验证码管理器初始化成功');
    } catch (error) {
      console.error('验证码管理器初始化失败：' + JSON.stringify(error));
      throw new Error('验证码管理器初始化失败');
    }
  }

  // ==================== 公共方法 ====================
  
  /**
   * 发送验证码
   * @param phoneNumber 手机号
   * @returns Promise<SMSResult> 发送结果Promise
   */
  async sendVerifyCode(phoneNumber: string): Promise<SMSResult> {
    try {
      // 1. 检查是否已初始化
      if (!this.preferenceStore) {
        return { success: false, message: '验证码管理器未初始化' };
      }

      // 2. 验证手机号格式
      if (!this.validatePhoneNumber(phoneNumber)) {
        return { success: false, message: '请输入正确的手机号码' };
      }

      // 3. 获取该手机号的验证码数据
      const codeData = await this.getVerifyCodeData(phoneNumber);
      const now = Date.now();

      // 4. 检查发送频率限制
      const frequencyCheck = this.checkSendFrequency(codeData, now);
      if (!frequencyCheck.success) {
        return { success: false, message: frequencyCheck.message };
      }

      // 5. 调用阿里云短信服务发送验证码
      const smsResult = await AliyunSMSService.sendVerifyCode(phoneNumber);
      
      if (smsResult.success && smsResult.code) {
        // 6. 发送成功，保存验证码数据
        const newCodeData: VerifyCodeData = {
          code: smsResult.code,
          expireTime: now + VerifyCodeManager.CODE_EXPIRE_MINUTES * 60 * 1000,
          sendCount: codeData.sendCount + 1,
          lastSendTime: now
        };
        await this.saveVerifyCodeData(phoneNumber, newCodeData);
        console.info(`验证码发送成功，手机号：${phoneNumber}，验证码：${smsResult.code}`);
      }

      return smsResult;
    } catch (error) {
      console.error('发送验证码异常：' + JSON.stringify(error));
      return { success: false, message: '发送验证码异常，请稍后重试' };
    }
  }

  /**
   * 验证验证码
   * @param phoneNumber 手机号
   * @param inputCode 用户输入的验证码
   * @param autoClear 验证成功后是否自动清除验证码（默认true）
   * @returns Promise<VerifyResult> 验证结果Promise
   */
  async verifyCode(phoneNumber: string, inputCode: string, autoClear: boolean = true): Promise<VerifyResult> {
    try {
      // 1. 检查是否已初始化
      if (!this.preferenceStore) {
        return { success: false, message: '验证码管理器未初始化' };
      }

      // 2. 验证手机号格式
      if (!this.validatePhoneNumber(phoneNumber)) {
        return { success: false, message: '手机号格式不正确' };
      }

      // 3. 检查输入验证码是否为空
      if (!inputCode || inputCode.trim() === '') {
        return { success: false, message: '请输入验证码' };
      }

      // 4. 获取存储的验证码数据
      const codeData = await this.getVerifyCodeData(phoneNumber);
      const now = Date.now();

      // 5. 检查是否存在有效的验证码
      if (!codeData.code || codeData.code === '') {
        return { success: false, message: '请先获取验证码' };
      }

      // 6. 检查验证码是否已过期
      if (now > codeData.expireTime) {
        if (autoClear) {
          await this.clearVerifyCode(phoneNumber);
        }
        return { success: false, message: '验证码已过期，请重新获取' };
      }

      // 7. 验证验证码是否正确
      if (codeData.code !== inputCode.trim()) {
        return { success: false, message: '验证码错误，请重新输入' };
      }

      // 8. 验证成功，清除验证码（防止重复使用）
      if (autoClear) {
        await this.clearVerifyCode(phoneNumber);
      }

      console.info(`验证码验证成功，手机号：${phoneNumber}`);
      return { success: true, message: '验证成功' };
    } catch (error) {
      console.error('验证验证码异常：' + JSON.stringify(error));
      return { success: false, message: '验证异常，请稍后重试' };
    }
  }

  /**
   * 清除指定手机号的验证码
   * @param phoneNumber 手机号
   */
  async clearVerifyCode(phoneNumber: string): Promise<void> {
    try {
      if (!this.preferenceStore) {
        return;
      }
      await this.preferenceStore.delete(phoneNumber);
      await this.preferenceStore.flush();
      console.info(`已清除手机号 ${phoneNumber} 的验证码`);
    } catch (error) {
      console.error('清除验证码失败：' + JSON.stringify(error));
    }
  }

  /**
   * 获取剩余可发送次数
   * @param phoneNumber 手机号
   * @returns Promise<number> 剩余可发送次数
   */
  async getRemainingSendCount(phoneNumber: string): Promise<number> {
    try {
      const codeData = await this.getVerifyCodeData(phoneNumber);
      const today = this.getTodayStartTimestamp();
      
      // 如果是今天之前的记录，重置发送次数
      if (codeData.lastSendTime < today) {
        return VerifyCodeManager.MAX_DAILY_SEND_COUNT;
      }
      
      return Math.max(0, VerifyCodeManager.MAX_DAILY_SEND_COUNT - codeData.sendCount);
    } catch (error) {
      console.error('获取剩余发送次数失败：' + JSON.stringify(error));
      return VerifyCodeManager.MAX_DAILY_SEND_COUNT;
    }
  }

  // ==================== 私有辅助方法 ====================
  
  /**
   * 验证手机号格式
   * @param phone 手机号
   * @returns boolean 是否为有效的中国大陆手机号
   */
  private validatePhoneNumber(phone: string): boolean {
    const phoneRegex = /^1[3-9]\d{9}$/;
    return phoneRegex.test(phone);
  }

  /**
   * 获取验证码数据
   * @param phoneNumber 手机号
   * @returns Promise<VerifyCodeData> 验证码数据
   */
  private async getVerifyCodeData(phoneNumber: string): Promise<VerifyCodeData> {
    try {
      if (!this.preferenceStore) {
        return this.createEmptyCodeData();
      }
      const dataStr = await this.preferenceStore.get(phoneNumber, '{}') as string;
      const data = JSON.parse(dataStr) as VerifyCodeData;
      return data || this.createEmptyCodeData();
    } catch (error) {
      console.error('获取验证码数据失败：' + JSON.stringify(error));
      return this.createEmptyCodeData();
    }
  }

  /**
   * 保存验证码数据
   * @param phoneNumber 手机号
   * @param codeData 验证码数据
   */
  private async saveVerifyCodeData(phoneNumber: string, codeData: VerifyCodeData): Promise<void> {
    try {
      if (!this.preferenceStore) {
        return;
      }
      await this.preferenceStore.put(phoneNumber, JSON.stringify(codeData));
      await this.preferenceStore.flush();
    } catch (error) {
      console.error('保存验证码数据失败：' + JSON.stringify(error));
    }
  }

  /**
   * 创建空的验证码数据
   * @returns VerifyCodeData 空的验证码数据
   */
  private createEmptyCodeData(): VerifyCodeData {
    return {
      code: '',
      expireTime: 0,
      sendCount: 0,
      lastSendTime: 0
    };
  }

  /**
   * 检查发送频率限制
   * @param codeData 验证码数据
   * @param now 当前时间戳
   * @returns VerifyResult 检查结果
   */
  private checkSendFrequency(codeData: VerifyCodeData, now: number): VerifyResult {
    const today = this.getTodayStartTimestamp();
    
    // 1. 如果是今天之前的记录，重置发送次数
    if (codeData.lastSendTime < today) {
      codeData.sendCount = 0;
    }

    // 2. 检查每日发送次数限制
    if (codeData.sendCount >= VerifyCodeManager.MAX_DAILY_SEND_COUNT) {
      return { 
        success: false, 
        message: `今日验证码发送次数已达上限（${VerifyCodeManager.MAX_DAILY_SEND_COUNT}次），请明天再试` 
      };
    }

    // 3. 检查最小发送间隔
    const timeSinceLastSend = (now - codeData.lastSendTime) / 1000;
    if (timeSinceLastSend < VerifyCodeManager.MIN_SEND_INTERVAL_SECONDS && codeData.lastSendTime > 0) {
      const waitTime = Math.ceil(VerifyCodeManager.MIN_SEND_INTERVAL_SECONDS - timeSinceLastSend);
      return { 
        success: false, 
        message: `发送过于频繁，请${waitTime}秒后再试` 
      };
    }

    return { success: true, message: '可以发送' };
  }

  /**
   * 获取今天开始的时间戳（0点）
   * @returns number 今天0点的时间戳
   */
  private getTodayStartTimestamp(): number {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return today.getTime();
  }
}

// ==================== 使用示例 ====================

/**
 * 使用示例：
 * 
 * // 1. 初始化（在应用启动时调用一次）
 * const verifyCodeManager = VerifyCodeManager.getInstance();
 * await verifyCodeManager.init(getContext(this));
 * 
 * // 2. 发送验证码
 * const sendResult = await verifyCodeManager.sendVerifyCode('13800138000');
 * if (sendResult.success) {
 *   console.log('验证码发送成功');
 * } else {
 *   console.log('验证码发送失败：' + sendResult.message);
 * }
 * 
 * // 3. 验证验证码
 * const verifyResult = await verifyCodeManager.verifyCode('13800138000', '123456');
 * if (verifyResult.success) {
 *   console.log('验证成功');
 * } else {
 *   console.log('验证失败：' + verifyResult.message);
 * }
 * 
 * // 4. 获取剩余可发送次数
 * const remainingCount = await verifyCodeManager.getRemainingSendCount('13800138000');
 * console.log('今日剩余发送次数：' + remainingCount);
 */
