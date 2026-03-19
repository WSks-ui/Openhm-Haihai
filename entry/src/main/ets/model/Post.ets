import { generateComments, GeneratedComment } from './commentGenerator';
import { CommentCategory } from './commentTemplates';

export class Comment {
  id: string;
  userName: string;
  userAvatar: string;
  content: string;
  time: string;
  likes: number;

  constructor(id: string, userName: string, userAvatar: string, content: string, time: string, likes: number) {
    this.id = id;
    this.userName = userName;
    this.userAvatar = userAvatar;
    this.content = content;
    this.time = time;
    this.likes = likes;
  }
}

export class Post {
  id: string;
  userName: string;
  userAvatar: string;
  content: string;
  images: string[];
  videoUrl?: string;
  likes: number;
  commentsCount: number;
  time: string;
  isLiked: boolean;
  title?: string;
  commentList: Comment[];

  constructor(id: string, userName: string, userAvatar: string, content: string, images: string[], likes: number, commentsCount: number, time: string, title?: string, commentList?: Comment[]) {
    this.id = id;
    this.userName = userName;
    this.userAvatar = userAvatar;
    this.content = content;
    this.images = images;
    this.likes = likes;
    this.commentsCount = commentsCount;
    this.time = time;
    this.isLiked = false;
    this.title = title || '';
    this.commentList = commentList || [];
  }

  copy(): Post {
    const newPost = new Post(
      this.id,
      this.userName,
      this.userAvatar,
      this.content,
      [...this.images],
      this.likes,
      this.commentsCount,
      this.time,
      this.title,
      [...this.commentList]
    );
    newPost.isLiked = this.isLiked;
    newPost.videoUrl = this.videoUrl;
    return newPost;
  }
}

const getComments = (category: CommentCategory, count: number): Comment[] => {
  const generated = generateComments(category, count);
  return generated.map(c => new Comment(c.id, c.userName, c.userAvatar, c.content, c.time, c.likes));
};

export const mockPosts: Post[] = [
  new Post('1', '爱丽丝', 'ID_Wa/20260308215510.jpg', '今天天气真好，出来晒晒太阳，心情也变好了呢！ 公园里的花都开了，五颜六色的，空气中弥漫着淡淡的花香。看着孩子们在草地上奔跑，感觉时间都慢了下来。', ['pexels-chrisjmitchell-1528361.jpg'], 120, 15, '10 分钟前', '阳光明媚的一天', getComments('life', 15)),
  
  new Post('2', '鲍勃', 'ID_Wa/20260308215518.jpg', '刚健完身，感觉棒极了，汗水是脂肪的眼泪： 今天挑战了新的重量，虽然很累，但是看到肌肉充血的感觉真的很爽。坚持就是胜利，大家一起加油！', ['pexels-sabel-blanco-662810-1756959.jpg'], 45, 8, '1 小时前', '健身打卡', getComments('life', 8)),
  
  new Post('3', '查理', 'ID_Wa/20260308215521.jpg', '看看这风景，大自然的鬼斧神工令人惊叹。站在山顶俯瞰，云海翻腾，仿佛置身仙境。这一刻，所有的烦恼都烟消云散了。下次一定要带家人一起来看看。', ['pexels-souvenirpixels-417074.jpg', 'pexels-eberhardgross-640809.jpg'], 300, 50, '2 小时前', '绝美风景', getComments('life', 50)),
  
  new Post('4', '大卫', 'ID_Wa/20260308215525.jpg', '有人知道怎么修这个 Bug 吗？在线等，挺急的。 报错信息是 NullPointerException，但是我明明已经判空了啊。在这个方法里调用的时候偶尔会崩，复现概率大概 10%。有没有大佬帮忙看看？', ['pexels-markusspiske-2061168.jpg'], 12, 12, '3 小时前', '求助', getComments('tech', 12)),
  
  new Post('5', '伊芙', 'ID_Wa/20260308215531.jpg', '祝大家周末愉快，好好休息，迎接新的一周！ 打算在家看几部电影，再做顿好吃的。平时工作太忙，周末就是用来充电的。', ['pexels-hamann-la-338986-1131575.jpg'], 88, 20, '5 小时前', '周末愉快', getComments('life', 20)),
  
  new Post('6', '弗兰克', 'ID_Wa/20260308215534.jpg', '刚试了市中心的新咖啡店，拿铁味道很正，强烈推荐！ 店里的装修很有格调，适合拍照打卡。甜点也不错，特别是那个提拉米苏，入口即化。', ['pexels-quark-studio-1159039-2506993.jpg'], 56, 10, '6 小时前', '探店日记', getComments('life', 10)),
  
  new Post('7', '格蕾丝', 'ID_Wa/20260308215537.jpg', '熬夜写代码中... 咖啡是我的续命水。 项目上线前的最后冲刺，大家都在加班。虽然很累，但是看到功能一个个实现，还是很有成就感的。', [], 234, 45, '8 小时前', '程序员的日常', getComments('tech', 45)),
  
  new Post('8', '汉克', 'ID_Wa/20260308215541.jpg', '看看我的新小狗！它叫旺财，超级可爱！ 刚到家还有点害羞，躲在沙发底下不肯出来。给它喂了点狗粮，终于肯让我摸摸头了。以后就是家里的一员啦！', ['pexels-sart-face-209620-672244.jpg'], 567, 120, '12 小时前', '萌宠时刻', getComments('pet', 120)),
  
  new Post('9', '艾薇', 'ID_Wa/20260308215546.jpg', '这周末有人想去爬山吗？一起去呼吸新鲜空气吧！ 计划去爬西山，大概需要 3 个小时。山顶有茶室，可以一边喝茶一边看风景。想去的私信我报名哦。', [], 34, 18, '1 天前', '户外活动召集', getComments('life', 18)),
  
  new Post('10', '杰克', 'ID_Wa/20260308215548.jpg', '美丽的日落！夕阳无限好，只是近黄昏。 每次看到日落，都会感叹时间的流逝。珍惜当下，过好每一天。', ['pexels-pixabay-269583.jpg'], 890, 60, '1 天前', '日落', getComments('life', 60)),
  
  new Post('11', '凯文', 'ID_Wa/20260308215552.jpg', '正在学习鸿蒙开发，ArkTS 语法很简洁，非常有趣！ 相比于 Java，代码量少了很多，而且声明式 UI 写起来很顺手。DevEco Studio 也越来越好用了。', [], 67, 25, '2 天前', '学习打卡', getComments('tech', 25)),
  
  new Post('12', '莉莉', 'ID_Wa/20260308215555.jpg', '和朋友们吃了一顿美味的晚餐，开心！ 这家火锅店的服务真的太好了，食材也很新鲜。虽然排队排了一个小时，但是完全值得！', ['pexels-cedric-fauntleroy-7221389.jpg'], 123, 30, '2 天前', '美食分享', getComments('life', 30)),
  
  new Post('13', '迈克', 'ID_Wa/20260308215559.jpg', '迫不及待想看下周的演唱会！激动的心，颤抖的手！抢票简直是拼手速，还好运气不错抢到了。已经开始循环播放歌单了，期待现场的大合唱！', [], 45, 15, '3 天前', '演唱会倒计时', getComments('life', 15)),
  
  new Post('14', '南希', 'ID_Wa/20260308215601.jpg', '正在读一本好书，推荐给大家《百年孤独》。 马尔克斯的文字真的太有魔力了，开头那句"多年以后，奥雷连诺上校站在行刑队面前..." 简直经典。', ['pexels-fotios-photos-1430796.jpg'], 78, 22, '3 天前', '好书推荐', getComments('life', 22)),
  
  new Post('15', '奥斯卡', 'ID_Wa/20260308215604.jpg', '早安，世界！新的一天，新的开始。 不管昨天发生了什么，今天都是新的一页。保持积极的心态，加油！', [], 22, 5, '4 天前', '早安', getComments('emotion', 5)),
  
  new Post('16', '保罗', 'ID_Wa/20260308215608.jpg', '刚买了一把新吉他，准备开始学琴了！ 一直都很喜欢吉他的声音，终于下定决心要自己学了。希望能坚持下去，学会弹唱自己喜欢的歌。', ['pexels-reneterp-1539788.jpg'], 156, 40, '5 天前', '新装备', getComments('life', 40)),
  
  new Post('17', '奎因', 'ID_Wa/20260308215611.jpg', '旅行的回忆... 那个夏天，风很轻，云很淡。️ 翻看照片，仿佛又回到了那个海边小镇。海鲜很好吃，人也很热情。期待下一次的旅行。', ['pexels-anastasia-shuraeva-4210032.jpg', 'pexels-peng-louis-587527-1450331.jpg'], 999, 100, '1 周前', '旅行回忆', getComments('life', 100)),
  
  new Post('18', '职场小萌新', 'ID_Wa/20260308215614.jpg', '刚入职一家互联网大厂，感觉压力好大。周围的同事都好优秀，觉得自己好多东西都不会。每天都在焦虑中度过，求前辈们指点迷津！', [], 88, 35, '2 小时前', '职场困惑', getComments('career', 35)),

  new Post('19', '深夜网抑云', 'ID_Wa/20260308215617.jpg', '在这个深夜，突然觉得好孤独。看着窗外的灯火，不知道哪一盏是为我而留。也许成长的代价就是学会一个人独处吧。', [], 234, 55, '1 天前', '深夜感慨', getComments('emotion', 55)),

  new Post('20', '技术宅', 'ID_Wa/20260308215620.jpg', '终于搞定了这个复杂的算法！推导了整整三天，头发都掉了一把。不过看到测试通过的那一刻，所有的付出都值了！', [], 567, 42, '3 天前', '算法攻坚', getComments('tech', 42)),

  new Post('21', '科技达人小张', 'ID_Wa/20260308215623.jpg', '鸿蒙原生应用开发真的太香了！之前用跨平台框架总有一些性能瓶颈，现在用 ArkTS + ArkUI 做的应用，流畅度简直提升了一个档次。特别是列表滚动，丝滑得像德芙巧克力！', [], 456, 78, '5 小时前', '鸿蒙开发心得', getComments('tech', 78)),

  new Post('22', 'AI 探索者', 'ID_Wa/20260308215626.jpg', '尝试了最新的大模型 API，效果惊艳！输入一段简单的需求描述，它就能生成完整的代码框架，还附带详细的注释。以前要写半天的功能，现在几分钟就搞定了。科技改变生活啊！', ['pexels-pixabay-35550.jpg'], 890, 120, '8 小时前', 'AI 编程初体验', getComments('tech', 120)),

  new Post('23', '美食博主小王', 'ID_Wa/20260308215629.jpg', '今天尝试做了一道红烧排骨，简直是人间美味！先焯水去腥，再用冰糖炒糖色，小火慢炖一个小时，最后大火收汁。成品色泽红亮，肉质软烂，入口即化。隔壁小孩都馋哭了！', ['pexels-filirovska-8250685.jpg', 'pexels-angela-roma-7363753.jpg'], 789, 56, '1 天前', '红烧排骨教程', getComments('life', 56)),

  new Post('24', '甜品爱好者', 'ID_Wa/20260308215631.jpg', '周末在家做了提拉米苏，第一次尝试就成功了！马斯卡彭芝士混合淡奶油，加上浓缩咖啡和手指饼干，最后撒上可可粉。口感绵密，咖啡香与芝士香完美融合，幸福感爆棚！', ['pexels-nikita-khandelwal-178978-963755.jpg'], 445, 34, '2 天前', '提拉米苏初体验', getComments('life', 34)),

  new Post('25', '背包客小李', 'ID_Wa/20260308215634.jpg', '终于来到了梦寐以求的丽江古城！清晨的古城没有太多游客，石板路上只有偶尔经过的当地人。阳光洒在青瓦白墙上，显得格外宁静。找一家小店，点一杯普洱，看着窗外发呆，这就是旅行的意义吧。', ['pexels-franklin-david-3796266-8936979.jpg', 'pexels-peng-louis-587527-1450331.jpg'], 1234, 156, '3 天前', '丽江古城游记', getComments('life', 156)),

  new Post('26', '海岛控', 'ID_Wa/20260308215637.jpg', '三亚的海真的太蓝了！站在沙滩上，看着一望无际的大海，所有的烦恼都烟消云散了。白天在海里游泳、浮潜，晚上在沙滩上散步、看星星。这种生活，给个神仙都不换！', ['pexels-fotios-photos-1048273.jpg'], 999, 98, '4 天前', '三亚度假', getComments('life', 98)),

  new Post('27', '深夜诗人', 'ID_Wa/20260308215641.jpg', '有些话，只能在深夜说给自己听。白天戴着面具生活，只有在夜深人静的时候，才能做回真正的自己。不知道从什么时候开始，笑只是一种表情，而不是心情。但无论如何，明天还是要继续。', [], 567, 89, '1 天前', '深夜独白', getComments('emotion', 89)),

  new Post('28', '温暖小太阳', 'ID_Wa/20260308215644.jpg', '今天收到了一个陌生人的微笑，突然觉得整个世界都明亮了。有时候，快乐就是这么简单。一个善意的眼神，一句温暖的问候，都能给人带来一整天的好心情。让我们一起做一个温暖的人吧！', [], 334, 45, '5 小时前', '传递温暖', getComments('emotion', 45)),

  new Post('29', '职场老司机', 'ID_Wa/20260308215647.jpg', '今天开会又被领导批了，不过这次我没有像以前那样沮丧。工作这么多年，我明白了一个道理：批评不一定是坏事，有时候它能让你成长得更快。保持一个好的心态，比什么都重要。', [], 234, 67, '2 小时前', '职场心得', getComments('career', 67)),

  new Post('30', '求职路上', 'ID_Wa/20260308215650.jpg', '裸辞两个月了，面试了十几家公司，还没找到合适的。有时候会怀疑自己，是不是真的很差劲。但转念一想，这只是暂时的，我一定能找到属于自己的机会。加油，不要放弃！', [], 678, 98, '6 小时前', '求职感悟', getComments('career', 98)),

  new Post('31', '铲屎官小美', 'ID_Wa/20260308215653.jpg', '我家橘猫今天又闯祸了！把我的水杯打翻，键盘里全是水。看着它一脸无辜的样子，真是又好气又好笑。算了，自己选的主子，哭着也要宠完。谁让它这么可爱呢！', ['pexels-peng-louis-587527-1450331.jpg'], 888, 123, '1 天前', '橘猫日常', getComments('pet', 123)),

  new Post('32', '狗狗爱好者', 'ID_Wa/20260308215656.jpg', '带家里的柴犬去宠物公园，它一进去就跟脱缰的野马一样，到处乱跑。后来遇到了一只小母狗，就一直跟在人家屁股后面，怎么叫都不走。真是个见色忘义的家伙！', ['pexels-shvetsa-4588013.jpg'], 567, 76, '3 天前', '柴犬相亲记', getComments('pet', 76)),

  new Post('33', '考研党', 'ID_Wa/20260308215701.jpg', '考研复习已经进入冲刺阶段了，每天早出晚归，图书馆、食堂、宿舍三点一线。虽然很累，但一想到自己的目标，就充满了动力。坚持到底，就是胜利！相信自己一定能考上理想的学校！', ['pexels-souvenirpixels-417074.jpg'], 456, 87, '4 小时前', '考研冲刺', getComments('life', 87)),

  new Post('34', '语言学习ing', 'ID_Wa/20260308215703.jpg', '学习日语三个月了，今天终于能够无障碍地看一部简单的动漫了！虽然还有很多生词，但这种进步的感觉真的太棒了。学习语言虽然枯燥，但只要坚持，就一定会有收获。', [], 345, 56, '1 天前', '日语学习心得', getComments('life', 56)),

  new Post('35', '智能家居控', 'ID_Wa/20260308215706.jpg', '终于把家里的智能家居设备都配齐了！现在可以用语音控制灯光、空调、窗帘，甚至还能远程喂猫。科技真的改变生活，以前幻想的生活场景，现在都实现了。强烈推荐给大家！', ['pexels-pixabay-275484.jpg'], 678, 89, '7 小时前', '智能家居体验', getComments('tech', 89)),

  new Post('36', '川菜爱好者', 'ID_Wa/20260308215710.jpg', '今天去吃了一家正宗的川菜馆，毛血旺、水煮鱼、麻婆豆腐，每一道都超级好吃！辣得过瘾，麻得舒服，吃到停不下来。作为一个无辣不欢的人，这简直是天堂！', ['pexels-rohanmuzafar-3054690.jpg'], 555, 67, '1 天前', '川菜探店', getComments('life', 67)),

  new Post('37', '登山爱好者', 'ID_Wa/20260308215715.jpg', '今天成功登顶了黄山！虽然过程很艰难，累得腿都快断了，但当看到山顶云海的那一刻，一切都值了。云雾缭绕，仿佛置身仙境。建议大家一定要来一次，绝对不会后悔！', ['pexels-sanmane-1365425.jpg'], 1111, 178, '2 天前', '黄山登顶', getComments('life', 178)),

  new Post('38', '程序员小白', 'ID_Wa/20260308215719.jpg', '作为一个刚入行的程序员，今天第一次独立完成了一个功能模块。虽然代码可能写得不够优雅，还有很多可以优化的地方，但这种成就感真的难以言表。继续加油，争取早日成为大神！', ['pexels-cottonbro-5473298.jpg'], 234, 56, '3 天前', '成长记录', getComments('tech', 56)),

  new Post('39', '多肉控', 'ID_Wa/20260308215722.jpg', '不知不觉已经养了50多盆多肉了！每次看到它们胖乎乎的样子，心情就特别好。虽然养死过不少，但也积累了很多经验。现在看到喜欢的品种还是忍不住想买，真是个无底洞啊！', ['pexels-nietjuhart-776656.jpg'], 444, 67, '4 天前', '多肉花园', getComments('life', 67)),

  new Post('40', '独立开发者', 'ID_Wa/20260308215726.jpg', '经过三个月的努力，我的第一个独立应用终于上线了！虽然下载量不多，但看到有用户给好评，真的很感动。独立开发这条路很难，但只要坚持，就一定会有收获。继续努力，更新更多功能！', ['pexels-markusspiske-2061168.jpg'], 777, 123, '5 天前', 'App 上线', getComments('tech', 123))
];

export let currentKeplerPost: Post | null = null;

export const setCurrentKeplerPost = (post: Post | null) => {
  currentKeplerPost = post;
}