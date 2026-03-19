import router from '@ohos.router';
import http from '@ohos.net.http';
import relationalStore from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import webview from '@ohos.web.webview';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';

/**
 * ChatDetailPage - 聊天详情页面
 * 
 * 沉浸式效果实现：
 * 1. 使用全局安全区域高度避开状态栏
 * 2. expandSafeArea 扩展页面到安全区域
 */

export class ChatMessage {
  id: string;
  content: string;
  isMe: boolean;
  time: string;

  constructor(id: string, content: string, isMe: boolean, time: string) {
    this.id = id;
    this.content = content;
    this.isMe = isMe;
    this.time = time;
  }
}

interface IChatMessage {
  id?: string;
  content?: string;
  isMe?: boolean;
  time?: string;
}

interface MessageRole {
  role: string;
  content: string;
}

interface AIResponseChoice {
  message: MessageRole;
}

interface AIResponse {
  choices: AIResponseChoice[];
}

interface APIPayload {
  model: string;
  messages: MessageRole[];
  stream: boolean;
  temperature: number;
  max_tokens: number;
}

@Entry
@Component
struct ChatDetailPage {
  @State userName: string = 'Chat';
  @State userId: number = 0;
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isTyping: boolean = false;
  @State apiKey: string = '';
  @State showApiKeyDialog: boolean = false;
  @State tempApiKey: string = '';
  @State isVideoChat: boolean = false;
  @State videoChatUrl: string = 'https://huggingface.co/spaces/HumanAIGC-Engineering-Team/open-avatar-chat';
  @State webLoading: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';
  
  // 沉浸式效果：安全区域高度
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  
  private scroller: Scroller = new Scroller();
  private rdbStore: relationalStore.RdbStore | null = null;
  private webController: webview.WebviewController = new webview.WebviewController();
  
  // CustomDialog controller
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: ApiKeyDialog({
      tempApiKey: this.tempApiKey,
      onCancel: () => {
        this.tempApiKey = '';
      },
      onDelete: async () => {
        await this.deleteApiKey();
        this.tempApiKey = '';
      },
      onSave: async (key: string) => {
        let finalKey = key;
        if (this.apiKey && this.apiKey.length > 8) {
          const masked = this.apiKey.substring(0, 8) + '****************';
          if (key === masked) {
            finalKey = this.apiKey;
          }
        }
        await this.saveApiKey(finalKey);
        this.tempApiKey = '';
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    customStyle: true
  })

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['userName']) {
      this.userName = params['userName'] as string;
    }
    if (params && params['userId']) {
      this.userId = params['userId'] as number;
    }
    this.loadApiKey();
    this.loadHistory();
  }

  async initRdb(): Promise<void> {
    if (this.rdbStore) {
      return;
    }
    try {
      const context = getContext(this);
      const config: relationalStore.StoreConfig = {
        name: 'ai_chat.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
    } catch (e) {
      console.error('RdbStore 初始化失败', e);
    }
  }

  async loadApiKey(): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'deepseek_api_key');
      let resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        this.apiKey = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();
    } catch (e) {
      console.error('加载 API Key 失败', e);
      this.apiKey = '';
    }
  }

  async saveApiKey(key: string): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = { key: 'deepseek_api_key', value: key.trim() };
      await this.rdbStore.insert('settings', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      this.apiKey = key.trim();
      promptAction.showToast({ message: 'API Key 已保存', duration: 2000 } as promptAction.ShowToastOptions);
    } catch (e) {
      console.error('保存 API Key 失败', e);
      promptAction.showToast({ message: '保存失败，请重试', duration: 2000 } as promptAction.ShowToastOptions);
    }
  }

  async deleteApiKey(): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'deepseek_api_key');
      await this.rdbStore.delete(predicates);
      this.apiKey = '';
      promptAction.showToast({ message: 'API Key 已删除', duration: 2000 } as promptAction.ShowToastOptions);
    } catch (e) {
      console.error('删除 API Key 失败', e);
      promptAction.showToast({ message: '删除失败，请重试', duration: 2000 } as promptAction.ShowToastOptions);
    }
  }

  loadHistory() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = this.userId > 0 ? `chat_history_${this.userId}.json` : `qwen_chat_history.json`;
      const filePath = `${filesDir}/${fileName}`;

      if (fs.accessSync(filePath)) {
        const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(filePath);
        if (stat.size > 0) {
          const buf = new ArrayBuffer(stat.size);
          fs.readSync(file.fd, buf);
          const decoder = util.TextDecoder.create('utf-8');
          const content = decoder.decodeWithStream(new Uint8Array(buf));
          if (content) {
            const parsed = JSON.parse(content) as IChatMessage[];
            this.messages = parsed.map((msg: IChatMessage) => {
              return new ChatMessage(
                msg.id || '',
                msg.content || '',
                msg.isMe || false,
                msg.time || ''
              );
            });
            setTimeout(() => {
              this.scroller.scrollEdge(Edge.Bottom);
            }, 100);
          }
        }
        fs.closeSync(file);
      }
    } catch (e) {
      console.error('加载聊天记录失败', e);
    }
  }

  saveHistory() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = this.userId > 0 ? `chat_history_${this.userId}.json` : `qwen_chat_history.json`;
      const filePath = `${filesDir}/${fileName}`;

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      const plainMessages = this.messages.map((msg: ChatMessage): IChatMessage => {
        return {
          id: msg.id,
          content: msg.content,
          isMe: msg.isMe,
          time: msg.time
        } as IChatMessage;
      });
      const content = JSON.stringify(plainMessages);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (e) {
      console.error('保存聊天记录失败', e);
    }
  }

  async requestPermissions(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = [
      'ohos.permission.CAMERA',
      'ohos.permission.MICROPHONE'
    ];
    
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const grantStatus = await atManager.requestPermissionsFromUser(context, permissions);
      
      if (grantStatus.authResults.every((result: number) => result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)) {
        return true;
      } else {
        promptAction.showToast({ message: '需要摄像头和麦克风权限才能进行视频聊天', duration: 2000 } as promptAction.ShowToastOptions);
        return false;
      }
    } catch (e) {
      console.error('请求权限失败', e);
      promptAction.showToast({ message: '请求权限失败，请在设置中开启权限', duration: 2000 } as promptAction.ShowToastOptions);
      return false;
    }
  }

  build() {
    Column() {
      // Top Bar
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333'])
          .onClick(() => {
            if (this.isVideoChat) {
              this.isVideoChat = false;
            } else {
              router.back();
            }
          })
        Text(this.isVideoChat ? '视频聊天' : this.userName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
          .margin({ left: 16 })
        Blank()
        
        if (!this.isVideoChat) {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.video'))
              .fontSize(22)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333'])
              .onClick(async () => {
                const hasPermission = await this.requestPermissions();
                if (hasPermission) {
                  this.isVideoChat = true;
                  this.webLoading = true;
                }
              })
            
            SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333'])
              .onClick(() => {
                this.tempApiKey = this.apiKey;
                if (this.tempApiKey && this.tempApiKey.length > 8) {
                  this.tempApiKey = this.tempApiKey.substring(0, 8) + '****************';
                }
                this.dialogController.open();
              })
          }
        } else {
          Button('结束视频')
            .height(32)
            .fontSize(14)
            .backgroundColor('#FF3B30')
            .fontColor(Color.White)
            .borderRadius(16)
            .onClick(() => {
              this.isVideoChat = false;
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
      .shadow({ radius: 4, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : '#0D000000', offsetY: 1 })
      .zIndex(10)

      if (this.isVideoChat) {
        this.VideoChatBuilder()
      } else {
        this.ChatMessageBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  VideoChatBuilder() {
    Stack({ alignContent: Alignment.Top }) {
      Web({ src: this.videoChatUrl, controller: this.webController })
        .width('115%')
        .height('115%')
        .margin({ top: '-15%' })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .mediaPlayGestureAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .onPageBegin(() => {
          this.webLoading = true;
        })
        .onPageEnd(() => {
          this.webLoading = false;
        })
        .onErrorReceive((event) => {
          console.error('Web加载错误:', event?.error.getErrorInfo());
          this.webLoading = false;
          promptAction.showToast({ message: '视频聊天加载失败，请检查网络', duration: 2000 } as promptAction.ShowToastOptions);
        })
        .onPermissionRequest((event) => {
          if (event && event.request) {
            event.request.grant(event.request.getAccessibleResource());
          }
        })
      
      if (this.webLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#7B68EE')
          Text('正在加载视频聊天...')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#666')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.9)')
      }
    }
    .layoutWeight(1)
    .width('100%')
    .clip(true)
  }

  @Builder
  ChatMessageBuilder() {
    Column() {
      List({ scroller: this.scroller }) {
        if (this.messages.length === 0) {
          ListItem() {
            Column() {
              Text('开始聊天吧！')
                .fontSize(16)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
            }
            .width('100%')
            .padding({ top: 100 })
          }
        } else {
          ForEach(this.messages, (msg: ChatMessage) => {
            ListItem() {
              Row() {
                if (msg.isMe) {
                  Blank()
                  Row() {
                    Text(msg.content)
                      .fontSize(16)
                      .fontColor(Color.White)
                      .padding(12)
                      .backgroundColor('#7B68EE')
                      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 0 })
                    
                    Image($rawfile(this.userAvatar))
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                      .margin({ left: 8 })
                      .objectFit(ImageFit.Cover)
                  }
                  .alignItems(VerticalAlign.Top)
                  .padding({ left: 40 })
                } else {
                  Row() {
                    Image($rawfile('pexels-anastasia-shuraeva-4210032.jpg'))
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                      .margin({ right: 8 })
                      .objectFit(ImageFit.Cover)
                    
                    Text(msg.content)
                      .fontSize(16)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
                      .padding(12)
                      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
                      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 12 })
                  }
                  .alignItems(VerticalAlign.Top)
                  .padding({ right: 40 })
                  Blank()
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            }
          }, (item: ChatMessage) => item.id)
        }
        
        if (this.isTyping) {
          ListItem() {
            Row() {
              Row() {
                Image($rawfile('pexels-anastasia-shuraeva-4210032.jpg'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .margin({ right: 8 })
                  .objectFit(ImageFit.Cover)
                
                Text('正在输入...')
                  .fontSize(16)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
                  .padding(12)
                  .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
                  .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 12 })
              }
              .alignItems(VerticalAlign.Top)
              .padding({ right: 40 })
              Blank()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')

      Row() {
        TextInput({ placeholder: '发送消息...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(20)
          .padding({ left: 16 })
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })
        
        Button('发送')
          .height(36)
          .fontSize(14)
          .backgroundColor('#7B68EE')
          .fontColor(Color.White)
          .borderRadius(18)
          .margin({ left: 12 })
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F9F9F9')
    }
    .layoutWeight(1)
    .width('100%')
  }

  sendMessage() {
    if (this.inputText.trim().length > 0) {
      const newMsg = new ChatMessage(`m_${Date.now()}`, this.inputText, true, '刚刚');
      this.messages.push(newMsg);
      this.saveHistory();
      this.inputText = '';
      this.isTyping = true;
      
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 80);
      
      this.callDeepSeekAPI(newMsg.content);
    }
  }

  async callDeepSeekAPI(userMessage: string): Promise<void> {
    const key = this.apiKey.trim();
    if (!key) {
      promptAction.showToast({ message: '请先设置DeepSeek API Key', duration: 2000 } as promptAction.ShowToastOptions);
      this.isTyping = false;
      return;
    }

    try {
      const history: MessageRole[] = this.messages
        .map((m: ChatMessage): MessageRole => {
          return {
            role: m.isMe ? 'user' : 'assistant',
            content: m.content
          } as MessageRole;
        });

      const messages: MessageRole[] = [
        {
          role: 'system',
          content: '你是Qwen，一个友好的AI助手。请用简洁、自然的语言回复用户。'
        } as MessageRole,
        ...history
      ];

      const httpRequest = http.createHttp();
      try {
        const payload: APIPayload = {
          model: 'deepseek-chat',
          messages: messages,
          stream: false,
          temperature: 0.7,
          max_tokens: 2000
        };

        const res = await httpRequest.request(
          'https://api.deepseek.com/chat/completions',
          {
            method: http.RequestMethod.POST,
            header: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${key}`
            },
            connectTimeout: 25000,
            readTimeout: 90000,
            extraData: JSON.stringify(payload)
          }
        );

        if (res.responseCode !== 200) {
          let errorMsg = `HTTP ${res.responseCode}`;
          try {
            const errData = JSON.parse(res.result as string) as Record<string, Object>;
            const errorObj = errData['error'] as Record<string, Object>;
            errorMsg += ` - ${(errorObj && errorObj['message'] || JSON.stringify(errData))}`;
          } catch {
          }
          throw new Error(errorMsg);
        }

        const data = JSON.parse(res.result as string) as AIResponse;
        const aiReply = data.choices?.[0]?.message?.content?.trim() || '（无有效回复）';
        
        const aiMsg = new ChatMessage(`a_${Date.now()}`, aiReply, false, '刚刚');
        this.messages.push(aiMsg);
        this.saveHistory();
      } catch (e) {
        if (e instanceof Error) {
          throw e;
        }
        throw new Error((e as BusinessError).message);
      } finally {
        httpRequest.destroy();
      }
    } catch (err) {
      const error = err as BusinessError;
      let tip = '抱歉，Qwen这边似乎出错了…稍后再试哦';
      if (error.message?.includes('401') || error.message?.includes('认证') ||
      error.message?.includes('Unauthorized')) {
        tip = 'API Key 无效或已过期，请重新设置哦～';
      } else if (error.message?.includes('402') || error.message?.includes('Payment Required') ||
      error.message?.includes('Insufficient Balance')) {
        tip = 'API Key 余额不足，请充值后使用哦～';
      } else if (/network|connect|timeout/i.test(error.message || '')) {
        tip = '网络好像不太稳定，请检查一下网络～';
      }
      
      const errorMsg = new ChatMessage(`e_${Date.now()}`, tip, false, '刚刚');
      this.messages.push(errorMsg);
      this.saveHistory();
    } finally {
      this.isTyping = false;
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }
}

@CustomDialog
struct ApiKeyDialog {
  @Link tempApiKey: string;
  controller: CustomDialogController;
  onCancel: () => void = () => {
  };
  onSave: (key: string) => void = (key: string) => {
  };
  onDelete: () => void = () => {
  };
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  DeleteMenu() {
    Menu() {
      MenuItem({ content: '删除 API Key' })
        .contentFontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' :
          '#F53F3F')
        .onClick(() => {
          this.onDelete();
          this.controller.close();
        })
    }
  }

  build() {
    Column() {
      Column() {
        Column() {
          Row() {
            Text('设置 API 密钥')
              .fontSize(18)
              .fontWeight(600)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            Blank()

            if (this.tempApiKey) {
              SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                .fontSize(20)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129'])
                .bindMenu(this.DeleteMenu())
            }
          }
          .width('100%')
          .margin({ bottom: 20 })
          .alignItems(VerticalAlign.Center)

          Column({ space: 8 }) {
            Text('DeepSeek API Key')
              .fontSize(14)
              .fontWeight(500)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            TextInput({ placeholder: '请输入 DeepSeek Key (sk-...)', text: $$this.tempApiKey })
              .type(InputType.Normal)
              .height(44)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                'rgba(255, 255, 255, 0.1)' : 'rgba(242, 243, 245, 0.2)')
              .borderRadius(6)
              .border({
                width: 1,
                color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.2)' :
                  'rgba(229, 230, 235, 0.5)'
              })
              .padding({ left: 12, right: 12 })
              .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#86909C')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Text('试用测试 Key')
            .fontSize(14)
            .fontColor('#165DFF')
            .margin({ top: 12 })
            .alignSelf(ItemAlign.End)
            .onClick(() => {
              this.onSave('sk-7e10c498229248a1a71b41e02c57267e');
              this.controller.close();
            })

          Row({ space: 12 }) {
            Button('取消')
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                'rgba(255, 255, 255, 0.15)' : 'rgba(242, 243, 245, 0.4)')
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
              .fontSize(14)
              .height(36)
              .onClick(() => {
                this.onCancel();
                this.controller.close();
              })
              .layoutWeight(1)

            Button('保存并使用')
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#165DFF')
              .fontColor(Color.White)
              .fontSize(14)
              .height(36)
              .shadow({ radius: 8, color: 'rgba(22, 93, 255, 0.3)', offsetY: 2 })
              .onClick(() => {
                this.onSave(this.tempApiKey);
                this.controller.close();
              })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 32 })
        }
        .width('100%')
        .padding(24)
        .borderRadius(24)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      }
    }
    .width('90%')
    .constraintSize({ maxWidth: 480 })
    .backgroundColor(Color.Transparent)
  }
}
