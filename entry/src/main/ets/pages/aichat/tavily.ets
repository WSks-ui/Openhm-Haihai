import http from '@ohos.net.http';
import {
  TavilyResponse,
  TAVILY_MAX_RESULTS,
  TAVILY_CONNECT_TIMEOUT,
  TAVILY_READ_TIMEOUT
} from './types';

const TAVILY_API_URL = 'https://api.tavily.com/search';

export class TavilySearchService {
  private apiKey: string = '';

  setApiKey(key: string): void {
    this.apiKey = key;
  }

  getApiKey(): string {
    return this.apiKey;
  }

  async search(query: string): Promise<string> {
    if (!this.apiKey) {
      return '';
    }

    const httpRequest = http.createHttp();
    try {
      const res = await httpRequest.request(
        TAVILY_API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            api_key: this.apiKey,
            query: query,
            search_depth: 'basic',
            include_answer: false,
            max_results: TAVILY_MAX_RESULTS
          }),
          connectTimeout: TAVILY_CONNECT_TIMEOUT,
          readTimeout: TAVILY_READ_TIMEOUT
        }
      );

      if (res.responseCode === 200) {
        const data = JSON.parse(res.result as string) as TavilyResponse;
        const results = data.results;
        if (results && results.length > 0) {
          return results.map((item, index) =>
            `[${index + 1}] ${item.title}: ${item.content} (Source: ${item.url})`
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
}

export const tavilySearchService = new TavilySearchService();
