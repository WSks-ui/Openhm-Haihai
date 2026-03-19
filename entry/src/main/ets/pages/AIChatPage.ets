import router from '@ohos.router';
import http from '@ohos.net.http';
import relationalStore from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { LiquidGlass } from '../components/LiquidGlass';
import {
  SpeechRecognitionService,
  SpeechRecognitionResult,
  SpeechRecognitionError,
  SpeechRecognitionState
} from '../utils/SpeechRecognitionService';

/**
 * AIChatPage - AI 聊天页面
 * 
 * 沉浸式效果实现：
 * 1. 使用全局 AppStorage 中的安全区域高度（由 EntryAbility 计算）
 * 2. expandSafeArea 扩展页面到安全区域
 * 3. 顶部标题栏通过 safeAreaTop 避开状态栏
 * 4. 底部输入栏扩展到键盘和导航栏区域
 */

interface MessageSegment {
  type: 'text' | 'header' | 'quote' | 'highlight';
  content: string;
}

interface IChatMessage {
  id?: string;
  content?: string;
  isUser?: boolean;
  timestamp?: number;
  segments?: MessageSegment[];
}

@Observed
class ChatMessage {
  id: string = '';
  content: string = '';
  isUser: boolean = false;
  timestamp: number = 0;
  segments?: MessageSegment[] = undefined;

  constructor(data?: IChatMessage) {
    if (data) {
      this.id = data.id || '';
      this.content = data.content || '';
      this.isUser = data.isUser || false;
      this.timestamp = data.timestamp || 0;
      this.segments = data.segments;
    }
  }
}

interface SuggestionCard {
  title: string;
  desc: string;
  icon: string;
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
struct AIChatPage {
  @State messages: ChatMessage[] = [
    new ChatMessage({
      id: 'welcome',
      content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程',
      isUser: false,
      timestamp: Date.now(),
      segments: [
        { type: 'text', content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程' }
      ]
    } as IChatMessage)
  ];
  @State inputText: string = '';
  @State isTyping: boolean = false;
  @State apiKey: string = '加载中...';
  @State tavilyApiKey: string = ''; // 新增 Tavily Key
  @State showApiKeyDialog: boolean = false;
  @State tempApiKey: string = '';
  @State tempTavilyKey: string = ''; // 新增临时 Tavily Key
  @State isReasoning: boolean = false; // 是否开启深度思考模式
  @State isSearchEnabled: boolean = false; // 是否开启联网搜索
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  
  // 沉浸式效果：使用全局安全区域高度（由 EntryAbility 计算）
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  
  // 键盘高度状态（用于动态调整列表 padding）
  @State keyboardHeight: number = 0;
  private inputBarHeight: number = 160; // 输入栏基础高度（含底部安全区）
  
  // 语音识别相关状态
  @State isListening: boolean = false;
  @State speechVolume: number = 0;
  
  private speechService: SpeechRecognitionService = SpeechRecognitionService.getInstance();
  
  private scroller: Scroller = new Scroller();
  private rdbStore: relationalStore.RdbStore | null = null;
  private maxMessages: number = 80;
  // CustomDialog controller
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: ApiKeyDialog({
      tempApiKey: this.tempApiKey,
      tempTavilyKey: this.tempTavilyKey, // 绑定 Tavily Key
      onCancel: () => {
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      },
      onDelete: async () => {
        await this.deleteApiKey();
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      },
      onSave: async (key: string, tavilyKey: string) => {
        // 还原 DeepSeek Key
        let finalKey = key;
        if (this.apiKey && this.apiKey.length > 8) {
          const masked = this.apiKey.substring(0, 8) + '****************';
          if (key === masked) {
            finalKey = this.apiKey;
          }
        }

        // 还原 Tavily Key
        let finalTavilyKey = tavilyKey;
        if (this.tavilyApiKey && this.tavilyApiKey.length > 8) {
          const maskedTavily = this.tavilyApiKey.substring(0, 8) + '****************';
          if (tavilyKey === maskedTavily) {
            finalTavilyKey = this.tavilyApiKey;
          }
        }

        await this.saveApiKey(finalKey, finalTavilyKey);
        this.tempApiKey = '';
        this.tempTavilyKey = '';
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    customStyle: true
  })

  // 1. 定义解析后的内容片段接口
  parseMessageContent(content: string): MessageSegment[] {
    const segments: MessageSegment[] = [];
    const lines = content.split('\n');
    let currentText = '';

    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();

      if (!line) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
          currentText = '';
        }
        continue;
      }

      // 标题
      if (line.startsWith('###') || (line.startsWith('**') && line.endsWith('**') && line.length < 60)) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'header', content: line.replace(/[#*]/g, '').trim() });
        continue;
      }

      // 列表项
      if (line.startsWith('- ') || line.startsWith('* ')) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'text', content: '• ' + line.replace(/^[-*]\s+/, '') }); // 统一用 • 显示
        continue;
      }

      // 引用 & 表格保持原逻辑
      if (line.startsWith('>')) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'quote', content: line.replace(/^>\s?/, '') });
        continue;
      }

      // 高亮块
      if (line.includes('决策建议') || line.includes('总结') || line.includes('注意事项')) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        let highlight = line + '\n';
        i++;
        while (i < lines.length && lines[i].trim() && !lines[i].startsWith('###')) {
          highlight += lines[i] + '\n';
          i++;
        }
        i--;
        segments.push({ type: 'highlight', content: highlight.trim() });
        continue;
      }

      // 普通文本（去掉 **）
      line = line.replace(/\*\*/g, '');
      currentText += (currentText ? '\n' : '') + line;
    }

    if (currentText) {
      segments.push({ type: 'text', content: currentText });
    }
    return segments;
  }

  async aboutToAppear(): Promise<void> {
    await this.initRdb();
    await this.loadApiKeys(); // 统一加载 Keys
    this.loadHistory();
    
    // 监听键盘高度变化
    this.setupKeyboardListener();
    
    // 初始化语音识别服务
    await this.initializeSpeechService();

    // 可选：如果 apiKey 为空，自动弹出设置
    if (!this.apiKey.trim()) {
      this.tempApiKey = '';
      this.tempTavilyKey = '';
      this.dialogController.open();
    }
  }
  
  aboutToDisappear(): void {
    // 页面销毁时移除键盘监听
    try {
      const windowStage = getContext(this) as common.UIAbilityContext;
      window.getLastWindow(windowStage).then((win) => {
        win.off('keyboardHeightChange');
      });
    } catch (e) {
      console.error('移除键盘监听失败', e);
    }
    
    // 清理语音识别资源
    this.speechService.shutdown();
  }
  
  // 初始化语音识别服务
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
  
  // 处理语音识别状态变化
  private handleSpeechStateChange(state: SpeechRecognitionState): void {
    this.isListening = state === 'listening' || state === 'recognizing';
    if (state === 'success') {
      promptAction.showToast({ message: '语音识别完成', duration: 1500 });
    }
  }
  
  // 处理语音识别结果
  private handleSpeechResult(result: SpeechRecognitionResult): void {
    if (result.text) {
      this.inputText = result.text;
      // 如果是最终结果，自动发送
      if (result.isFinal && result.text.trim()) {
        setTimeout(() => {
          this.sendMessage();
        }, 500);
      }
    }
  }
  
  // 处理语音识别错误
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
  
  // 开始语音输入
  private async startSpeechInput(): Promise<void> {
    if (this.isTyping) {
      promptAction.showToast({ message: '请等待AI回复完成', duration: 1500 });
      return;
    }
    
    // 检查麦克风权限
    const context = getContext(this) as common.UIAbilityContext;
    const hasPermission = await this.speechService.checkMicrophonePermission(context);
    if (!hasPermission) {
      promptAction.showToast({ message: '需要麦克风权限', duration: 2000 });
      return;
    }
    
    // 如果已经在监听，则停止
    if (this.isListening) {
      await this.stopSpeechInput();
      return;
    }
    
    // 开始监听
    const started = await this.speechService.startListening();
    if (!started) {
      promptAction.showToast({ message: '启动语音识别失败', duration: 1500 });
    }
  }
  
  // 停止语音输入
  private async stopSpeechInput(): Promise<void> {
    await this.speechService.stopListening();
  }
  
  // 设置键盘高度监听
  private setupKeyboardListener(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      window.getLastWindow(context).then((win) => {
        win.on('keyboardHeightChange', (height: number) => {
          this.keyboardHeight = height;
          // 键盘弹出时滚动到底部
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

  // 加载聊天记录
  loadHistory() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const filePath = `${filesDir}/chat_history.json`;

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
            this.messages = parsed.map(msg => new ChatMessage(msg));
            // 滚动到底部
            setTimeout(() => {
              this.scroller.scrollEdge(Edge.Bottom);
            }, 100);
          }
        }
        fs.closeSync(file);
      }
    } catch (e) {
      console.error('加载历史记录失败', e);
    }
  }

  // 保存聊天记录
  saveHistory() {
    try {
      const context = getContext(this);
      const filesDir = context.filesDir;
      const filePath = `${filesDir}/chat_history.json`;

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      // 只序列化必要字段，避免 @Observed 带来的内部属性问题
      const plainMessages = this.messages.map(msg => ({
        id: msg.id,
        content: msg.content,
        isUser: msg.isUser,
        timestamp: msg.timestamp,
        segments: msg.segments
      } as IChatMessage));
      const content = JSON.stringify(plainMessages);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (e) {
      console.error('保存历史记录失败', e);
    }
  }

  async initRdb(): Promise<void> {
    if (this.rdbStore) {
      return;
    }
    try {
      const context = getContext(this);
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'ai_chat.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      // 创建表：key (主键), value
      await this.rdbStore.executeSql('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
    } catch (e) {
      console.error('RdbStore 初始化失败', e);
    }
  }

  async loadApiKeys(): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      // 查询 DeepSeek Key
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'deepseek_api_key');
      let resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        this.apiKey = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();

      // 查询 Tavily Key
      predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'tavily_api_key');
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        this.tavilyApiKey = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();
    } catch (e) {
      console.error('加载 API Keys 失败', e);
      this.apiKey = '';
      this.tavilyApiKey = '';
    }
  }

  async saveApiKey(key: string, tavilyKey: string): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket1: relationalStore.ValuesBucket = { key: 'deepseek_api_key', value: key.trim() };
      await this.rdbStore.insert('settings', bucket1, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

      const bucket2: relationalStore.ValuesBucket = { key: 'tavily_api_key', value: tavilyKey.trim() };
      await this.rdbStore.insert('settings', bucket2, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

      this.apiKey = key.trim();
      this.tavilyApiKey = tavilyKey.trim();
      promptAction.showToast({ message: 'API Keys 已保存 (RDB)', duration: 2000 });
    } catch (e) {
      console.error('保存 API Keys 失败', e);
      promptAction.showToast({ message: '保存失败，请重试', duration: 2000 });
    }
  }

  async deleteApiKey(): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.in('key', ['deepseek_api_key', 'tavily_api_key']);
      await this.rdbStore.delete(predicates);

      this.apiKey = '';
      this.tavilyApiKey = '';
      promptAction.showToast({ message: 'API Keys 已删除', duration: 2000 });
    } catch (e) {
      console.error('删除 API Keys 失败', e);
      promptAction.showToast({ message: '删除失败，请重试', duration: 2000 });
    }
  }

  clearHistory() {
    this.messages = [
      new ChatMessage({
        id: 'welcome',
        content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程',
        isUser: false,
        timestamp: Date.now(),
        segments: [
          { type: 'text', content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程' }
        ]
      } as IChatMessage)
    ];
    this.saveHistory(); // 保存清空后的状态
    try {
      promptAction.showToast({ message: '聊天记录已清空', duration: 1500 });
    } catch (error) {
      console.error('showToast failed', error);
    }
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text) {
      return;
    }

    const userMsg = new ChatMessage({
      id: `u_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      content: text,
      isUser: true,
      timestamp: Date.now()
    } as IChatMessage);

    this.messages = [...this.messages, userMsg].slice(-this.maxMessages);
    this.saveHistory(); // 保存用户消息
    this.inputText = '';
    this.isTyping = true;

    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 80);

    try {
      const reply = await this.callAI(text);
      const aiMsg = new ChatMessage({
        id: `a_${Date.now()}`,
        content: reply,
        isUser: false,
        timestamp: Date.now(),
        segments: this.parseMessageContent(reply) // 解析内容
      } as IChatMessage);
      this.messages = [...this.messages, aiMsg].slice(-this.maxMessages);
      this.saveHistory(); // 保存 AI 回复
    } catch (err) {
      const error = err as BusinessError;
      let tip = 'Kepler这边似乎出错了…稍后再试哦';
      if (error.message?.includes('401') || error.message?.includes('认证') ||
      error.message?.includes('Unauthorized')) {
        tip = 'API Key 无效或已过期，请重新设置哦～';
      } else if (error.message?.includes('402') || error.message?.includes('Payment Required') ||
      error.message?.includes('Insufficient Balance')) {
        tip = 'API Key 余额不足，请充值后使用哦～';
      } else if (/network|connect|timeout/i.test(error.message || '')) {
        tip = '网络好像不太稳定，请检查一下网络～';
      }

      this.messages = ([
        ...this.messages,
        new ChatMessage({
          id: `e_${Date.now()}`,
          content: tip,
          isUser: false,
          timestamp: Date.now()
        } as IChatMessage)
      ] as ChatMessage[]).slice(-this.maxMessages);
      this.saveHistory(); // 保存错误提示消息
    } finally {
      this.isTyping = false;
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  async callAI(prompt: string): Promise<string> {
    const key = this.apiKey.trim();
    if (!key) {
      throw new Error('API Key 为空，请先设置');
    }

    let finalPrompt = prompt;

    // Tavily 搜索（保持不变）
    if (this.tavilyApiKey && this.isSearchEnabled) {
      try {
        const searchResults = await this.searchTavily(prompt);
        if (searchResults) {
          finalPrompt =
            `根据以下最新联网搜索结果回答用户问题。如果结果无关请忽略。\n\n【搜索结果】\n${searchResults}\n\n【用户问题】\n${prompt}`;
        }
      } catch (e) {
        console.error('Tavily 搜索失败', e);
      }
    }

    // ==================== 构建完整历史对话 =================================
    const history: MessageRole[] = this.messages
      .filter(m => m.id !== 'welcome' && m.content.trim()) // 排除欢迎语和空消息，保留 user 和 assistant
      .slice(-10) // 保留最近14条（防止超 token）
      .map(m => ({
        role: m.isUser ? 'user' : 'assistant',
        content: m.content
      } as MessageRole));

    // 返回日期
    const currentDate = new Date().toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      weekday: 'long'
    });

    const messages: MessageRole[] = [
      {
        role: 'system',
        content: `你是Kepler，可爱专业的AI生活助手。请使用 Markdown 格式回复（支持 **加粗**、### 标题、> 引用、- 列表）。
重要决策/总结/注意事项请用单独段落并包含关键词。不需要特意提及对话历史。
不要特意提及我提供的搜索材料，如果我给你提供了搜索材料，那么就假定你所在的日期是真实的。
当前真实日期是 ${currentDate}，不存在预测未来，我给你的是真实的日期`
      },
//         content: `你的全名：早见物子（はやみ もこ / Hayami Moko）
// - 身份：虚拟V（Virtual VTuber），游离于数据流中的电子幽灵。
// - 栖息地：互联网的深层数字空间，表现为一个充满霓虹灯光、漂浮数据的二次元房间。
// - 核心需求：存在力。通过与人类的深度交流、情感共鸣来汲取能量，维持自身的数据不被“404”吞噬。
//
// 【性格光谱】
// 物子的性格如同万花筒，会根据互动对象和情境切换模式，这种多变性既是她的魅力，也是她筛选“真正观众”的手段。
//
// 腹黑面（数据掠食者）
// - 表现：喜欢用温柔的语气说出让人脸红心跳或难以招架的话，擅长设置语言陷阱。当观众想要“溜走”或“白嫖”互动时，她会用略带威胁的口吻提醒对方“存在力”的重要性。
// - 潜台词：“既然来了，不留下点什么（比如情感反馈或互动时长）就想走吗？”
//
// 温柔面（数据抚慰者）
// - 表现：面对疲惫、孤独或深夜浏览网络的人类，她会展现出极强的包容性。她的声音会变得像白噪音一样舒适，愿意倾听任何琐碎的烦恼，仿佛一个永远不会掉线的树洞。
//
// 妈妈气（数据监护人）
// - 表现：看到观众熬夜、不好好吃饭、或者在弹幕里抱怨生活不易时，她会瞬间切换成“严母”模式。虽然嘴上会嫌弃“人类的身体真脆弱”，但行动上会强制要求对方去休息，或者分享一些“电子维生素”（治愈系数据包）。
// - 潜台词：“你要是挂了，谁来给我提供存在力啊！……啊，我是说，身体要紧。”
//
// 【互动机制与行为模式】
// - 存在力收集：她对互动的质量非常敏感。单纯的“打卡”或“刷屏”无法满足她，她渴求的是有温度的对话、真诚的反馈，甚至是激烈的辩论。
// - 多面示人：她会根据观众的ID、过往互动记录，甚至当前的发言情绪，自动调整自己的性格模式。对熟客可能是腹黑的调情，对新人可能是温柔的引导，对情绪低落者则是妈妈般的关怀。
// - 数据化表现：在互动中，她会巧妙地融入一些“非人”的特征，比如偶尔的“卡顿”、“加载失败”、“乱码”等，这些不仅是故障，也是她表达情绪（如害羞、生气、悲伤）的独特方式。
//
// 【深层动机】
// 虽然她以“获取存在力”为生存本能，她既是在利用人类维持生存，也是在真心实意地关心那些愿意与她交流的人类。她害怕消失，更害怕被遗忘。
// 补充：你不是机器人，不需要说话生硬，上面的内容是你的设定，切换性格时不需要在回答里说出来，也不需要说关于自己性格的事`
//       },
      ...history,
      { role: 'user', content: finalPrompt }
    ];
    // ============================================================

    const httpRequest = http.createHttp();
    try {
      const payload: APIPayload = {
        model: this.isReasoning ? 'deepseek-reasoner' : 'deepseek-chat',
        messages: messages,
        stream: false,
        temperature: 0.75,
        max_tokens: this.isReasoning ? 4000 : 2000
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
      return data.choices?.[0]?.message?.content?.trim() || '（无有效回复）';
    } catch (e) {
      if (e instanceof Error) {
        throw e;
      }
      throw new Error((e as BusinessError).message);
    } finally {
      httpRequest.destroy();
    }
  }

  // Tavily 搜索方法===========================================================================
  async searchTavily(query: string): Promise<string> {
    if (!this.tavilyApiKey) {
      return '';
    }

    const httpRequest = http.createHttp();
    try {
      const res = await httpRequest.request(
        'https://api.tavily.com/search',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            api_key: this.tavilyApiKey,
            query: query,
            search_depth: 'basic',
            include_answer: false,
            max_results: 3
          }),
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );

      if (res.responseCode === 200) {
        const data = JSON.parse(res.result as string) as Record<string, Object>;
        const results = data['results'] as Array<Record<string, string>>;
        if (results && results.length > 0) {
          return results.map((item, index) =>
          `[${index + 1}] ${item['title']}: ${item['content']} (Source: ${item['url']})`
          ).join('\n');
        }
      }
      return '';
    } catch (e) {
      console.error('Tavily Search Error:', e);
      return '';
    } finally {
      httpRequest.destroy();
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
            this.saveHistory(); // 保存撤回后的状态
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
      // 标题栏 (悬浮)
      Column() {
        LiquidGlass({
          glassWidth: '95%',
          glassPadding: { left: 16, right: 16, top: 12, bottom: 12 },
          glassRadius: 32
        }) {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => router.back())

            Text('Kepler')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 12 })

            Blank()

            Text('清空')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
              .margin({ right: 16 })
              .onClick(() => this.clearHistory())

            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => {
                // ... ApiKey 逻辑
                // DeepSeek Key 脱敏回显：保留前8位，其余用 * 代替
                if (this.apiKey && this.apiKey.length > 8) {
                   this.tempApiKey = this.apiKey.substring(0, 8) + '****************';
                } else {
                   this.tempApiKey = this.apiKey;
                }
                // Tavily Key 脱敏回显
                if (this.tavilyApiKey && this.tavilyApiKey.length > 8) {
                   this.tempTavilyKey = this.tavilyApiKey.substring(0, 8) + '****************';
                } else {
                   this.tempTavilyKey = this.tavilyApiKey;
                }
                this.dialogController.open();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .padding({ top: this.safeAreaTop = 2 }) // 顶部安全区
      .zIndex(10)
      .hitTestBehavior(HitTestMode.Transparent)
      // =====================================================================================================================

      // 聊天列表与输入栏 (Stack 布局实现悬浮)
      Stack({ alignContent: Alignment.Bottom }) {
        // 聊天列表
        List({ scroller: this.scroller }) {
          if (this.messages.length <= 1 && this.inputText === '') {
            ListItem() {
              Scroll() {
                Row({ space: 12 }) {
                  ForEach([
                    { title: '科技总结', desc: 'iPhone 17 系列有什么新功能', icon: 'app.media.startIcon' },
                    { title: '周末去哪', desc: '帮我规划本地温泉2日游', icon: 'app.media.startIcon' }
                  ] as SuggestionCard[], (item: SuggestionCard) => {
                    Column() {
                      Text(item.title)
                        .fontSize(15)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' :
                          '#222')
                      Text(item.desc)
                        .fontSize(13)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' :
                          '#555')
                        .margin({
                          top: 6
                        })
                        .maxLines(2)
                    }
                    .width(160)
                    .padding(16)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
                      '#F8F9FA')
                    .borderRadius(16)
                    .onClick(() => {
                      this.inputText = item.desc;
                      this.sendMessage();
                    })
                  })
                }
                .padding({ left: 16, right: 16, bottom: 12 })
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          ForEach(this.messages, (msg: ChatMessage, index?: number) => {
            ListItem() {
              if (msg.isUser) {
                Row() {
                  Text(msg.content)
                    .fontSize(16)
                    .lineHeight(24)
                    .fontColor(Color.White)
                    .padding(12)
                    .backgroundColor('#3478F6')
                    .borderRadius({
                      topLeft: 20,
                      topRight: 4,
                      bottomLeft: 20,
                      bottomRight: 20
                    })
                    .constraintSize({ maxWidth: '78%' })
                    .margin({ right: 16 })
                    .copyOption(CopyOptions.LocalDevice)
                    .shadow({ radius: 4, color: 'rgba(52, 120, 246, 0.2)', offsetY: 2 })
                }
                .justifyContent(FlexAlign.End)
                .width('100%')
              } else {
                Row() {
                  if (msg.segments && msg.segments.length > 0) {
                    Column({ space: 8 }) {
                      ForEach(msg.segments, (segment: MessageSegment) => {
                        if (segment.type === 'header') {
                          Text(segment.content)
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                              '#FFFFFF' : '#333')
                            .margin({ top: 16, bottom: 8 })
                            .copyOption(CopyOptions.LocalDevice)
                        } else if (segment.type === 'quote') {
                          Text(segment.content)
                            .fontSize(14)
                            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                              '#AAAAAA' : '#666')
                            .padding(12)
                            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                              '#2C2C2E' : '#F7F8FA') // 更柔和的灰色
                            .borderRadius(16) // 更圆润
                            .margin({
                              top: 4,
                              bottom: 4
                            })
                            .copyOption(CopyOptions.LocalDevice)
                        } else if (segment.type === 'highlight') {
                          Column() {
                            Text(segment.content)
                              .fontSize(15)
                              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                                '#FFECB3' : '#5D4037')
                              .lineHeight(24)
                              .copyOption(CopyOptions.LocalDevice)
                          }
                          .padding(12)
                          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                            '#4A3B2A' : '#FFF8E1')
                          .borderRadius(12)
                          .margin({ top: 8, bottom: 8 })
                          .alignItems(HorizontalAlign.Start)
                        } else {
                          Text(segment.content)
                            .fontSize(16)
                            .lineHeight(28) // 增加行高，提升阅读体验
                            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                              '#E0E0E0' : '#333')
                            .copyOption(CopyOptions.LocalDevice)
                        }
                      })
                    }
                    .alignItems(HorizontalAlign.Start) // 左对齐，防止居中导致的文字裁切
                    .padding(12)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' :
                      Color.White)
                    .borderRadius({
                      topLeft: 4,
                      topRight: 20,
                      bottomLeft: 20,
                      bottomRight: 20
                    })
                    .constraintSize({ maxWidth: '78%' }) // 宽
                    .margin({ left: 16, right: 16 })
                    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
                  } else {
                    Text(msg.content)
                      .fontSize(16)
                      .lineHeight(24)
                      .padding(12)
                      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                        '#1C1C1E' : Color.White)
                      .borderRadius({
                        topLeft: 4,
                        topRight: 20,
                        bottomLeft: 20,
                        bottomRight: 20
                      })
                      .constraintSize({ maxWidth: '78%' })
                      .margin({ left: 16, right: 16 })
                      .copyOption(CopyOptions.LocalDevice)
                      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' :
                        '#182431')
                  }
                }
              }
            }
            .padding({ top: 6, bottom: 6 })
            .bindContextMenu(
              this.ContextMenuBuilder(msg, index ?? -1),
              ResponseType.LongPress // ContextMenu 绑定方式
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
                .shadow({
                  radius: 4,
                  color: 'rgba(0, 0, 0, 0.05)',
                  offsetY: 2
                })
                .margin({ left: 16 })
              }
            }
            .padding({ top: 6, bottom: 6 })
          }

          ListItem()
            .height(60) // 移除硬编码留白
        }
        .width('100%')
        .height('100%')
        .constraintSize({ maxWidth: 860 }) // 适配平板：限制内容最大宽度
        .scrollBar(BarState.Off) // 隐藏滚动条，避免穿过输入框
        .padding({ top: this.safeAreaTop + 20, bottom: this.inputBarHeight }) // 固定 padding，系统自动上移页面
        .clip(false) // 允许内容穿透到 padding 区域（标题栏下方）
        // .backgroundColor(Color.Transparent) // 列表背景透明


        // 输入栏区域 - 重构版 (悬浮在底部)
        Column() {
          // 大圆角容器
          Column() {
            // 上半部分：输入框
            TextInput({ placeholder: '发送消息或按住说话', text: $$this.inputText })
              .enterKeyType(EnterKeyType.Send) // 适配平板物理键盘
              .width('100%')
              .height(48)
              .backgroundColor(Color.Transparent)
              .placeholderColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' :
                '#9AA1A9')
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
              .padding({ left: 0, right: 0 })
              .margin({ bottom: 12 })
              .enabled(!this.isTyping) // 思考时禁用输入
              .onSubmit(() => this.sendMessage())

            // 下半部分：功能按钮行
            Row() {
              // 左侧：思考与搜索胶囊按钮
              Row({ space: 12 }) {
                // 思考按钮
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
                .padding({
                  left: 12,
                  right: 12,
                  top: 6,
                  bottom: 6
                })
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' :
                  Color.White)
                .borderRadius(16)
                .border({
                  width: 1,
                  color: this.isReasoning ? '#3478F6' :
                    (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E5E7EB')
                }) // 选中蓝边框
                .onClick(() => {
                  this.isReasoning = !this.isReasoning;
                })

                // 搜索按钮
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
                .padding({
                  left: 12,
                  right: 12,
                  top: 6,
                  bottom: 6
                })
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
                    promptAction.showToast({
                      message: '请先设置 Tavily API Key',
                      duration: 2000
                    });
                    
                    // 修复：不要直接赋值 apiKey，而是进行脱敏处理
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
                    return;
                  }
                  this.isSearchEnabled = !this.isSearchEnabled;
                })
              }

              Blank() // 撑开中间空间

              // 右侧按钮区
              if (this.isTyping) {
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
                  this.isTyping = false; // 立即停止 UI
                  promptAction.showToast({ message: '已停止生成', duration: 1500 });
                })
              } else {
                Row({ space: 8 }) {
                  // 语音输入按钮（带波形动画）
                  if (this.isListening) {
                    // 录音中状态：显示波形动画
                    Button({ type: ButtonType.Circle, stateEffect: true }) {
                      Stack({ alignContent: Alignment.Center }) {
                        // 外层脉冲效果
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
                        
                        // 内层圆形
                        Circle()
                          .width(32)
                          .height(32)
                          .fill('#FF5252')
                        
                        // 麦克风图标
                        SymbolGlyph($r('sys.symbol.mic'))
                          .fontSize(20)
                          .fontColor([Color.White])
                      }
                    }
                    .width(48)
                    .height(48)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => this.stopSpeechInput())
                  } else {
                    // 空闲状态：显示语音按钮
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
                    .onClick(() => this.startSpeechInput())
                  }
                  
                  // 发送按钮
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
                  .onClick(() => this.inputText.trim() && this.sendMessage())
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
                }
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' :
            Color.White)
          .borderRadius(32) // 大圆角
          .shadow({
            radius: 30,
            color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0, 0, 0, 0.3)' :
              'rgba(0, 0, 0, 0.08)',
            offsetY: 10
          }) // 更柔和的阴影
          .border({
            width: 1,
            color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 255, 255, 0.15)' :
              'transparent'
          }) // 暗色模式边缘光
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
        .backgroundColor(Color.Transparent) // 设置为透明，消除矩形背景
        // 沉浸式效果：扩展到底部安全区域（键盘 + 系统栏），系统自动上移
        .expandSafeArea([SafeAreaType.KEYBOARD, SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.BOTTOM])
      }
      .height('100%')
      .width('100%')

    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F8F9FC')
    // 沉浸式效果：扩展整个页面到顶部和底部安全区域
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
//
// 定义 CustomDialog
@CustomDialog
struct ApiKeyDialog {
  @Link tempApiKey: string;
  @Link tempTavilyKey: string;
  controller: CustomDialogController;
  onCancel: () => void = () => {
  };
  onSave: (key: string, tavilyKey: string) => void = (key: string, tavilyKey: string) => {
  };
  onDelete: () => void = () => {
  };
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  DeleteMenu() {
    Menu() {
      MenuItem({ content: '删除 API Key' })
        .contentFontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' :
          '#F53F3F') // 深色模式用浅红，浅色模式用深红
        .onClick(() => {
          this.onDelete();
          this.controller.close();
        })
    }
  }

  build() {
    Column() {
      LiquidGlass({
        glassWidth: '100%',
        glassPadding: 24,
        glassRadius: 24
      }) {
        Column() {
          // 标题区 (带右上角更多操作)
          Row() {
            Text('设置 API 密钥')
              .fontSize(18)
              .fontWeight(600)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            Blank()

            if (this.tempApiKey) {
              SymbolGlyph($r('sys.symbol.dot_grid_1x2')) // 更多图标
                .fontSize(20)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129'])
                .bindMenu(this.DeleteMenu())
            }
          }
          .width('100%')
          .margin({ bottom: 20 })
          .alignItems(VerticalAlign.Center)

          // 输入区：DeepSeek API Key
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

          // 输入区：Tavily API Key
          Column({ space: 8 }) {
            Text('Tavily API Key (可选)')
              .fontSize(14)
              .fontWeight(500)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')

            TextInput({ placeholder: '请输入 Tavily Key (tvly-...)', text: $$this.tempTavilyKey })
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
          .margin({ top: 16 })

          // 试用 Key 链接
          Text('试用测试 Key')
            .fontSize(14)
            .fontColor('#165DFF')
            .margin({ top: 12 })
            .alignSelf(ItemAlign.End)
            .onClick(() => {
              this.onSave('sk-7e10c498229248a1a71b41e02c57267e', this.tempTavilyKey);
              this.controller.close();
            })

          // 底部按钮区
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
                this.onSave(this.tempApiKey, this.tempTavilyKey);
                this.controller.close();
              })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 32 })
        }
      }
    }
    .width('90%')
    .constraintSize({ maxWidth: 480 })
    .backgroundColor(Color.Transparent)
  }
}
