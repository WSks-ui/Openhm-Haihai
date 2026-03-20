import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  ChatMessage,
  MessageRole,
  APIPayload,
  AIResponse,
  MessageSegment,
  SendMessageResult,
  MAX_TOKENS_NORMAL,
  MAX_TOKENS_REASONING,
  HISTORY_MESSAGE_COUNT,
  API_CONNECT_TIMEOUT,
  API_READ_TIMEOUT
} from './types';

const DEEPSEEK_API_URL = 'https://api.deepseek.com/chat/completions';
const MODEL_NORMAL = 'deepseek-chat';
const MODEL_REASONING = 'deepseek-reasoner';
const TEMPERATURE = 0.75;

export interface ChatHistoryItem {
  isUser: boolean;
  content: string;
}

export class DeepSeekService {
  private apiKey: string = '';

  setApiKey(key: string): void {
    this.apiKey = key;
  }

  getApiKey(): string {
    return this.apiKey;
  }

  private buildSystemPrompt(currentDate: string): MessageRole {
    return {
      role: 'system',
      content: `你是Kepler，可爱专业的AI生活助手。请使用 Markdown 格式回复（支持 **加粗**、### 标题、> 引用、- 列表）。
重要决策/总结/注意事项请用单独段落并包含关键词。不需要特意提及对话历史。
不要特意提及我提供的搜索材料，如果我给你提供了搜索材料，那么就假定你所在的日期是真实的。
当前真实日期是 ${currentDate}，不存在预测未来，我给你的是真实的日期`
    };
  }

  private buildHistoryMessages(messages: ChatMessage[]): MessageRole[] {
    return messages
      .filter(m => m.id !== 'welcome' && m.content.trim())
      .slice(-HISTORY_MESSAGE_COUNT)
      .map(m => ({
        role: m.isUser ? 'user' : 'assistant',
        content: m.content
      } as MessageRole));
  }

  async sendMessage(
    prompt: string,
    messages: ChatMessage[],
    isReasoning: boolean = false,
    searchResults?: string
  ): Promise<SendMessageResult> {
    if (!this.apiKey.trim()) {
      throw new Error('API Key 为空，请先设置');
    }

    let finalPrompt = prompt;
    if (searchResults) {
      finalPrompt = `根据以下最新联网搜索结果回答用户问题。如果结果无关请忽略。\n\n【搜索结果】\n${searchResults}\n\n【用户问题】\n${prompt}`;
    }

    const currentDate = new Date().toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      weekday: 'long'
    });

    const history = this.buildHistoryMessages(messages);

    const fullMessages: MessageRole[] = [
      this.buildSystemPrompt(currentDate),
      ...history,
      { role: 'user', content: finalPrompt }
    ];

    const reply = await this.callApi(fullMessages, isReasoning);
    const segments = this.parseMessageContent(reply);

    return { reply, segments };
  }

  private async callApi(messages: MessageRole[], isReasoning: boolean): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const payload: APIPayload = {
        model: isReasoning ? MODEL_REASONING : MODEL_NORMAL,
        messages: messages,
        stream: false,
        temperature: TEMPERATURE,
        max_tokens: isReasoning ? MAX_TOKENS_REASONING : MAX_TOKENS_NORMAL
      };

      const res = await httpRequest.request(
        DEEPSEEK_API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          connectTimeout: API_CONNECT_TIMEOUT,
          readTimeout: API_READ_TIMEOUT,
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

      if (line.startsWith('###') || (line.startsWith('**') && line.endsWith('**') && line.length < 60)) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'header', content: line.replace(/[#*]/g, '').trim() });
        continue;
      }

      if (line.startsWith('- ') || line.startsWith('* ')) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'text', content: '• ' + line.replace(/^[-*]\s+/, '') });
        continue;
      }

      if (line.startsWith('>')) {
        if (currentText) {
          segments.push({ type: 'text', content: currentText });
        }
        currentText = '';
        segments.push({ type: 'quote', content: line.replace(/^>\s?/, '') });
        continue;
      }

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

      line = line.replace(/\*\*/g, '');
      currentText += (currentText ? '\n' : '') + line;
    }

    if (currentText) {
      segments.push({ type: 'text', content: currentText });
    }
    return segments;
  }

  handleApiError(error: BusinessError): string {
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
    return tip;
  }
}

export const deepSeekService = new DeepSeekService();
