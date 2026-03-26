import http from '@ohos.net.http';

const TAVILY_API_KEY = '暂不提供';
const DEEPSEEK_API_KEY = '暂不提供';

interface TavilyResult {
  content: string;
}

interface TavilyResponse {
  results: TavilyResult[];
  answer?: string;
}

interface DeepSeekMessage {
  role: string;
  content: string;
}

interface DeepSeekRequest {
  model: string;
  messages: DeepSeekMessage[];
  max_tokens: number;
  temperature: number;
}

interface DeepSeekChoice {
  message: DeepSeekMessage;
}

interface DeepSeekResponse {
  choices: DeepSeekChoice[];
}

interface TavilyRequest {
  api_key: string;
  query: string;
  search_depth: string;
  include_answer: boolean;
  max_results: number;
}

export class ContentGenerator {
  
  // 检查网络状态
  static async checkNetwork(): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      // 1. 尝试 HTTP HEAD 请求到百度首页
      const response = await httpRequest.request('https://www.baidu.com', {
        method: http.RequestMethod.HEAD,
        connectTimeout: 5000, // 增加超时时间到 5s
        readTimeout: 5000
      });
      if (response.responseCode === 200) {
        return true;
      }
      throw new Error(`HTTP HEAD failed: ${response.responseCode}`);
    } catch (headError) {
      console.warn('Primary network check failed, trying fallback:', JSON.stringify(headError));
      
      // 2. 备用方案：尝试简单的 GET 请求到另一个稳定地址
      try {
        const fallbackRequest = http.createHttp();
        const response = await fallbackRequest.request('http://www.baidu.com', { // 尝试 http 协议
            method: http.RequestMethod.GET,
            connectTimeout: 5000,
            readTimeout: 5000
        });
        fallbackRequest.destroy();
        return response.responseCode === 200;
      } catch (fallbackError) {
        console.warn('Fallback network check failed:', JSON.stringify(fallbackError));
        // 这里临时返回 true 并打印错误
        // 业务请求改为（DeepSeek/Tavily）
        console.warn('All network checks failed. Assuming online to allow retry.');
        return true; 
      }
    } finally {
      httpRequest.destroy();
    }
  }

  // 生成搜索内容
  static async generateContent(keyword: string): Promise<string> {
    // 1. 检查网络
    const isOnline = await ContentGenerator.checkNetwork();
    if (!isOnline) {
      throw new Error('Network unavailable');
    }

    try {
      // 2. Tavily 搜索
      const searchResults = await ContentGenerator.searchTavily(keyword);
      
      // 3. DeepSeek 生成内容
      const content = await ContentGenerator.generateWithDeepSeek(keyword, searchResults);
      
      return content;
    } catch (err) {
      console.error('Content generation failed:', err);
      throw new Error(JSON.stringify(err));
    }
  }

  private static async searchTavily(keyword: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url = 'https://api.tavily.com/search';
    
    const requestData: TavilyRequest = {
      api_key: TAVILY_API_KEY,
      query: keyword,
      search_depth: "basic",
      include_answer: true,
      max_results: 3
    };

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(requestData),
        readTimeout: 10000,
        connectTimeout: 10000
      });

      if (response.responseCode === 200) {
        const result: TavilyResponse = JSON.parse(response.result as string) as TavilyResponse;
        // 提取搜索结果摘要
        let context = "";
        if (result.results && Array.isArray(result.results)) {
          context = result.results.map((item: TavilyResult) => item.content).join("\n");
        }
        if (result.answer) {
            context = result.answer + "\n" + context;
        }
        return context;
      } else {
        throw new Error(`Tavily API failed: ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  private static async generateWithDeepSeek(keyword: string, context: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url = 'https://api.deepseek.com/chat/completions';
    
    const messages: DeepSeekMessage[] = [
      {
        role: "system",
        content: "你是一个专业的智能助手 Kepler。请根据提供的搜索结果，生成一篇关于该关键词的详细总结。要求：\n1. 内容深度解析，逻辑清晰，分点阐述。\n2. 语言通顺流畅，风格客观专业。\n3. 字数控制在 500 字左右。\n4. 不要包含'根据搜索结果'等引用语，直接给出内容。\n5. 结构建议：引言 -> 核心观点/主要内容 -> 细节分析 -> 结论/展望。"
      },
      {
        role: "user",
        content: `关键词：${keyword}\n\n搜索结果参考：\n${context}`
      }
    ];

    const requestData: DeepSeekRequest = {
      model: "deepseek-chat",
      messages: messages,
      max_tokens: 1000, // 增加生成长度限制以支持 500 字
      temperature: 0.7
    };

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${DEEPSEEK_API_KEY}`
        },
        extraData: JSON.stringify(requestData),
        readTimeout: 20000,
        connectTimeout: 20000
      });

      if (response.responseCode === 200) {
        const result: DeepSeekResponse = JSON.parse(response.result as string) as DeepSeekResponse;
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content.trim();
        }
        return "无法生成内容";
      } else {
        throw new Error(`DeepSeek API failed: ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}
