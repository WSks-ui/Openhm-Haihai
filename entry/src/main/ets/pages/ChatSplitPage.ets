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

interface MessageItem {
  id: number;
  userName: string;
  avatar: string;
  lastMessage: string;
  time: string;
  isPinned: boolean;
  lastInteractionTime: number;
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

function formatDateTime(timestamp: number): string {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}`;
}

function truncateText(text: string, maxLength: number = 15): string {
  if (text.length <= maxLength) {
    return text;
  }
  return text.substring(0, maxLength) + '...';
}

@Entry
@Component
struct ChatSplitPage {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;

  @State selectedUserId: number = 1;
  @State selectedUserName: string = 'Qwen';
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isTyping: boolean = false;
  @State apiKey: string = '';
  @State showApiKeyDialog: boolean = false;
  @State tempApiKey: string = '';
  @State isVideoChat: boolean = false;
  @State videoChatUrl: string = 'https://huggingface.co/spaces/HumanAIGC-Engineering-Team/open-avatar-chat';
  @State webLoading: boolean = false;

  private scroller: Scroller = new Scroller();
  private rdbStore: relationalStore.RdbStore | null = null;
  private webController: webview.WebviewController = new webview.WebviewController();

  @State messageItems: MessageItem[] = [
    { id: 1, userName: 'Qwen', avatar: 'pexels-anastasia-shuraeva-4210032.jpg', lastMessage: '祝你今天过得愉快！', time: '2026-03-09 12:00', isPinned: true, lastInteractionTime: Date.now() },
    { id: 2, userName: '好友 2', avatar: 'pexels-angela-roma-7363753.jpg', lastMessage: '明天一起去喝咖啡吗？', time: '2026-03-09 11:30', isPinned: true, lastInteractionTime: Date.now() - 1800000 },
    { id: 3, userName: '好友 3', avatar: 'pexels-cedric-fauntleroy-7221389.jpg', lastMessage: '那个项目进展如何？', time: '2026-03-08 10:00', isPinned: true, lastInteractionTime: Date.now() - 86400000 }
  ];

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
  });

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['userId']) {
      this.selectedUserId = params['userId'] as number;
    }
    if (params && params['userName']) {
      this.selectedUserName = params['userName'] as string;
    }
    this.loadChatHistoryForSelectedUser();
    this.loadApiKey();
    this.loadAllChatPreviews();
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

  loadAllChatPreviews() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;

      for (let i = 0; i < this.messageItems.length; i++) {
        const item = this.messageItems[i];
        const fileName = `chat_history_${item.id}.json`;
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
              if (parsed.length > 0) {
                const lastMsg = parsed[parsed.length - 1];
                if (lastMsg.content) {
                  item.lastMessage = truncateText(lastMsg.content);
                  item.lastInteractionTime = Date.now();
                  item.time = formatDateTime(Date.now());
                }
              }
            }
          }
          fs.closeSync(file);
        }
      }
    } catch (e) {
      console.error('加载聊天记录预览失败', e);
    }
  }

  loadChatHistoryForSelectedUser() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = `chat_history_${this.selectedUserId}.json`;
      const filePath = `${filesDir}/${fileName}`;

      this.messages = [];

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

  saveChatHistory() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = `chat_history_${this.selectedUserId}.json`;
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

      this.loadAllChatPreviews();
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

  sendMessage() {
    if (this.inputText.trim().length > 0) {
      const newMsg = new ChatMessage(`m_${Date.now()}`, this.inputText, true, '刚刚');
      this.messages.push(newMsg);
      this.saveChatHistory();
      this.inputText = '';
      this.isTyping = true;

      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 80);

      this.callDeepSeekAPI(newMsg.content);
    }
  }

  async callDeepSeekAPI(userMessage: string): Promise<void> {
    const key = this.apiKey;
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
        this.saveChatHistory();
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
      this.saveChatHistory();
    } finally {
      this.isTyping = false;
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  selectUser(userId: number, userName: string) {
    this.selectedUserId = userId;
    this.selectedUserName = userName;
    this.loadChatHistoryForSelectedUser();
  }

  build() {
    Row() {
      this.FriendListPanel()
      Divider()
        .width(1)
        .height('100%')
        .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)')
      this.ChatContentPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  @Builder
  FriendListPanel() {
    Column() {
      Column() {
        Row() {
          Text('好友')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      .alignItems(HorizontalAlign.Start)

      List() {
        ForEach(this.messageItems, (item: MessageItem) => {
          ListItem() {
            this.FriendListItem(item)
          }
        }, (item: MessageItem) => item.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
    }
    .width('35%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
  }

  @Builder
  FriendListItem(item: MessageItem) {
    Row() {
      Image(item.avatar.startsWith('app.media.') ? $r(item.avatar) : $rawfile(item.avatar))
        .width(48)
        .height(48)
        .borderRadius(24)
        .objectFit(ImageFit.Cover)
        .border({
          width: this.selectedUserId === item.id ? 2 : 0,
          color: '#7B68EE'
        })
      Column({ space: 4 }) {
        Row() {
          if (item.isPinned) {
            SymbolGlyph($r('sys.symbol.pin'))
              .fontSize(12)
              .fontColor(['#7B68EE'])
              .margin({ right: 2 })
          }
          Text(item.userName)
            .fontSize(15)
            .fontWeight(this.selectedUserId === item.id ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')
        }
        Text(truncateText(item.lastMessage, 12))
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
          .maxLines(1)
      }
      .layoutWeight(1)
      .padding({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.selectedUserId === item.id ?
      (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.2)' : 'rgba(123, 104, 238, 0.1)') :
      Color.Transparent)
    .onClick(() => {
      this.selectUser(item.id, item.userName);
    })
  }

  @Builder
  ChatContentPanel() {
    Column() {
      Row() {
        Text(this.isVideoChat ? '视频聊天' : this.selectedUserName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
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
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')

      if (this.isVideoChat) {
        this.VideoChatBuilder()
      } else {
        this.ChatMessageBuilder()
      }
    }
    .width('65%')
    .height('100%')
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
              Text('开始和 ' + this.selectedUserName + ' 聊天吧！')
                .fontSize(16)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
            }
            .width('100%')
            .padding({ top: 50 })
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
                  }
                } else {
                  Row() {
                    Text(msg.content)
                      .fontSize(16)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')
                      .padding(12)
                      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
                      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 12 })
                  }
                  Blank()
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            }
          }, (msg: ChatMessage) => msg.id)
        }

        if (this.isTyping) {
          ListItem() {
            Row() {
              Row() {
                Text('正在输入...')
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
              }
              .padding(12)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
              .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 12 })
            }
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
      }
      .width('100%')
      .layoutWeight(1)

      Row() {
        TextInput({ placeholder: '发送消息...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F2F2F7')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        SymbolGlyph($r('sys.symbol.paperplane_fill'))
          .fontSize(24)
          .fontColor(['#7B68EE'])
          .margin({ left: 12 })
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    }
    .width('100%')
    .height('100%')
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
  contentBuilder() {
    Column({ space: 16 }) {
      Text('设置 DeepSeek API Key')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')

      TextInput({ placeholder: '请输入 API Key', text: this.tempApiKey })
        .width('100%')
        .height(44)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F2F2F7')
        .onChange((value: string) => {
          this.tempApiKey = value;
        })

      Row({ space: 12 }) {
        Button('删除Key')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#FF3B30')
          .fontColor(Color.White)
          .onClick(() => {
            this.onDelete();
            this.controller.close();
          })

        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F2F2F7')
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')
          .onClick(() => {
            this.onCancel();
            this.controller.close();
          })

        Button('保存')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#7B68EE')
          .fontColor(Color.White)
          .onClick(() => {
            if (this.tempApiKey.trim()) {
              this.onSave(this.tempApiKey.trim());
              this.controller.close();
            }
          })
      }
    }
    .width('100%')
    .padding(20)
  }

  build() {
    Column() {
      this.contentBuilder()
    }
    .width('90%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
  }
}
