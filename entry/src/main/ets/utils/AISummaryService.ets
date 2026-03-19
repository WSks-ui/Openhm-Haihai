import http from '@ohos.net.http';
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@kit.BasicServicesKit';

interface SummaryResult {
  content: string;
  timestamp: number;
}

interface MessageContent {
  content: string;
}

interface MessageRole {
  role: string;
  content: string;
}

interface Choice {
  message: MessageContent;
}

interface ApiResponse {
  choices: Choice[];
}

interface ApiPayload {
  model: string;
  messages: MessageRole[];
  stream: boolean;
  temperature: number;
  max_tokens: number;
}

interface HttpResponseData {
  responseCode: number;
  result: string | Object;
}

class AISummaryService {
  private rdbStore: relationalStore.RdbStore | null = null;
  private debounceTimer: number | null = null;
  private debounceDelay: number = 1000;
  private apiKey: string = '';
  private pendingRequest: string | null = null;

  async init(): Promise<void> {
    await this.initRdb();
    await this.loadApiKey();
  }

  private async initRdb(): Promise<void> {
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
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS summaries (id TEXT PRIMARY KEY, content TEXT, timestamp INTEGER)'
      );
    } catch (e) {
      console.error('[AISummary] RdbStore 初始化失败', e);
    }
  }

  private async loadApiKey(): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'deepseek_api_key');
      let resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        const storedKey: string = resultSet.getString(resultSet.getColumnIndex('value'));
        this.apiKey = storedKey.trim();
      }
      resultSet.close();
    } catch (e) {
      console.error('[AISummary] 加载 API Key 失败', e);
    }
  }

  private async getCachedSummary(id: string): Promise<SummaryResult | null> {
    await this.initRdb();
    if (!this.rdbStore) {
      return null;
    }
    try {
      let predicates = new relationalStore.RdbPredicates('summaries');
      predicates.equalTo('id', id);
      let resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        const content: string = resultSet.getString(resultSet.getColumnIndex('content'));
        const timestampVal: number = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
        resultSet.close();
        const result: SummaryResult = { content: content, timestamp: timestampVal };
        return result;
      }
      resultSet.close();
    } catch (e) {
      console.error('[AISummary] 获取缓存摘要失败', e);
    }
    return null;
  }

  private async saveSummary(id: string, content: string): Promise<void> {
    await this.initRdb();
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: id,
        content: content,
        timestamp: Date.now()
      };
      await this.rdbStore.insert(
        'summaries',
        bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
    } catch (e) {
      console.error('[AISummary] 保存摘要失败', e);
    }
  }

  async generateSummary(
    id: string,
    content: string,
    onStateChange?: (state: 'loading' | 'success' | 'error', data?: string) => void
  ): Promise<string> {
    if (!this.apiKey) {
      onStateChange?.('error', '请先在 AI 助手页面设置 API Key');
      return '';
    }

    const cached = await this.getCachedSummary(id);
    if (cached) {
      onStateChange?.('success', cached.content);
      return cached.content;
    }

    if (this.pendingRequest === id) {
      return '';
    }

    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }

    this.debounceTimer = setTimeout(async () => {
      await this.doGenerateSummary(id, content, onStateChange);
    }, this.debounceDelay);

    return '';
  }

  private async doGenerateSummary(
    id: string,
    content: string,
    onStateChange?: (state: 'loading' | 'success' | 'error', data?: string) => void,
    retryCount: number = 0
  ): Promise<void> {
    this.pendingRequest = id;
    onStateChange?.('loading');

    const prompt: string = `请对以下内容生成简洁的摘要，控制在60字以内，突出核心信息。\n\n【内容】\n${content}`;

    const systemMsg: MessageRole = { role: 'system', content: '你是一个专业的文章摘要助手，请用简洁的语言概括文章要点。' };
    const userMsg: MessageRole = { role: 'user', content: prompt };
    const messages: MessageRole[] = [systemMsg, userMsg];

    const payload: ApiPayload = {
      model: 'deepseek-chat',
      messages: messages,
      stream: false,
      temperature: 0.7,
      max_tokens: 200
    };

    const httpRequest = http.createHttp();
    try {
      const res = await httpRequest.request(
        'https://api.deepseek.com/chat/completions',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          connectTimeout: 30000,
          readTimeout: 30000,
          extraData: JSON.stringify(payload)
        }
      ) as HttpResponseData;

      if (res.responseCode !== 200) {
        if (retryCount < 2) {
          await new Promise<void>(resolve => setTimeout(resolve, 1000));
          await this.doGenerateSummary(id, content, onStateChange, retryCount + 1);
          return;
        }
        let errorMsg: string = `HTTP ${res.responseCode}`;
        try {
          const errData: Record<string, Object> = JSON.parse(res.result as string) as Record<string, Object>;
          const errorObj: Record<string, Object> = errData['error'] as Record<string, Object>;
          const msg: string = (errorObj && errorObj['message']) as string;
          errorMsg += ` - ${msg || JSON.stringify(errData)}`;
        } catch {
        }
        onStateChange?.('error', errorMsg);
        return;
      }

      const data: ApiResponse = JSON.parse(res.result as string) as ApiResponse;
      const summary: string = data.choices?.[0]?.message?.content?.trim() || '';

      if (summary) {
        await this.saveSummary(id, summary);
        onStateChange?.('success', summary);
      } else {
        onStateChange?.('error', '生成摘要为空');
      }
    } catch (e) {
      if (retryCount < 2) {
        await new Promise<void>(resolve => setTimeout(resolve, 1000));
        await this.doGenerateSummary(id, content, onStateChange, retryCount + 1);
        return;
      }
      const errMsg: string = e instanceof Error ? e.message : '网络异常，请检查网络连接';
      onStateChange?.('error', errMsg);
    } finally {
      httpRequest.destroy();
      this.pendingRequest = null;
    }
  }

  async retry(id: string, content: string, onStateChange?: (state: 'loading' | 'success' | 'error', data?: string) => void): Promise<void> {
    await this.doGenerateSummary(id, content, onStateChange, 0);
  }
}

export const aiSummaryService = new AISummaryService();
