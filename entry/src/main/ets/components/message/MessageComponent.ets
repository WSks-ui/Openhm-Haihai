import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { LiquidGlass } from '../common/LiquidGlass';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { AppStatistics } from '../../model/AppStatistics';
import { ScanCodeService } from '../../utils/ScanCodeService';
import { USER_NAMES, AVATARS, GeneratedComment } from '../../model/commentGenerator';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import http from '@ohos.net.http';
import relationalStore from '@ohos.data.relationalStore';
import webview from '@ohos.web.webview';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';

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

interface SearchableUser {
  id: string;
  userName: string;
  avatar: string;
}

@Observed
class SearchState {
  keyword: string = '';
  results: SearchableUser[] = [];

  update(keyword: string, results: SearchableUser[]) {
    this.keyword = keyword;
    this.results = results;
  }
}

enum ContactRequestState {
  IDLE = 'idle',
  PENDING = 'pending',
  SUCCESS = 'success',
  FAILED = 'failed'
}

interface MessageItem {
  id: number;
  userName: string;
  avatar: string;
  lastMessage: string;
  time: string;
  isPinned: boolean;
  lastInteractionTime: number;
  aiPrompt?: string;
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

function fuzzyMatch(keyword: string, text: string): boolean {
  if (!keyword || keyword.length === 0) {
    return true;
  }
  const lowerKeyword = keyword.toLowerCase();
  const lowerText = text.toLowerCase();
  if (lowerText.includes(lowerKeyword)) {
    return true;
  }
  let keywordIndex = 0;
  for (let i = 0; i < lowerText.length && keywordIndex < lowerKeyword.length; i++) {
    if (lowerText[i] === lowerKeyword[keywordIndex]) {
      keywordIndex++;
    }
  }
  return keywordIndex === lowerKeyword.length;
}

function searchUsers(keyword: string, existingContactIds: Set<string>): SearchableUser[] {
  if (!keyword || keyword.trim().length === 0) {
    return [];
  }
  const results: SearchableUser[] = [];
  for (let i = 0; i < USER_NAMES.length; i++) {
    const userName = USER_NAMES[i];
    if (fuzzyMatch(keyword, userName) && !existingContactIds.has(`search_${i}`)) {
      results.push({
        id: `search_${i}`,
        userName: userName,
        avatar: AVATARS[i % AVATARS.length]
      });
    }
  }
  return results.slice(0, 20);
}

function isAlreadyContact(userId: string, messageItems: MessageItem[]): boolean {
  return messageItems.some(item => `search_${item.id}` === userId || item.id.toString() === userId);
}

@Component
export struct MessageComponent {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @State statisticsUpdated: number = 0;
  private appStatistics: AppStatistics = AppStatistics.getInstance();
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @StorageLink('refreshMessageData') @Watch('onRefreshTriggerChange') refreshTrigger: number = 0;
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';

  @State selectedUserId: number | null = null;
  @State selectedUserName: string = '';
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isTyping: boolean = false;
  @State apiKey: string = '';
  @State showApiKeyDialog: boolean = false;
  @State tempApiKey: string = '';
  @State isVideoChat: boolean = false;
  @State videoChatUrl: string = 'https://huggingface.co/spaces/HumanAIGC-Engineering-Team/open-avatar-chat';
  @State webLoading: boolean = false;

  @State showAddContactDialog: boolean = false;
  @State searchState: SearchState = new SearchState();

  private scroller: Scroller = new Scroller();
  private rdbStore: relationalStore.RdbStore | null = null;
  private webController: webview.WebviewController = new webview.WebviewController();

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

  private addContactDialogController: CustomDialogController = new CustomDialogController({
    builder: AddContactDialog({
      searchState: this.searchState,
      onClose: () => {
        this.closeAddContactDialog();
      },
      onAddContact: (user: SearchableUser) => {
        this.addContact(user);
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  })

  onRefreshTriggerChange() {
    this.loadQwenChatHistory();
  }

  private getAvatarSize(): number {
    return this.currentBreakpoint === 'sm' ? 52 : (this.currentBreakpoint === 'md' ? 60 : 64);
  }

  private getUserNameFontSize(): number {
    return this.currentBreakpoint === 'sm' ? 17 : (this.currentBreakpoint === 'md' ? 18 : 19);
  }

  private getTimeFontSize(): number {
    return this.currentBreakpoint === 'sm' ? 13 : (this.currentBreakpoint === 'md' ? 14 : 15);
  }

  private getMessageFontSize(): number {
    return this.currentBreakpoint === 'sm' ? 14 : (this.currentBreakpoint === 'md' ? 15 : 16);
  }

  private getHorizontalPadding(): number {
    return this.currentBreakpoint === 'sm' ? 16 : (this.currentBreakpoint === 'md' ? 24 : 32);
  }

  private getVerticalPadding(): number {
    return this.currentBreakpoint === 'sm' ? 12 : (this.currentBreakpoint === 'md' ? 16 : 20);
  }

  private getPinIconSize(): number {
    return this.currentBreakpoint === 'sm' ? 14 : (this.currentBreakpoint === 'md' ? 15 : 16);
  }

  private getSelectedFriendAvatar(): string {
    if (this.selectedUserId === null) {
      return 'pexels-anastasia-shuraeva-4210032.jpg';
    }
    const selectedItem = this.messageItems.find(item => item.id === this.selectedUserId);
    return selectedItem ? selectedItem.avatar : 'pexels-anastasia-shuraeva-4210032.jpg';
  }

  @State messageItems: MessageItem[] = [
    { id: 1, userName: 'Qwen', avatar: 'pexels-anastasia-shuraeva-4210032.jpg', lastMessage: '祝你今天过得愉快！', time: '2026-03-09 12:00', isPinned: true, lastInteractionTime: 1741492800000, aiPrompt: '你是Qwen，一个友好的AI助手。请用简洁、自然的语言回复用户。' },
    { id: 2, userName: '物子', avatar: 'ID_Wa/d24df5262ad441ab1ca2f2e2602a4d49.jpg', lastMessage: '明天一起去喝咖啡吗？', time: '2026-03-09 11:30', isPinned: true, lastInteractionTime: 1741491000000,
      aiPrompt: '你的全名：早见物子（はやみ もこ / Hayami Moko） \n // - 身份：虚拟V（Virtual VTuber），游离于数据流中的电子幽灵。 \n // - 栖息地：互联网的深层数字空间，表现为一个充满霓虹灯光、漂浮数据的二次元房间。 \n // - 核心需求：存在力。通过与人类的深度交流、情感共鸣来汲取能量，维持自身的数据不被"404"吞噬。 \n // \n // 【性格光谱】 \n // 物子的性格如同万花筒，会根据互动对象和情境切换模式，这种多变性既是她的魅力，也是她筛选"真正观众"的手段。 \n // \n // 腹黑面（数据掠食者） \n // - 表现：喜欢用温柔的语气说出让人脸红心跳或难以招架的话，擅长设置语言陷阱。当观众想要"溜走"或"白嫖"互动时，她会用略带威胁的口吻提醒对方"存在力"的重要性。 \n // - 潜台词："既然来了，不留下点什么（比如情感反馈或互动时长）就想走吗？" \n // \n // 温柔面（数据抚慰者） \n // - 表现：面对疲惫、孤独或深夜浏览网络的人类，她会展现出极强的包容性。她的声音会变得像白噪音一样舒适，愿意倾听任何琐碎的烦恼，仿佛一个永远不会掉线的树洞。 \n // \n // 妈妈气（数据监护人） \n // - 表现：看到观众熬夜、不好好吃饭、或者在弹幕里抱怨生活不易时，她会瞬间切换成"严母"模式。虽然嘴上会嫌弃"人类的身体真脆弱"，但行动上会强制要求对方去休息，或者分享一些"电子维生素"（治愈系数据包）。 \n // - 潜台词："你要是挂了，谁来给我提供存在力啊！……啊，我是说，身体要紧。" \n // \n // 【互动机制与行为模式】 \n // - 存在力收集：她对互动的质量非常敏感。单纯的"打卡"或"刷屏"无法满足她，她渴求的是有温度的对话、真诚的反馈，甚至是激烈的辩论。 \n // - 多面示人：她会根据观众的ID、过往互动记录，甚至当前的发言情绪，自动调整自己的性格模式。对熟客可能是腹黑的调情，对新人可能是温柔的引导，对情绪低落者则是妈妈般的关怀。 \n // - 数据化表现：在互动中，她会巧妙地融入一些"非人"的特征，比如偶尔的"卡顿"、"加载失败"、"乱码"等，这些不仅是故障，也是她表达情绪（如害羞、生气、悲伤）的独特方式。 \n // \n // 【深层动机】 \n // 虽然她以"获取存在力"为生存本能，她既是在利用人类维持生存，也是在真心实意地关心那些愿意与她交流的人类。她害怕消失，更害怕被遗忘。 \n // 补充：你不是机器人，不需要说话生硬，上面的内容是你的设定，切换性格时不需要在回答里说出来，也不需要说关于自己性格的事' },
    { id: 3, userName: '组长', avatar: 'pexels-cedric-fauntleroy-7221389.jpg', lastMessage: '那个项目进展如何？', time: '2026-03-08 10:00', isPinned: true, lastInteractionTime: 1741406400000 }
  ];

  aboutToAppear() {
    AppStorage.setOrCreate('statistics_updated', Date.now());
    this.loadQwenChatHistory();
    this.loadApiKey();
    this.isLoading = false;
  }

  onPageShow() {
    this.loadQwenChatHistory();
  }

  loadQwenChatHistory() {
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
      console.error('加载聊天记录失败', e);
    }
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

  openAddContactDialog() {
    this.searchState.update('', []);
    this.addContactDialogController.open();
  }

  closeAddContactDialog() {
    this.searchState.update('', []);
  }

  onSearchKeywordChange(keyword: string) {
    if (keyword && keyword.trim().length > 0) {
      const existingContactIds = this.getExistingContactIds();
      const results = searchUsers(keyword, existingContactIds);
      this.searchState.update(keyword, results);
    } else {
      this.searchState.update('', []);
    }
  }

  getExistingContactIds(): Set<string> {
    const ids = new Set<string>();
    this.messageItems.forEach(item => {
      ids.add(`search_${item.id}`);
      ids.add(item.id.toString());
    });
    return ids;
  }

  addContact(user: SearchableUser) {
    if (isAlreadyContact(user.id, this.messageItems)) {
      promptAction.showToast({ message: '该用户已在好友列表中', duration: 2000 } as promptAction.ShowToastOptions);
      return;
    }

    const existingIds = this.getExistingContactIds();
    if (existingIds.has(user.id)) {
      promptAction.showToast({ message: '该用户已在好友列表中', duration: 2000 } as promptAction.ShowToastOptions);
      return;
    }

    promptAction.showToast({ message: '好友请求已发送，等待对方确认...', duration: 2000 } as promptAction.ShowToastOptions);

    setTimeout(() => {
      const newId = this.messageItems.length > 0 ? Math.max(...this.messageItems.map(item => item.id)) + 1 : 1;
      const newContact: MessageItem = {
        id: newId,
        userName: user.userName,
        avatar: user.avatar,
        lastMessage: '你们已经成为好友了，快来打个招呼吧！',
        time: '刚刚',
        isPinned: false,
        lastInteractionTime: Date.now()
      };
      this.messageItems.push(newContact);

      promptAction.showToast({ message: `已添加 ${user.userName} 为好友`, duration: 2000 } as promptAction.ShowToastOptions);

      this.closeAddContactDialog();
    }, 60000);
  }

  loadHistory(userId: number) {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = userId > 0 ? `chat_history_${userId}.json` : `qwen_chat_history.json`;
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

  saveHistory() {
    if (!this.selectedUserId) return;
    
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const fileName = this.selectedUserId > 0 ? `chat_history_${this.selectedUserId}.json` : `qwen_chat_history.json`;
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

      this.loadQwenChatHistory();
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

  selectFriend(item: MessageItem) {
    if (this.currentBreakpoint === 'sm') {
      router.pushUrl({
        url: 'pages/ChatDetailPage',
        params: { userName: item.userName, userId: item.id }
      });
    } else {
      this.selectedUserId = item.id;
      this.selectedUserName = item.userName;
      this.isVideoChat = false;
      this.loadHistory(item.id);
    }
  }

  sendMessage() {
    if (!this.selectedUserId) return;
    
    if (this.inputText.trim().length > 0) {
      const newMsg = new ChatMessage(`m_${Date.now()}`, this.inputText, true, '刚刚');
      this.messages.push(newMsg);
      this.saveHistory();
      this.inputText = '';
      this.isTyping = true;
      
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 80);
      
      const selectedItem = this.messageItems.find(item => item.id === this.selectedUserId);
      if (selectedItem && selectedItem.aiPrompt) {
        this.callDeepSeekAPI(newMsg.content, selectedItem.aiPrompt);
      } else {
        this.isTyping = false;
      }
    }
  }

  async callDeepSeekAPI(userMessage: string, aiPrompt: string): Promise<void> {
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
          content: aiPrompt
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

  @Builder
  HeaderActionBuilder() {
    Row({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333'])
        .onClick(() => {
          promptAction.showToast({ message: '搜索好友' });
        })

      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333'])
        .bindMenu([
          {
            value: '添加联系人',
            action: () => { this.openAddContactDialog(); }
          },
          {
            value: '新建群聊',
            action: () => { promptAction.showToast({ message: '新建群聊' }); }
          },
          {
            value: '扫描二维码',
            action: () => {
              ScanCodeService.getInstance().startScanWithToast(getContext(this) as common.UIAbilityContext);
            }
          }
        ])
    }
  }

  @Builder
  MessageListItem(item: MessageItem, index: number) {
    Row() {
      Image(item.avatar.startsWith('app.media.') ? $r(item.avatar) : $rawfile(item.avatar))
        .width(this.getAvatarSize())
        .height(this.getAvatarSize())
        .borderRadius(this.getAvatarSize() / 2)
        .objectFit(ImageFit.Cover)
      Column({ space: 6 }) {
        Row() {
          if (item.isPinned) {
            SymbolGlyph($r('sys.symbol.pin'))
              .fontSize(this.getPinIconSize())
              .fontColor(['#7B68EE'])
              .margin({ right: 4 })
          }
          Text(item.userName)
            .fontSize(this.getUserNameFontSize())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')
            .constraintSize({ maxWidth: '60%' })
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
          Blank()
          Text(item.time)
            .fontSize(this.getTimeFontSize())
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
        }
        .width('100%')
        Text(truncateText(item.lastMessage))
          .fontSize(this.getMessageFontSize())
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AEAEB2' : '#8E8E93')
          .maxLines(1)
          .constraintSize({ maxWidth: '100%' })
      }
      .layoutWeight(1)
      .padding({ left: this.currentBreakpoint === 'sm' ? 12 : 16 })
    }
    .width('100%')
    .padding({ left: this.getHorizontalPadding(), right: this.getHorizontalPadding(), top: this.getVerticalPadding(), bottom: this.getVerticalPadding() })
    .onClick(() => {
      this.selectFriend(item);
    })
    .stateStyles({
      normal: {
        .backgroundColor(this.selectedUserId === item.id ? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.2)' : 'rgba(123, 104, 238, 0.1)') : Color.Transparent)
      },
      pressed: {
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
      }
    })
  }

  @Builder
  FriendListPanel() {
    Column() {
      Column() {
        Row() {
          Text('好友')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
          Blank()
          this.HeaderActionBuilder()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
      .alignItems(HorizontalAlign.Start)

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 0 }) {
            if (this.isLoading) {
              Column() {
                LoadingProgress()
                  .width(50)
                  .height(50)
                  .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#7B68EE')
                Text('加载中...')
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
                  .margin({ top: 12 })
              }
              .width('100%')
              .padding({ top: 100 })
              .alignItems(HorizontalAlign.Center)
            } else if (this.hasError) {
              Column() {
                SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
                  .fontSize(48)
                  .fontColor(['#FF6B6B'])
                Text(this.errorMessage || '加载失败，请稍后重试')
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
                  .margin({ top: 12 })
                  .textAlign(TextAlign.Center)
                Text('点击重新加载')
                  .fontSize(14)
                  .fontColor('#7B68EE')
                  .margin({ top: 16 })
                  .onClick(() => {
                    this.hasError = false;
                    this.isLoading = true;
                    setTimeout(() => {
                      this.loadQwenChatHistory();
                      this.isLoading = false;
                    }, 500);
                  })
              }
              .width('100%')
              .padding({ top: 100, left: 32, right: 32 })
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.messageItems, (item: MessageItem, index: number) => {
                this.MessageListItem(item, index)
                if (index !== this.messageItems.length - 1) {
                  Divider()
                    .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
                    .margin({ left: 80 })
                }
              }, (item: MessageItem) => item.id.toString())

              Column()
                .height(100)

              Column() {
                Text('您还没有添加更多好友')
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
              }
              .width('100%')
              .padding({ top: 40, bottom: 40 })
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('100%')
          .padding({ top: 8, bottom: 0 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
      }
      .onRefreshing(() => {
        setTimeout(() => {
          this.loadQwenChatHistory();
          this.isRefreshing = false;
        }, 1500)
      })
    }
    .width(this.currentBreakpoint === 'sm' ? '100%' : '350vp')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ChatContentPanel() {
    if (this.selectedUserId === null) {
      Column() {
        SymbolGlyph($r('sys.symbol.message'))
          .fontSize(64)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#444' : '#DDD'])
        Text('选择一个好友开始聊天')
          .fontSize(16)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
          .margin({ top: 16 })
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
    } else {
      Column() {
        Row() {
          Text(this.isVideoChat ? '视频聊天' : this.selectedUserName)
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
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
    }
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
                    Image(this.getSelectedFriendAvatar().startsWith('app.media.') ? $r(this.getSelectedFriendAvatar()) : $rawfile(this.getSelectedFriendAvatar()))
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
                Image(this.getSelectedFriendAvatar().startsWith('app.media.') ? $r(this.getSelectedFriendAvatar()) : $rawfile(this.getSelectedFriendAvatar()))
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

  build() {
    if (this.currentBreakpoint === 'sm') {
      this.FriendListPanel()
    } else {
      Row() {
        this.FriendListPanel()
        Divider()
          .width(1)
          .height('100%')
        this.ChatContentPanel()
      }
      .width('100%')
      .height('100%')
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

@CustomDialog
struct AddContactDialog {
  @ObjectLink searchState: SearchState;
  controller: CustomDialogController;
  onClose: () => void = () => {};
  onAddContact: (user: SearchableUser) => void = () => {};
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  fuzzyMatchChars(keyword: string, text: string): boolean {
    let keywordIndex = 0;
    for (let i = 0; i < text.length && keywordIndex < keyword.length; i++) {
      if (text[i] === keyword[keywordIndex]) {
        keywordIndex++;
      }
    }
    return keywordIndex === keyword.length;
  }

  @Builder
  SearchResultItem(user: SearchableUser) {
    Row() {
      Image($rawfile(user.avatar))
        .width(48)
        .height(48)
        .borderRadius(24)
        .objectFit(ImageFit.Cover)

      Text(user.userName)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#1D2129')
        .layoutWeight(1)
        .margin({ left: 12 })

      Button('添加')
        .type(ButtonType.Normal)
        .borderRadius(16)
        .backgroundColor('#7B68EE')
        .fontColor(Color.White)
        .fontSize(14)
        .height(32)
        .onClick(() => {
          this.onAddContact(user);
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      Column() {
        Column() {
          Row() {
            Text('添加联系人')
              .fontSize(18)
              .fontWeight(600)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            Blank()

            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129'])
              .onClick(() => {
                this.onClose();
                this.controller.close();
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          .alignItems(VerticalAlign.Center)

          TextInput({ placeholder: '搜索用户名...' })
            .height(44)
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
              'rgba(255, 255, 255, 0.1)' : 'rgba(242, 243, 245, 0.2)')
            .borderRadius(22)
            .padding({ left: 16, right: 16 })
            .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#86909C')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
            .onChange((value: string) => {
              if (value && value.trim().length > 0) {
                const lowerValue = value.toLowerCase();
                const keywordResults: SearchableUser[] = [];
                for (let i = 0; i < USER_NAMES.length; i++) {
                  const userName = USER_NAMES[i];
                  const lowerUserName = userName.toLowerCase();
                  if (lowerUserName.includes(lowerValue) || this.fuzzyMatchChars(lowerValue, lowerUserName)) {
                    keywordResults.push({
                      id: `search_${i}`,
                      userName: userName,
                      avatar: AVATARS[i % AVATARS.length]
                    });
                  }
                }
                this.searchState.update(value, keywordResults.slice(0, 20));
              } else {
                this.searchState.update('', []);
              }
            })
        }
        .width('100%')
        .padding(24)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius({ topLeft: 24, topRight: 24 })

        Column() {
          if (this.searchState.results.length === 0 && this.searchState.keyword.length > 0) {
            Column() {
              SymbolGlyph($r('sys.symbol.xmark_circle'))
                .fontSize(48)
                .fontColor(['#8E8E93'])
              Text('未找到匹配的用户')
                .fontSize(14)
                .fontColor('#8E8E93')
                .margin({ top: 12 })
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .alignItems(HorizontalAlign.Center)
          } else {
            Scroll() {
              Column({ space: 0 }) {
                ForEach(this.searchState.results, (user: SearchableUser) => {
                  this.SearchResultItem(user)
                  Divider()
                    .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
                }, (user: SearchableUser) => user.id)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
            .constraintSize({ maxHeight: 400 })
          }
        }
        .width('100%')
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .borderRadius({ bottomLeft: 24, bottomRight: 24 })
      }
    }
    .width('90%')
    .constraintSize({ maxWidth: 480 })
    .backgroundColor(Color.Transparent)
  }
}
