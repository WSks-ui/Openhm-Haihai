import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';

@Component
export struct ChatInputBar {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Link inputText: string;
  @Link isTyping: boolean;
  @Link isReasoning: boolean;
  @Link isSearchEnabled: boolean;
  @Link isListening: boolean;
  @Link speechVolume: number;
  @Prop tavilyApiKey: string;
  @Prop apiKey: string;

  onSendMessage: () => void = () => {};
  onStartSpeech: () => void = () => {};
  onStopSpeech: () => void = () => {};
  onOpenSettings: () => void = () => {};

  build() {
    Column() {
      Column() {
        TextInput({
          placeholder: '发送消息或按住说话',
          text: $$this.inputText
        })
          .enterKeyType(EnterKeyType.Send)
          .width('100%')
          .height(48)
          .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' :
            '#9AA1A9')
          .fontSize(16)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
          .margin({ bottom: 12 })
          .enabled(!this.isTyping)
          .focusable(true)
          .focusOnTouch(true)
          .onSubmit(() => this.onSendMessage())

        Row() {
          Row({ space: 12 }) {
            this.ReasoningToggle()
            this.SearchToggle()
          }

          Blank()

          if (this.isTyping) {
            this.StopButton()
          } else {
            this.ActionButtons()
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' :
        Color.White)
      .borderRadius(32)
      .shadow({
        radius: 30,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0, 0, 0, 0.3)' :
          'rgba(0, 0, 0, 0.08)',
        offsetY: 10
      })
      .border({
        width: 1,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.15)' :
          'transparent'
      })
      .padding(20)

      Text('由 DeepSeek 提供技术支持 • AI 生成内容')
        .fontSize(10)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#AAA')
        .margin({ top: 12, bottom: 4 })
    }
    .width('100%')
    .constraintSize({ maxWidth: 860 })
    .padding({
      left: 16,
      right: 16,
      bottom: 0,
      top: 8
    })
    .backgroundColor(Color.Transparent)
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  ReasoningToggle() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_clockwise'))
        .fontSize(16)
        .fontColor(['#3478F6'])
      Text('思考')
        .fontSize(14)
        .fontColor(this.isReasoning ? '#3478F6' :
          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666'))
        .fontWeight(FontWeight.Medium)
        .margin({ left: 6 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
      Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: this.isReasoning ? '#3478F6' :
        (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E5E7EB')
    })
    .onClick(() => {
      this.isReasoning = !this.isReasoning;
    })
  }

  @Builder
  SearchToggle() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(16)
        .fontColor(['#3478F6'])
      Text('搜索')
        .fontSize(14)
        .fontColor(this.isSearchEnabled ? '#3478F6' :
          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666'))
        .fontWeight(FontWeight.Medium)
        .margin({ left: 6 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
      Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: this.isSearchEnabled ? '#3478F6' :
        (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E5E7EB')
    })
    .onClick(() => {
      if (!this.isSearchEnabled && !this.tavilyApiKey) {
        promptAction.showToast({ message: '请先设置 Tavily API Key', duration: 2000 });
        this.onOpenSettings();
        return;
      }
      this.isSearchEnabled = !this.isSearchEnabled;
    })
  }

  @Builder
  StopButton() {
    Button({ type: ButtonType.Capsule }) {
      Text('停止生成')
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' :
          '#D32F2F')
        .fontSize(15)
    }
    .width(100)
    .height(48)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#5C1D1D' :
      '#FFEBEE')
    .onClick(() => {
      this.isTyping = false;
      promptAction.showToast({ message: '已停止生成', duration: 1500 });
    })
  }

  @Builder
  ActionButtons() {
    Row({ space: 8 }) {
      if (this.isListening) {
        this.VoiceRecordingButton()
      } else {
        this.VoiceButton()
      }
      this.SendButton()
    }
  }

  @Builder
  VoiceRecordingButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(40)
          .height(40)
          .fill(Color.Transparent)
          .stroke('#FF5252')
          .strokeWidth(2)
          .scale({
            x: 1 + (this.speechVolume / 100) * 0.3,
            y: 1 + (this.speechVolume / 100) * 0.3
          })
          .opacity(0.5 + (this.speechVolume / 100) * 0.5)

        Circle()
          .width(32)
          .height(32)
          .fill('#FF5252')

        SymbolGlyph($r('sys.symbol.mic'))
          .fontSize(20)
          .fontColor([Color.White])
      }
    }
    .width(48)
    .height(48)
    .backgroundColor(Color.Transparent)
    .onClick(() => this.onStopSpeech())
  }

  @Builder
  VoiceButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.mic'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666'])
    }
    .width(48)
    .height(48)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
      Color.White)
    .border({
      width: 1,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E5E7EB'
    })
    .onClick(() => this.onStartSpeech())
  }

  @Builder
  SendButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.paperplane_fill'))
        .fontSize(22)
        .fontColor(['#3478F6'])
    }
    .width(48)
    .height(48)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
      Color.White)
    .border({
      width: 1,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E5E7EB'
    })
    .onClick(() => this.inputText.trim() && this.onSendMessage())
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
  }
}
