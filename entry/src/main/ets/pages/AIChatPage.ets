import router from '@ohos.router';
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import window from '@ohos.window';
import promptAction from '@ohos.promptAction';

import { ChatMessage, MAX_MESSAGES } from './aichat/types';
import { chatStorage } from './aichat/storage';
import { deepSeekService } from './aichat/deepseek';
import { tavilySearchService } from './aichat/tavily';
import { SpeechRecognitionService, SpeechRecognitionResult, SpeechRecognitionError, SpeechRecognitionState } from '../utils/SpeechRecognitionService';
import { MessageBubble } from './aichat/MessageBubble';
import { SuggestionCards } from './aichat/SuggestionCards';
import { ChatInputBar } from './aichat/ChatInputBar';
import { ChatHeaderBar } from './aichat/ChatHeaderBar';
import { ApiKeyDialog } from './aichat/ApiKeyDialog';

@Entry
@Component
struct AIChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isTyping: boolean = false;
  @State apiKey: string = '加载中...';
  @State tavilyApiKey: string = '';
  @State showApiKeyDialog: boolean = false;
  @State tempApiKey: string = '';
  @State tempTavilyKey: string = '';
  @State isReasoning: boolean = false;
  @State isSearchEnabled: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;

  @State keyboardHeight: number = 0;
  private inputBarHeight: number = 160;

  @State isListening: boolean = false;
  @State speechVolume: number = 0;

  private speechService: SpeechRecognitionService = SpeechRecognitionService.getInstance();
  private scroller: Scroller = new Scroller();

  private dialogController: CustomDialogController = new CustomDialogController({
    builder: ApiKeyDialog({
      tempApiKey: this.tempApiKey,
      tempTavilyKey: this.tempTavilyKey,
      onCancel: () => {
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      },
      onDelete: async () => {
        await chatStorage.deleteApiKeys();
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      },
      onSave: async (key: string, tavilyKey: string) => {
        let finalKey = key;
        if (this.apiKey && this.apiKey.length > 8) {
          const masked = this.apiKey.substring(0, 8) + '****************';
          if (key === masked) {
            finalKey = this.apiKey;
          }
        }

        let finalTavilyKey = tavilyKey;
        if (this.tavilyApiKey && this.tavilyApiKey.length > 8) {
          const maskedTavily = this.tavilyApiKey.substring(0, 8) + '****************';
          if (tavilyKey === maskedTavily) {
            finalTavilyKey = this.tavilyApiKey;
          }
        }

        await chatStorage.saveApiKeys(finalKey, finalTavilyKey);
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    customStyle: true
  })

  async aboutToAppear(): Promise<void> {
    const context = getContext(this);
    await chatStorage.initialize(context);
    await this.loadApiKeys();
    this.loadHistory();

    this.setupKeyboardListener();
    await this.initializeSpeechService();

    if (!this.apiKey.trim()) {
      this.tempApiKey = '';
      this.tempTavilyKey = '';
      this.dialogController.open();
    }
  }

  aboutToDisappear(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      window.getLastWindow(context).then((win) => {
        win.off('keyboardHeightChange');
      });
    } catch (e) {
      console.error('移除键盘监听失败', e);
    }

    this.speechService.shutdown();
  }

  private async initializeSpeechService(): Promise<void> {
    try {
      await this.speechService.initialize({
        onStateChange: (state: SpeechRecognitionState) => {
          this.handleSpeechStateChange(state);
        },
        onResult: (result: SpeechRecognitionResult) => {
          this.handleSpeechResult(result);
        },
        onError: (error: SpeechRecognitionError) => {
          this.handleSpeechError(error);
        },
        onVolumeChange: (volume: number) => {
          this.speechVolume = volume;
        }
      });
    } catch (e) {
      console.error('初始化语音识别服务失败', e);
    }
  }

  private handleSpeechStateChange(state: SpeechRecognitionState): void {
    this.isListening = state === 'listening' || state === 'recognizing';
    if (state === 'success') {
      promptAction.showToast({ message: '语音识别完成', duration: 1500 });
    }
  }

  private handleSpeechResult(result: SpeechRecognitionResult): void {
    if (result.text) {
      this.inputText = result.text;
      if (result.isFinal && result.text.trim()) {
        setTimeout(() => {
          this.sendMessage();
        }, 500);
      }
    }
  }

  private handleSpeechError(error: SpeechRecognitionError): void {
    console.error('语音识别错误:', error.code, error.message);
    this.isListening = false;
    this.speechVolume = 0;
    let errorMsg = '语音识别失败';
    if (error.code === -2) {
      errorMsg = error.message;
    } else if (error.message.includes('permission') || error.message.includes('权限')) {
      errorMsg = '麦克风权限被拒绝，请在设置中开启';
    }
    promptAction.showToast({ message: errorMsg, duration: 2000 });
  }

  private async startSpeechInput(): Promise<void> {
    if (this.isTyping) {
      promptAction.showToast({ message: '请等待AI回复完成', duration: 1500 });
      return;
    }

    const context = getContext(this) as common.UIAbilityContext;
    const hasPermission = await this.speechService.checkMicrophonePermission(context);
    if (!hasPermission) {
      promptAction.showToast({ message: '需要麦克风权限', duration: 2000 });
      return;
    }

    if (this.isListening) {
      await this.stopSpeechInput();
      return;
    }

    const started = await this.speechService.startListening();
    if (!started) {
      promptAction.showToast({ message: '启动语音识别失败', duration: 1500 });
    }
  }

  private async stopSpeechInput(): Promise<void> {
    await this.speechService.stopListening();
  }

  private setupKeyboardListener(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      window.getLastWindow(context).then((win) => {
        win.on('keyboardHeightChange', (height: number) => {
          this.keyboardHeight = px2vp(height);
          if (height > 0) {
            setTimeout(() => {
              this.scroller.scrollEdge(Edge.Bottom);
            }, 100);
          }
        });
      });
    } catch (e) {
      console.error('设置键盘监听失败', e);
    }
  }

  private loadHistory(): void {
    this.messages = chatStorage.loadChatHistory();
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  private saveHistory(): void {
    chatStorage.saveChatHistory(this.messages);
  }

  private async loadApiKeys(): Promise<void> {
    const keys = await chatStorage.loadApiKeys();
    this.apiKey = keys.deepseekApiKey;
    this.tavilyApiKey = keys.tavilyApiKey;
    deepSeekService.setApiKey(keys.deepseekApiKey);
    tavilySearchService.setApiKey(keys.tavilyApiKey);
  }

  clearHistory(): void {
    this.messages = [chatStorage.createWelcomeMessage()];
    this.saveHistory();
    try {
      promptAction.showToast({ message: '聊天记录已清空', duration: 1500 });
    } catch (error) {
      console.error('showToast failed', error);
    }
  }

  private openApiKeyDialog(): void {
    if (this.apiKey && this.apiKey.length > 8) {
      this.tempApiKey = this.apiKey.substring(0, 8) + '****************';
    } else {
      this.tempApiKey = this.apiKey;
    }

    if (this.tavilyApiKey && this.tavilyApiKey.length > 8) {
      this.tempTavilyKey = this.tavilyApiKey.substring(0, 8) + '****************';
    } else {
      this.tempTavilyKey = this.tavilyApiKey;
    }
    this.dialogController.open();
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text) {
      return;
    }

    const userMsg = chatStorage.createUserMessage(text);
    this.messages = [...this.messages, userMsg].slice(-MAX_MESSAGES);
    this.saveHistory();
    this.inputText = '';
    this.isTyping = true;

    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 80);

    try {
      let searchResults: string | undefined;
      if (this.tavilyApiKey && this.isSearchEnabled) {
        try {
          searchResults = await tavilySearchService.search(text);
        } catch (e) {
          console.error('Tavily 搜索失败', e);
        }
      }

      const result = await deepSeekService.sendMessage(text, this.messages, this.isReasoning, searchResults);
      const aiMsg = chatStorage.createAiMessage(result.reply, result.segments);
      this.messages = [...this.messages, aiMsg].slice(-MAX_MESSAGES);
      this.saveHistory();
    } catch (err) {
      const error = err as BusinessError;
      const tip = deepSeekService.handleApiError(error);
      const errorMsg = chatStorage.createErrorMessage(tip);
      this.messages = [...this.messages, errorMsg].slice(-MAX_MESSAGES);
      this.saveHistory();
    } finally {
      this.isTyping = false;
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  @Builder
  ContextMenuBuilder(msg: ChatMessage, index: number) {
    Menu() {
      MenuItem({ content: '复制' })
        .onClick(() => {
          try {
            promptAction.showToast({ message: '已复制到剪贴板', duration: 1500 });
          } catch (error) {
            console.error('showToast failed', error);
          }
        })

      if (msg.isUser) {
        MenuItem({ content: '撤回' })
          .onClick(() => {
            this.messages.splice(index, 1);
            this.saveHistory();
            try {
              promptAction.showToast({ message: '已撤回', duration: 1500 });
            } catch (error) {
              console.error('showToast failed', error);
            }
          })
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        ChatHeaderBar({
          onClearHistory: () => this.clearHistory(),
          onOpenSettings: () => this.openApiKeyDialog()
        })
      }
      .width('100%')
      .padding({ top: this.safeAreaTop + 2 })
      .zIndex(10)
      .hitTestBehavior(HitTestMode.Transparent)

      Stack({ alignContent: Alignment.Bottom }) {
        List({ scroller: this.scroller }) {
          if (this.messages.length <= 1 && this.inputText === '') {
            ListItem() {
              SuggestionCards({
                onSuggestionClick: (desc: string) => {
                  this.inputText = desc;
                  this.sendMessage();
                }
              })
            }
          }

          ForEach(this.messages, (msg: ChatMessage, index?: number) => {
            ListItem() {
              MessageBubble({ msg: msg })
            }
            .padding({ top: 6, bottom: 6 })
            .bindContextMenu(
              this.ContextMenuBuilder(msg, index ?? -1),
              ResponseType.LongPress
            )
          }, (item: ChatMessage) => item.id)

          if (this.isTyping) {
            ListItem() {
              Row() {
                Row() {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
                    .margin({ right: 8 })
                  Text('Kepler 正在思考...')
                    .fontSize(14)
                    .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
                }
                .padding(12)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' :
                  Color.White)
                .borderRadius({
                  topLeft: 4,
                  topRight: 20,
                  bottomLeft: 20,
                  bottomRight: 20
                })
                .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
                .margin({ left: 16 })
              }
            }
            .padding({ top: 6, bottom: 6 })
          }

          ListItem().height(60)
        }
        .width('100%')
        .height('100%')
        .constraintSize({ maxWidth: 860 })
        .scrollBar(BarState.Off)
        .padding({ top: this.safeAreaTop + 20, bottom: this.inputBarHeight })
        .clip(false)

        Column() {
          ChatInputBar({
            inputText: $inputText,
            isTyping: $isTyping,
            isReasoning: $isReasoning,
            isSearchEnabled: $isSearchEnabled,
            isListening: $isListening,
            speechVolume: $speechVolume,
            tavilyApiKey: this.tavilyApiKey,
            apiKey: this.apiKey,
            onSendMessage: () => this.sendMessage(),
            onStartSpeech: () => this.startSpeechInput(),
            onStopSpeech: () => this.stopSpeechInput(),
            onOpenSettings: () => this.openApiKeyDialog()
          })
        }
        .width('100%')
        .constraintSize({ maxWidth: 860 })
        .padding({ left: 16, right: 16, bottom: 0, top: 8 })
        .backgroundColor(Color.Transparent)
        .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.BOTTOM])
      }
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F8F9FC')
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
