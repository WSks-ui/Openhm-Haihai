
import { COMMENT_TEMPLATES, CommentCategory } from './commentTemplates';

export const AVATARS = [
  'ID_Wa/20260308215510.jpg', 'ID_Wa/20260308215518.jpg', 'ID_Wa/20260308215521.jpg', 'ID_Wa/20260308215525.jpg',
  'ID_Wa/20260308215531.jpg', 'ID_Wa/20260308215534.jpg', 'ID_Wa/20260308215537.jpg', 'ID_Wa/20260308215541.jpg',
  'ID_Wa/20260308215546.jpg', 'ID_Wa/20260308215548.jpg', 'ID_Wa/20260308215552.jpg', 'ID_Wa/20260308215555.jpg',
  'ID_Wa/20260308215559.jpg', 'ID_Wa/20260308215601.jpg', 'ID_Wa/20260308215604.jpg', 'ID_Wa/20260308215608.jpg',
  'ID_Wa/20260308215611.jpg', 'ID_Wa/20260308215614.jpg', 'ID_Wa/20260308215617.jpg', 'ID_Wa/20260308215620.jpg',
  'ID_Wa/20260308215623.jpg', 'ID_Wa/20260308215626.jpg', 'ID_Wa/20260308215629.jpg', 'ID_Wa/20260308215631.jpg',
  'ID_Wa/20260308215634.jpg', 'ID_Wa/20260308215637.jpg', 'ID_Wa/20260308215641.jpg', 'ID_Wa/20260308215644.jpg',
  'ID_Wa/20260308215647.jpg', 'ID_Wa/20260308215650.jpg', 'ID_Wa/20260308215653.jpg', 'ID_Wa/20260308215656.jpg',
  'ID_Wa/20260308215701.jpg', 'ID_Wa/20260308215703.jpg', 'ID_Wa/20260308215706.jpg', 'ID_Wa/20260308215710.jpg',
  'ID_Wa/20260308215715.jpg', 'ID_Wa/20260308215719.jpg', 'ID_Wa/20260308215722.jpg', 'ID_Wa/20260308215726.jpg',
  'ID_Wa/20260308215752.jpg', 'ID_Wa/20260308215757.jpg', 'ID_Wa/20260308215801.jpg', 'ID_Wa/20260308215804.jpg',
  'ID_Wa/20260308215807.jpg', 'ID_Wa/20260308215810.jpg', 'ID_Wa/20260308215818.jpg', 'ID_Wa/20260308215821.jpg'
];

// 用户名池
export const USER_NAMES = [
  '星辰大海', '代码诗人', '咖啡因依赖者', '追风筝的人', '安静的美男子',
  '程序媛小张', '摄影爱好者老王', '铲屎官阿喵', '旅行达人小李', '健身狂魔',
  '深夜码农', '文艺青年', '吃货小分队', '职场小白', '鸿蒙布道师',
  '开源贡献者', 'UI设计师', '产品经理老刘', '测试工程师', '运维小哥',
  '学生党小明', '自由职业者', '斜杠青年', '数字游民', '极简主义者',
  '热心市民张先生', '佛系少女', '暴躁老哥', '养生达人', '吃土少年',
  '熬夜冠军', '追星女孩', '游戏宅', '猫奴', '狗党',
  '二次元控', '国风爱好者', '旅行博主', '美食探店', '技术宅',
  '产品体验官', '设计狮', '运营喵', 'HR小姐姐', '猎头老王',
  '金融民工', '法务精英', '销售冠军', '创业者老李', '全职妈妈',
  '退休大爷', '广场舞领队', '钓鱼佬', '机车党', '滑板少年'
];

// 时间描述
const TIME_DESCS = [
  '刚刚', '1分钟前', '3分钟前', '5分钟前', '8分钟前', '12分钟前', '18分钟前',
  '25分钟前', '35分钟前', '45分钟前', '55分钟前', '1小时前', '1小时20分钟前',
  '2小时前', '3小时前', '5小时前', '8小时前', '12小时前', '18小时前', '1天前',
  '2天前', '3天前', '5天前', '1周前',
  '10天前', '半个月前', '1个月前', '2个月前', '半年前', '1年前'
];

export interface GeneratedComment {
  id: string;
  userName: string;
  userAvatar: string;
  content: string;
  time: string;
  likes: number;
}

const getCommentTemplates = (category: CommentCategory): string[] => {
  switch (category) {
    case 'tech':
      return COMMENT_TEMPLATES.tech;
    case 'life':
      return COMMENT_TEMPLATES.life;
    case 'pet':
      return COMMENT_TEMPLATES.pet;
    case 'emotion':
      return COMMENT_TEMPLATES.emotion;
    case 'career':
      return COMMENT_TEMPLATES.career;
    default:
      return COMMENT_TEMPLATES.tech;
  }
};

/**
 * 生成指定数量和分类的评论
 * @param category 评论分类
 * @param count 生成数量
 * @param minLength 内容最小长度（字符）
 */
export const generateComments = (
  category: CommentCategory,
  count: number,
  minLength: number = 20
): GeneratedComment[] => {
  const activeTemplates: string[] = getCommentTemplates(category);
  const comments: GeneratedComment[] = [];
  const baseId = Date.now();

  for (let i = 0; i < count; i++) {
    // 随机选择模板
    let content = activeTemplates[Math.floor(Math.random() * activeTemplates.length)];
    
    // 确保内容长度足够（可选：拼接多个模板）
    while (content.length < minLength && activeTemplates.length > 1) {
      const extra = activeTemplates[Math.floor(Math.random() * activeTemplates.length)];
      if (!content.includes(extra)) {
        content += ' ' + extra;
      }
    }

    // 随机用户名
    const userName = USER_NAMES[Math.floor(Math.random() * USER_NAMES.length)];
    
    // 随机时间
    const time = TIME_DESCS[Math.floor(Math.random() * TIME_DESCS.length)];
    
    // 随机点赞数（模拟真实分布：大部分少，少数多）
    const likes = Math.floor(Math.random() * 100);
    const finalLikes = likes < 80 ? Math.floor(likes / 5) : likes; // 80% 评论点赞<16

    comments.push({
      id: `c_${baseId}_${i}`,
      userName,
      userAvatar: AVATARS[Math.floor(Math.random() * AVATARS.length)],
      content,
      time,
      likes: finalLikes
    });
  }

  return comments;
};

/**
 * 批量生成多分类评论（总计约400条）
 */
export const generateAllComments = (): GeneratedComment[] => {
  const allComments: GeneratedComment[] = [];
  
  // 按比例分配（总计约 1000 条，大幅增加数据量以模拟真实场景）
  allComments.push(...generateComments('tech', 250, 30));      // 250条技术
  allComments.push(...generateComments('life', 300, 25));      // 300条生活
  allComments.push(...generateComments('pet', 200, 20));        // 200条宠物
  allComments.push(...generateComments('emotion', 150, 35));    // 150条情感
  allComments.push(...generateComments('career', 100, 40));     // 100条职场
  
  // 随机打乱顺序，模拟真实的时间线混合
  for (let i = allComments.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    let temp = allComments[i];
    allComments[i] = allComments[j];
    allComments[j] = temp;
  }

  return allComments;
};

// =================================================================================================
// 真实 API 接口预留区
// =================================================================================================

/**
 * API 响应接口定义
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * 模拟从服务器获取评论列表
 * @param page 页码
 * @param pageSize 每页数量
 * @returns Promise<GeneratedComment[]>
 */
export const fetchCommentsFromApi = async (page: number = 1, pageSize: number = 20): Promise<GeneratedComment[]> => {
  // 模拟网络延迟 (300ms - 800ms)
  const delay = Math.floor(Math.random() * 500) + 300;
  await new Promise<void>(resolve => setTimeout(resolve, delay));

  // 模拟 API 调用成功
  // 在真实场景中，这里会使用 http.createHttp().request(...)
  // const httpRequest = http.createHttp();
  // const response = await httpRequest.request('https://api.example.com/comments?page=' + page);
  
  // 目前直接返回生成的数据作为 Mock
  // 可以根据页码返回不同的数据切片，模拟分页
  const allData = generateAllComments(); // 注意：这里每次调用都会重新生成随机数据，仅作演示
  const startIndex = (page - 1) * pageSize;
  const endIndex = startIndex + pageSize;
  
  // 如果超出范围，返回空数组
  if (startIndex >= allData.length) {
    return [];
  }
  
  return allData.slice(startIndex, endIndex);
};

/**
 * 模拟发布评论 API
 * @param content 评论内容
 * @returns Promise<boolean>
 */
export const postCommentToApi = async (content: string): Promise<boolean> => {
  // 模拟网络延迟
  await new Promise<void>(resolve => setTimeout(resolve, 600));
  
  // 模拟随机失败 (1% 概率)
  if (Math.random() < 0.01) {
    throw new Error('Network Error: Failed to post comment');
  }
  
  return true;
};

