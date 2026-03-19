import http from '@ohos.net.http';
import util from '@ohos.util';
import cryptoFramework from '@ohos.security.cryptoFramework';

/**
 * 短信发送结果接口
 * 用于封装短信发送的返回结果
 */
export interface SMSResult {
  success: boolean;      // 是否发送成功
  code?: string;          // 发送的验证码（仅在测试模式或成功时返回）
  message?: string;       // 响应消息或错误信息
}

/**
 * 阿里云API响应接口
 * 用于解析阿里云短信服务API的返回数据
 */
interface AliyunAPIResponse {
  Code: string;           // 响应状态码，OK表示成功
  Message: string;        // 响应消息
  RequestId?: string;     // 请求ID，用于问题追踪
  BizId?: string;         // 发送回执ID
}

/**
 * 阿里云短信服务类
 * 提供完整的短信验证码发送功能
 */
export class AliyunSMSService {
  // ==================== 配置参数 ====================

  /**
   * 测试模式开关
   * 设置为true时，不调用真实的阿里云短信服务，直接生成验证码
   */
  private static readonly TEST_MODE:
    boolean = false;

  /**
   * 测试模式下的固定验证码
   */
  private static readonly TEST_CODE: string = '123456';

  /**
   * 阿里云AccessKey ID
   */
  private static readonly ACCESS_KEY_ID: string = 'YOUR_ACCESS_KEY_ID';

  /**
   * 阿里云AccessKey Secret
   */
  private static readonly ACCESS_KEY_SECRET: string = 'YOUR_ACCESS_KEY_SECRET';

  /**
   * 阿里云API端点
   * 使用阿里云号码认证服务端点：https://dypnsapi.aliyuncs.com
   */
  private static readonly ENDPOINT: string = 'https://dypnsapi.aliyuncs.com';

  /**
   * 短信签名
   * 必须在阿里云短信服务控制台审核通过
   */
  private static readonly SIGN_NAME: string = '速通互联验证码';

  /**
   * 短信模板CODE
   * 必须在阿里云短信服务控制台审核通过
   */
  private static readonly TEMPLATE_CODE: string = '100001';

  /**
   * 验证码有效期（分钟）
   */
  private static readonly CODE_VALID_MINUTES: string = '5';

  // ==================== 公共方法 ====================

  /**
   * 生成随机验证码
   * @param length 验证码长度，建议4-6位
   * @returns 生成的随机数字验证码字符串
   */
  static generateVerifyCode(length: number): string {
    let code = '';
    for (let i = 0; i < length; i++) {
      code += Math.floor(Math.random() * 10);
    }
    return code;
  }

  /**
   * 发送短信验证码
   * @param phoneNumber 接收验证码的手机号（中国大陆手机号）
   * @returns Promise<SMSResult> 发送结果Promise
   */
  static async sendVerifyCode(phoneNumber: string): Promise<SMSResult> {
    try {
      // 测试模式：直接返回固定验证码，不发送真实短信
      if (AliyunSMSService.TEST_MODE) {
        console.info('【测试模式】使用固定验证码：' + AliyunSMSService.TEST_CODE);
        // 模拟网络延迟
        await new Promise<void>((resolve) => {
          setTimeout(() => {
            resolve();
          }, 500);
        });
        return {
          success: true,
          code: AliyunSMSService.TEST_CODE,
          message: '测试模式：验证码为 ' + AliyunSMSService.TEST_CODE
        };
      }

      // 生成验证码
      const verifyCode = AliyunSMSService.generateVerifyCode(6);

      // 构建请求参数 - 使用Map代替对象字面量
      const timestamp = new Date().toISOString().replace(/\.\d{3}Z/, 'Z');
      const nonce = Math.random().toString(36).substring(2, 15);

      const params = new Map<string, string>();
      params.set('AccessKeyId', AliyunSMSService.ACCESS_KEY_ID);
      params.set('Action', 'SendSmsVerifyCode');
      params.set('Format', 'JSON');
      params.set('PhoneNumber', phoneNumber);
      params.set('RegionId', 'cn-hangzhou');
      params.set('SignName', AliyunSMSService.SIGN_NAME);
      params.set('SignatureMethod', 'HMAC-SHA1');
      params.set('SignatureNonce', nonce);
      params.set('SignatureVersion', '1.0');
      params.set('TemplateCode', AliyunSMSService.TEMPLATE_CODE);
      params.set('TemplateParam', `{"code":"${verifyCode}","min":"${AliyunSMSService.CODE_VALID_MINUTES}"}`);
      params.set('Timestamp', timestamp);
      params.set('Version', '2017-05-25');

      // 生成阿里云API签名
      const signature = await AliyunSMSService.generateSignature(params, 'POST');
      params.set('Signature', signature);

      // 构建查询字符串
      const queryString = AliyunSMSService.buildQueryString(params);

      // 创建HTTP请求并发送
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(AliyunSMSService.ENDPOINT, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        extraData: queryString,
        connectTimeout: 60000,  // 连接超时60秒
        readTimeout: 60000      // 读取超时60秒
      });

      // 销毁HTTP请求对象，释放资源
      httpRequest.destroy();

      // 记录响应日志
      console.info('========== 阿里云API响应 ==========');
      console.info('响应码：' + response.responseCode);
      console.info('响应内容：' + response.result);
      console.info('===================================');

      // 处理响应结果
      if (response.responseCode === 200) {
        const resultStr = response.result as string;
        const result: AliyunAPIResponse = JSON.parse(resultStr) as AliyunAPIResponse;

        console.info('解析后的Code：' + result.Code);
        console.info('解析后的Message：' + result.Message);

        if (result.Code === 'OK') {
          console.info('✅ 验证码发送成功，验证码为：' + verifyCode);
          return { success: true, code: verifyCode, message: '验证码发送成功' };
        } else {
          console.error('❌ 发送失败，错误码：' + result.Code + '，错误信息：' + result.Message);
          return { success: false, message: result.Message || '发送失败' };
        }
      } else {
        console.error('❌ 网络请求失败，响应码：' + response.responseCode);
        return { success: false, message: '网络请求失败' };
      }
    } catch (error) {
      console.error('发送验证码异常：' + JSON.stringify(error));
      return { success: false, message: '发送验证码异常，请稍后重试' };
    }
  }

  // ==================== 私有辅助方法 ====================

  /**
   * 生成阿里云API签名
   * 按照阿里云API签名规范进行签名计算
   * @param params 请求参数Map
   * @param method HTTP请求方法（GET/POST）
   * @returns Promise<string> 生成的签名字符串
   */
  private static async generateSignature(params: Map<string, string>, method: string): Promise<string> {
    try {
      // 1. 对参数进行字典序排序（排除Signature参数）
      const sortedKeys: string[] = [];
      params.forEach((value: string, key: string) => {
        if (key !== 'Signature') {
          sortedKeys.push(key);
        }
      });
      sortedKeys.sort();

      // 2. 构造规范化查询字符串
      let canonicalizedQueryString = '';
      for (let i = 0; i < sortedKeys.length; i++) {
        const key = sortedKeys[i];
        const value = params.get(key);
        if (value !== undefined) {
          if (i > 0) {
            canonicalizedQueryString += '&';
          }
          canonicalizedQueryString += `${AliyunSMSService.percentEncode(key)}=${AliyunSMSService.percentEncode(value)}`;
        }
      }

      // 3. 构造待签名字符串
      const stringToSign = `${method}&${AliyunSMSService.percentEncode('/')}&${AliyunSMSService.percentEncode(canonicalizedQueryString)}`;

      // 4. 使用HMAC-SHA1进行加密（注意：密钥需要添加&后缀）
      const signature = await AliyunSMSService.hmacSha1(stringToSign, AliyunSMSService.ACCESS_KEY_SECRET + '&');

      return signature;
    } catch (error) {
      console.error('生成签名失败：' + JSON.stringify(error));
      throw new Error('生成签名失败');
    }
  }

  /**
   * HMAC-SHA1加密
   * 使用HarmonyOS cryptoFramework进行加密计算
   * @param data 待加密的数据字符串
   * @param key 加密密钥
   * @returns Promise<string> Base64编码的加密结果
   */
  private static async hmacSha1(data: string, key: string): Promise<string> {
    // 1. 创建对称密钥生成器
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');

    // 2. 将密钥字符串转换为Uint8Array
    const keyData = AliyunSMSService.stringToUint8Array(key);
    const keyBlob: cryptoFramework.DataBlob = {
      data: new Uint8Array(keyData)
    };

    // 3. 转换密钥格式
    const symKey = await symKeyGenerator.convertKey(keyBlob);

    // 4. 创建Mac实例并初始化
    const mac = cryptoFramework.createMac('SHA1');
    await mac.init(symKey);

    // 5. 更新数据到Mac
    const inputData = AliyunSMSService.stringToUint8Array(data);
    const inputBlob: cryptoFramework.DataBlob = {
      data: new Uint8Array(inputData)
    };
    await mac.update(inputBlob);

    // 6. 计算最终的HMAC值
    const outputBlob: cryptoFramework.DataBlob = await mac.doFinal();

    // 7. 转换为Base64编码
    return AliyunSMSService.base64Encode(outputBlob.data);
  }

  /**
   * 字符串转换为Uint8Array
   * @param str 输入字符串
   * @returns number[] 转换后的数字数组
   */
  private static stringToUint8Array(str: string): number[] {
    const arr: number[] = [];
    for (let i = 0; i < str.length; i++) {
      arr.push(str.charCodeAt(i));
    }
    return arr;
  }

  /**
   * Base64编码
   * @param data 待编码的Uint8Array数据
   * @returns string Base64编码字符串
   */
  private static base64Encode(data: Uint8Array): string {
    const base64Helper = new util.Base64Helper();
    return base64Helper.encodeToStringSync(data);
  }

  /**
   * URL编码（符合阿里云规范）
   * 阿里云API对URL编码有特殊要求，需要对某些字符进行额外处理
   * @param str 待编码字符串
   * @returns string 编码后的字符串
   */
  private static percentEncode(str: string): string {
    return encodeURIComponent(str)
      .replace(/!/g, '%21')
      .replace(/'/g, '%27')
      .replace(/\(/g, '%28')
      .replace(/\)/g, '%29')
      .replace(/\*/g, '%2A')
      .replace(/%7E/g, '~')
      .replace(/\+/g, '%20');
  }

  /**
   * 构建查询字符串
   * @param params 参数Map
   * @returns string 构建好的查询字符串
   */
  private static buildQueryString(params: Map<string, string>): string {
    let queryString = '';
    let isFirst = true;

    params.forEach((value: string, key: string) => {
      if (!isFirst) {
        queryString += '&';
      }
      queryString += `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
      isFirst = false;
    });

    return queryString;
  }
}
