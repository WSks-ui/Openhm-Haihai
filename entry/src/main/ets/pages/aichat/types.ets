import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@kit.BasicServicesKit';

export interface MessageSegment {
  type: 'text' | 'header' | 'quote' | 'highlight';
  content: string;
}

export interface IChatMessage {
  id?: string;
  content?: string;
  isUser?: boolean;
  timestamp?: number;
  segments?: MessageSegment[];
}

@Observed
export class ChatMessage {
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

  toPlainObject(): IChatMessage {
    return {
      id: this.id,
      content: this.content,
      isUser: this.isUser,
      timestamp: this.timestamp,
      segments: this.segments
    };
  }
}

export interface SuggestionCard {
  title: string;
  desc: string;
  icon: string;
}

export interface MessageRole {
  role: string;
  content: string;
}

export interface AIResponseChoice {
  message: MessageRole;
}

export interface AIResponse {
  choices: AIResponseChoice[];
}

export interface APIPayload {
  model: string;
  messages: MessageRole[];
  stream: boolean;
  temperature: number;
  max_tokens: number;
}

export interface ChatStorageConfig {
  name: string;
  securityLevel: relationalStore.SecurityLevel;
}

export interface ApiKeysData {
  deepseekApiKey: string;
  tavilyApiKey: string;
}

export interface SendMessageResult {
  reply: string;
  segments: MessageSegment[];
}

export interface TavilySearchResult {
  title: string;
  content: string;
  url: string;
}

export interface TavilyResponse {
  results: TavilySearchResult[];
}

export const WELCOME_MESSAGE: IChatMessage = {
  id: 'welcome',
  content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程',
  isUser: false,
  timestamp: Date.now(),
  segments: [
    { type: 'text', content: 'Hi～我是Kepler，您的AI助手，\n可以帮你联网搜索、总结事项、推荐玩法、规划行程' }
  ]
};

export const MAX_MESSAGES: number = 80;
export const HISTORY_MESSAGE_COUNT: number = 10;
export const MAX_TOKENS_NORMAL: number = 2000;
export const MAX_TOKENS_REASONING: number = 4000;
export const API_CONNECT_TIMEOUT: number = 25000;
export const API_READ_TIMEOUT: number = 90000;
export const TAVILY_CONNECT_TIMEOUT: number = 10000;
export const TAVILY_READ_TIMEOUT: number = 10000;
export const TAVILY_MAX_RESULTS: number = 3;
