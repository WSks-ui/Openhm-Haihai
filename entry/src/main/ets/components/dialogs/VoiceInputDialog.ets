import { SpeechRecognitionService, SpeechRecognitionState, SpeechRecognitionError } from '../../utils/SpeechRecognitionService';
import { common, Want, ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { BRAND_PRIMARY } from '../../constants/ThemeTokens';

export interface VoiceInputCallbacks {
  onClose: () => void;
  onResult: (text: string) => void;
}

@CustomDialog
export struct VoiceInputDialog {
  controller: CustomDialogController;
  onClose: () => void = () => {};
  onResult: (text: string) => void = () => {};

  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State voiceState: SpeechRecognitionState = 'idle';
  @State recognizedText: string = '';
  @State volume: number = 0;
  @State waveHeights: number[] = [20, 30, 40, 50, 40, 30, 20];
  @State permissionDenied: boolean = false;
  @State errorMessage: string = '';

  private speechService: SpeechRecognitionService = SpeechRecognitionService.getInstance();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private waveAnimationTimer: number = -1;

  async aboutToAppear() {
    const hasPermission = await this.speechService.checkMicrophonePermission(this.context);
    
    if (!hasPermission) {
      this.permissionDenied = true;
      this.voiceState = 'error';
      this.errorMessage = '需要麦克风权限才能使用语音搜索';
      return;
    }

    await this.initializeSpeechRecognition();
  }

  private async initializeSpeechRecognition(): Promise<void> {
    const success = await this.speechService.initialize({
      onStateChange: (state: SpeechRecognitionState) => {
        this.voiceState = state;
        if (state === 'listening') {
          this.startWaveAnimation();
        } else {
          this.stopWaveAnimation();
        }
      },
      onResult: (result) => {
        if (result.text) {
          this.recognizedText = result.text;
        }
        if (result.isFinal && result.text) {
          setTimeout(() => {
            this.onResult(result.text);
            this.controller.close();
          }, 800);
        }
      },
      onError: (error: SpeechRecognitionError) => {
        this.errorMessage = this.getErrorMessage(error.code, error.message);
        this.stopWaveAnimation();
      },
      onVolumeChange: (volume: number) => {
        this.volume = volume;
        this.updateWaveHeights(volume);
      }
    });

    if (success) {
      await this.speechService.startListening();
    } else {
      this.voiceState = 'error';
      this.errorMessage = '语音识别初始化失败';
    }
  }

  private getErrorMessage(code: number, message: string): string {
    switch (code) {
      case -1:
        return message || '语音识别服务异常';
      case -2:
        return '未检测到语音输入';
      case 1001:
        return '录音权限被拒绝';
      case 1002:
        return '录音设备不可用';
      case 1003:
        return '录音中断';
      default:
        return `识别失败: ${message}`;
    }
  }

  private startWaveAnimation(): void {
    let phase = 0;
    this.waveAnimationTimer = setInterval(() => {
      phase += 0.15;
      const newHeights: number[] = [];
      for (let i = 0; i < 7; i++) {
        const base = Math.sin(phase + i * 0.8) * 30 + 40;
        const random = Math.random() * 10 - 5;
        newHeights.push(Math.max(15, Math.min(80, base + random)));
      }
      this.waveHeights = newHeights;
    }, 120);
  }

  private stopWaveAnimation(): void {
    if (this.waveAnimationTimer !== -1) {
      clearInterval(this.waveAnimationTimer);
      this.waveAnimationTimer = -1;
    }
  }

  private updateWaveHeights(volume: number): void {
    const scale = volume / 100;
    const newHeights = this.waveHeights.map(h => Math.max(15, Math.min(80, h * (0.5 + scale * 0.5))));
    this.waveHeights = newHeights;
  }

  openSystemSettings(): void {
    const want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: this.context.applicationInfo.name
      }
    };

    this.context.startAbility(want).catch(() => {
      const want2: Want = {
        action: 'action.settings.app.info',
        parameters: {
          settingsParamBundleName: this.context.applicationInfo.name
        }
      };
      this.context.startAbility(want2).catch(() => {
        promptAction.showToast({ message: '无法打开设置，请手动前往', duration: 2000 });
      });
    });
    this.controller.close();
  }

  async retry(): Promise<void> {
    this.voiceState = 'idle';
    this.recognizedText = '';
    this.errorMessage = '';
    await this.initializeSpeechRecognition();
  }

  aboutToDisappear() {
    this.stopWaveAnimation();
    this.speechService.cancel();
    this.onClose();
  }

  @Builder
  ListeningContent() {
    Column({ space: 20 }) {
      Text('正在聆听...')
        .fontSize(18)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
      
      Row({ space: 6 }) {
        ForEach(this.waveHeights, (height: number, index: number) => {
          Column()
            .width(4)
            .height(height)
            .backgroundColor('BRAND_PRIMARY')
            .borderRadius(2)
            .animation({ duration: 120, curve: Curve.EaseInOut })
        })
      }
      .height(80)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Button('取消')
        .width('80%')
        .height(40)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F5F5F5')
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#666666')
        .onClick(() => {
          this.controller.close();
        })
    }
  }

  @Builder
  RecognizingContent() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('BRAND_PRIMARY')
      
      Text('正在识别...')
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')
    }
  }

  @Builder
  SuccessContent() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
        .fontSize(40)
        .fontColor(['#34C759'])
      
      Text(this.recognizedText)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
    }
  }

  @Builder
  ErrorContent() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
        .fontSize(40)
        .fontColor(['#FF3B30'])
      
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#FF3B30')
        .textAlign(TextAlign.Center)
        .maxLines(2)

      if (this.permissionDenied) {
        Button('去设置开启权限')
          .backgroundColor('BRAND_PRIMARY')
          .fontColor(Color.White)
          .height(40)
          .width(160)
          .onClick(() => {
            this.openSystemSettings();
          })
      }

      Row({ space: 16 }) {
        Button('重试')
          .height(36)
          .fontSize(14)
          .backgroundColor('BRAND_PRIMARY')
          .fontColor(Color.White)
          .onClick(() => {
            this.retry();
          })
        
        Button('取消')
          .height(36)
          .fontSize(14)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F5F5F5')
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#666666')
          .onClick(() => {
            this.controller.close();
          })
      }
    }
  }

  @Builder
  PermissionDeniedContent() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.mic_slash_fill'))
        .fontSize(64)
        .fontColor(['#FF3B30'])
      
      Text('需要麦克风权限')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333333')
      
      Text('请在设置中开启麦克风权限以使用语音搜索功能')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')
        .textAlign(TextAlign.Center)

      Button('去设置开启权限')
        .backgroundColor('BRAND_PRIMARY')
        .fontColor(Color.White)
        .height(44)
        .width(180)
        .onClick(() => {
          this.openSystemSettings();
        })

      Button('取消')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F5F5F5')
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#666666')
        .height(44)
        .width(180)
        .onClick(() => {
          this.controller.close();
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ top: 30, bottom: 30 })
  }

  build() {
    Column() {
      if (this.permissionDenied) {
        this.PermissionDeniedContent()
      } else {
        Column({ space: 20 }) {
          if (this.voiceState === 'listening') {
            this.ListeningContent()
          } else if (this.voiceState === 'recognizing') {
            this.RecognizingContent()
          } else if (this.voiceState === 'success') {
            this.SuccessContent()
          } else if (this.voiceState === 'error') {
            this.ErrorContent()
          } else {
            this.ListeningContent()
          }
        }
        .width('100%')
        .padding(24)
      }
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)' })
  }
}