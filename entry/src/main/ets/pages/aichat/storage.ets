import relationalStore from '@ohos.data.relationalStore';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction';
import {
  ChatMessage,
  IChatMessage,
  MessageSegment,
  ApiKeysData,
  ChatStorageConfig,
  WELCOME_MESSAGE
} from './types';

const STORE_CONFIG: ChatStorageConfig = {
  name: 'ai_chat.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SETTINGS_TABLE = 'settings';
const DEEPSEEK_KEY = 'deepseek_api_key';
const TAVILY_KEY = 'tavily_api_key';
const CHAT_HISTORY_FILE = 'chat_history.json';

export class ChatStorage {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context | null = null;

  async initialize(context: Context): Promise<void> {
    this.context = context;
    if (this.rdbStore) {
      return;
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)'
      );
    } catch (e) {
      console.error('RdbStore 初始化失败', e);
      throw new Error(String(e));
    }
  }

  private async ensureInitialized(): Promise<void> {
    if (!this.rdbStore || !this.context) {
      throw new Error('ChatStorage 未初始化，请先调用 initialize()');
    }
  }

  async loadApiKeys(): Promise<ApiKeysData> {
    await this.ensureInitialized();
    const result: ApiKeysData = {
      deepseekApiKey: '',
      tavilyApiKey: ''
    };

    try {
      let predicates = new relationalStore.RdbPredicates(SETTINGS_TABLE);
      predicates.equalTo('key', DEEPSEEK_KEY);
      let resultSet = await this.rdbStore!.query(predicates);
      if (resultSet.goToFirstRow()) {
        result.deepseekApiKey = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();

      predicates = new relationalStore.RdbPredicates(SETTINGS_TABLE);
      predicates.equalTo('key', TAVILY_KEY);
      resultSet = await this.rdbStore!.query(predicates);
      if (resultSet.goToFirstRow()) {
        result.tavilyApiKey = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();
    } catch (e) {
      console.error('加载 API Keys 失败', e);
    }

    return result;
  }

  async saveApiKeys(deepseekKey: string, tavilyKey: string): Promise<void> {
    await this.ensureInitialized();
    try {
      const bucket1: relationalStore.ValuesBucket = {
        key: DEEPSEEK_KEY,
        value: deepseekKey.trim()
      };
      await this.rdbStore!.insert(
        SETTINGS_TABLE,
        bucket1,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );

      const bucket2: relationalStore.ValuesBucket = {
        key: TAVILY_KEY,
        value: tavilyKey.trim()
      };
      await this.rdbStore!.insert(
        SETTINGS_TABLE,
        bucket2,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );

      promptAction.showToast({ message: 'API Keys 已保存 (RDB)', duration: 2000 });
    } catch (e) {
      console.error('保存 API Keys 失败', e);
      promptAction.showToast({ message: '保存失败，请重试', duration: 2000 });
      throw new Error(String(e));
    }
  }

  async deleteApiKeys(): Promise<void> {
    await this.ensureInitialized();
    try {
      let predicates = new relationalStore.RdbPredicates(SETTINGS_TABLE);
      predicates.in('key', [DEEPSEEK_KEY, TAVILY_KEY]);
      await this.rdbStore!.delete(predicates);
      promptAction.showToast({ message: 'API Keys 已删除', duration: 2000 });
    } catch (e) {
      console.error('删除 API Keys 失败', e);
      promptAction.showToast({ message: '删除失败，请重试', duration: 2000 });
      throw new Error(String(e));
    }
  }

  loadChatHistory(): ChatMessage[] {
    if (!this.context) {
      return [new ChatMessage(WELCOME_MESSAGE)];
    }

    try {
      const filesDir = this.context.filesDir;
      const filePath = `${filesDir}/${CHAT_HISTORY_FILE}`;

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
            return parsed.map(msg => new ChatMessage(msg));
          }
        }
        fs.closeSync(file);
      }
    } catch (e) {
      console.error('加载历史记录失败', e);
    }

    return [new ChatMessage(WELCOME_MESSAGE)];
  }

  saveChatHistory(messages: ChatMessage[]): void {
    if (!this.context) {
      return;
    }

    try {
      const filesDir = this.context.filesDir;
      const filePath = `${filesDir}/${CHAT_HISTORY_FILE}`;

      const file = fs.openSync(
        filePath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      const plainMessages = messages.map(msg => msg.toPlainObject());
      const content = JSON.stringify(plainMessages);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (e) {
      console.error('保存历史记录失败', e);
    }
  }

  getWelcomeMessage(): ChatMessage {
    return new ChatMessage(WELCOME_MESSAGE);
  }

  createUserMessage(content: string): ChatMessage {
    return new ChatMessage({
      id: `u_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      content: content,
      isUser: true,
      timestamp: Date.now()
    } as IChatMessage);
  }

  createAiMessage(content: string, segments?: MessageSegment[]): ChatMessage {
    return new ChatMessage({
      id: `a_${Date.now()}`,
      content: content,
      isUser: false,
      timestamp: Date.now(),
      segments: segments
    } as IChatMessage);
  }

  createErrorMessage(content: string): ChatMessage {
    return new ChatMessage({
      id: `e_${Date.now()}`,
      content: content,
      isUser: false,
      timestamp: Date.now()
    } as IChatMessage);
  }

  createWelcomeMessage(): ChatMessage {
    return new ChatMessage({
      id: WELCOME_MESSAGE.id,
      content: WELCOME_MESSAGE.content,
      isUser: WELCOME_MESSAGE.isUser,
      timestamp: Date.now(),
      segments: WELCOME_MESSAGE.segments
    } as IChatMessage);
  }
}

export const chatStorage = new ChatStorage();
