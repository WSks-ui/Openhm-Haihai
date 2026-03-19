/**
 * 语音识别服务模块
 * 
 * 该模块封装了 HarmonyOS Core Speech Kit 的语音识别功能，提供统一的语音识别服务接口。
 * 采用单例模式设计，确保全局只有一个语音识别引擎实例，优化资源使用。
 * 
 * 主要功能：
 * - 麦克风权限检查与申请
 * - 语音识别引擎初始化与管理
 * - 实时语音识别结果回调
 * - 音量变化监听
 * - 超时自动停止
 * - 错误处理与状态管理
 * 
 * @author HarmonyOS Architect
 * @date 2026-03-07
 */

import { speechRecognizer } from '@kit.CoreSpeechKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';

/**
 * 语音识别结果接口
 * 
 * 用于封装语音识别返回的结果数据
 */
export interface SpeechRecognitionResult {
  /** 识别出的文本内容 */
  text: string;
  /** 是否为最终结果（true 表示识别完成，false 表示中间结果） */
  isFinal: boolean;
  /** 识别置信度（0.0-1.0，值越大表示识别越准确） */
  confidence: number;
}

/**
 * 语音识别错误接口
 * 
 * 用于封装语音识别过程中发生的错误信息
 */
export interface SpeechRecognitionError {
  /** 错误码 */
  code: number;
  /** 错误描述信息 */
  message: string;
}

/**
 * 语音识别状态类型
 * 
 * - 'idle': 空闲状态，未开始识别
 * - 'listening': 正在监听，等待语音输入
 * - 'recognizing': 正在识别中，处理语音数据
 * - 'success': 识别成功
 * - 'error': 识别出错
 */
export type SpeechRecognitionState = 'idle' | 'listening' | 'recognizing' | 'success' | 'error';

/**
 * 语音识别回调接口
 * 
 * 定义了语音识别过程中各种事件的回调方法
 */
export interface SpeechRecognitionCallbacks {
  /** 状态变化回调 */
  onStateChange: (state: SpeechRecognitionState) => void;
  /** 识别结果回调 */
  onResult: (result: SpeechRecognitionResult) => void;
  /** 错误回调 */
  onError: (error: SpeechRecognitionError) => void;
  /** 音量变化回调（音量范围 0-100） */
  onVolumeChange: (volume: number) => void;
}

/**
 * 语音识别服务类
 * 
 * 核心服务类，提供语音识别的完整生命周期管理。
 * 使用单例模式，通过 getInstance() 获取全局唯一实例。
 * 
 * @example
 * ```typescript
 * const speechService = SpeechRecognitionService.getInstance();
 * 
 * // 检查权限
 * const hasPermission = await speechService.checkMicrophonePermission(context);
 * 
 * // 初始化并设置回调
 * await speechService.initialize({
 *   onStateChange: (state) => console.log('State:', state),
 *   onResult: (result) => console.log('Result:', result.text),
 *   onError: (error) => console.error('Error:', error.message),
 *   onVolumeChange: (volume) => console.log('Volume:', volume)
 * });
 * 
 * // 开始监听
 * await speechService.startListening();
 * 
 * // 停止监听
 * await speechService.stopListening();
 * ```
 */
export class SpeechRecognitionService {
  /** 单例实例 */
  private static instance: SpeechRecognitionService | null = null;
  
  /** 语音识别引擎实例 */
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  
  /** 当前会话ID */
  private sessionId: string = '';
  
  /** 回调函数集合 */
  private callbacks: SpeechRecognitionCallbacks | null = null;
  
  /** 当前识别状态 */
  private currentState: SpeechRecognitionState = 'idle';
  
  /** 音量模拟定时器ID */
  private volumeTimer: number = -1;
  
  /** 无语音超时定时器ID */
  private noSpeechTimer: number = -1;
  
  /** 无语音超时时间（毫秒） */
  private readonly NO_SPEECH_TIMEOUT: number = 5000;
  
  /** 引擎是否已初始化 */
  private isInitialized: boolean = false;

  /** 私有构造函数，防止外部实例化 */
  private constructor() {}

  /**
   * 获取单例实例
   * 
   * @returns SpeechRecognitionService 的全局唯一实例
   */
  static getInstance(): SpeechRecognitionService {
    if (!SpeechRecognitionService.instance) {
      SpeechRecognitionService.instance = new SpeechRecognitionService();
    }
    return SpeechRecognitionService.instance;
  }

  /**
   * 检查并申请麦克风权限
   * 
   * @param context - UIAbility 上下文
   * @returns Promise<boolean> - true 表示权限已授予，false 表示权限被拒绝
   */
  async checkMicrophonePermission(context: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']);
      return grantStatus.authResults[0] === 0;
    } catch (err) {
      console.error('Permission check failed:', err);
      return false;
    }
  }

  /**
   * 初始化语音识别服务
   * 
   * 创建语音识别引擎并设置监听器。如果已经初始化，则直接更新回调函数。
   * 
   * @param callbacks - 回调函数集合
   * @returns Promise<boolean> - true 表示初始化成功，false 表示失败
   */
  async initialize(callbacks: SpeechRecognitionCallbacks): Promise<boolean> {
    if (this.isInitialized && this.asrEngine) {
      this.callbacks = callbacks;
      return true;
    }

    this.callbacks = callbacks;

    try {
      this.asrEngine = await speechRecognizer.createEngine({
        language: 'zh-CN',
        online: 1,
        extraParams: { 
          'locate': 'CN', 
          'recognizerMode': 'short'
        }
      });

      if (!this.asrEngine) {
        this.handleError(-1, 'Failed to create speech recognition engine');
        return false;
      }

      this.setupListener();
      this.isInitialized = true;
      return true;
    } catch (err) {
      this.handleError(-1, `Initialization failed: ${err}`);
      return false;
    }
  }

  /**
   * 设置语音识别监听器
   * 
   * 配置引擎的各种事件回调，包括开始、结果、完成、错误和事件回调。
   */
  private setupListener(): void {
    if (!this.asrEngine) return;

    this.asrEngine.setListener({
      onStart: (sessionId: string, eventMessage: string) => {
        console.info('ASR start:', sessionId, eventMessage);
        this.updateState('listening');
        this.startNoSpeechTimer();
      },

      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        console.info('ASR result:', JSON.stringify(result));
        this.resetNoSpeechTimer();

        const recognitionResult: SpeechRecognitionResult = {
          text: result.result || '',
          isFinal: result.isFinal,
          confidence: 1.0
        };

        if (this.callbacks) {
          this.callbacks.onResult(recognitionResult);
        }

        if (result.isFinal) {
          this.clearNoSpeechTimer();
          this.updateState('success');
        }
      },

      onComplete: (sessionId: string, eventMessage: string) => {
        console.info('ASR complete:', sessionId, eventMessage);
        this.clearNoSpeechTimer();
      },

      onError: (sessionId: string, errorCode: number, errorMessage: string) => {
        console.error('ASR error:', errorCode, errorMessage);
        this.clearNoSpeechTimer();
        this.handleError(errorCode, errorMessage);
      },

      onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
        console.info('ASR event:', eventCode, eventMessage);
      }
    });
  }

  /**
   * 开始监听语音输入
   * 
   * 启动语音识别引擎，开始接收麦克风输入。
   * 
   * @returns Promise<boolean> - true 表示启动成功，false 表示失败
   */
  async startListening(): Promise<boolean> {
    if (!this.asrEngine) {
      this.handleError(-1, 'Engine not initialized');
      return false;
    }

    try {
      this.sessionId = `asr_${Date.now()}`;
      
      const audioParam: speechRecognizer.AudioInfo = {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      };

      const startParams: speechRecognizer.StartParams = {
        sessionId: this.sessionId,
        audioInfo: audioParam
      };

      this.startVolumeSimulation();
      await this.asrEngine.startListening(startParams);
      this.updateState('listening');
      return true;
    } catch (err) {
      this.handleError(-1, `Start listening failed: ${err}`);
      return false;
    }
  }

  /**
   * 停止监听并完成识别
   * 
   * 停止接收语音输入，但会继续处理已接收的音频数据。
   */
  async stopListening(): Promise<void> {
    if (this.asrEngine && this.sessionId) {
      try {
        await this.asrEngine.finish(this.sessionId);
      } catch (err) {
        console.error('Stop listening error:', err);
      }
    }
    this.stopVolumeSimulation();
    this.clearNoSpeechTimer();
  }

  /**
   * 取消当前识别
   * 
   * 取消语音识别，丢弃所有已接收的音频数据。
   */
  async cancel(): Promise<void> {
    if (this.asrEngine && this.sessionId) {
      try {
        await this.asrEngine.cancel(this.sessionId);
      } catch (err) {
        console.error('Cancel error:', err);
      }
    }
    this.stopVolumeSimulation();
    this.clearNoSpeechTimer();
    this.updateState('idle');
  }

  /**
   * 关闭语音识别服务
   * 
   * 释放语音识别引擎资源，重置所有状态。
   */
  async shutdown(): Promise<void> {
    await this.stopListening();
    if (this.asrEngine) {
      try {
        await this.asrEngine.shutdown();
      } catch (err) {
        console.error('Shutdown error:', err);
      }
      this.asrEngine = null;
      this.isInitialized = false;
    }
  }

  /**
   * 更新识别状态
   * 
   * @param state - 新的识别状态
   */
  private updateState(state: SpeechRecognitionState): void {
    this.currentState = state;
    if (this.callbacks) {
      this.callbacks.onStateChange(state);
    }
  }

  /**
   * 处理错误
   * 
   * @param code - 错误码
   * @param message - 错误信息
   */
  private handleError(code: number, message: string): void {
    this.updateState('error');
    if (this.callbacks) {
      this.callbacks.onError({ code, message });
    }
  }

  /**
   * 启动音量模拟
   * 
   * 由于部分设备不支持实时音量回调，使用正弦波模拟音量变化。
   * 音量值范围：0-100
   */
  private startVolumeSimulation(): void {
    let phase = 0;
    this.volumeTimer = setInterval(() => {
      if (this.currentState !== 'listening') {
        this.stopVolumeSimulation();
        return;
      }
      phase += 0.15;
      const volume = Math.abs(Math.sin(phase)) * 100;
      if (this.callbacks) {
        this.callbacks.onVolumeChange(volume);
      }
    }, 100);
  }

  /**
   * 停止音量模拟
   */
  private stopVolumeSimulation(): void {
    if (this.volumeTimer !== -1) {
      clearInterval(this.volumeTimer);
      this.volumeTimer = -1;
    }
  }

  /**
   * 启动无语音超时计时器
   * 
   * 如果在指定时间内没有检测到语音输入，自动停止识别。
   */
  private startNoSpeechTimer(): void {
    this.clearNoSpeechTimer();
    this.noSpeechTimer = setTimeout(() => {
      console.info('No speech detected, stopping');
      this.stopListening();
      this.handleError(-2, '未检测到语音输入');
    }, this.NO_SPEECH_TIMEOUT);
  }

  /**
   * 重置无语音超时计时器
   * 
   * 当检测到语音输入时调用，重置超时计时。
   */
  private resetNoSpeechTimer(): void {
    if (this.noSpeechTimer !== -1) {
      this.startNoSpeechTimer();
    }
  }

  /**
   * 清除无语音超时计时器
   */
  private clearNoSpeechTimer(): void {
    if (this.noSpeechTimer !== -1) {
      clearTimeout(this.noSpeechTimer);
      this.noSpeechTimer = -1;
    }
  }

  /**
   * 获取当前识别状态
   * 
   * @returns 当前识别状态
   */
  getState(): SpeechRecognitionState {
    return this.currentState;
  }

  /**
   * 检查服务是否就绪
   * 
   * @returns true 表示服务已初始化并可用
   */
  isReady(): boolean {
    return this.isInitialized && this.asrEngine !== null;
  }
}