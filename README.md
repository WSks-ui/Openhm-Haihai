# Haihai

一款基于 HarmonyOS / ArkTS 构建的社交分享应用。

## 应用信息

| 属性 | 值 |
|-----|-----|
| 包名 | com.example.myapplication4 |
| 版本 | 1.0.0 |
| 平台 | HarmonyOS |
| 设备支持 | 手机、平板、二合一设备、可穿戴设备 |

## 权限说明

- `ohos.permission.INTERNET` - 网络访问
- `ohos.permission.MICROPHONE` - 麦克风（语音输入）
- `ohos.permission.CAMERA` - 相机（拍照发布）
- `ohos.permission.DETECT_GESTURE` - 手势检测

## 项目结构

```
entry/src/main/ets/
├── components/                         # UI 组件库
│   ├── common/                         # 通用组件（全局可复用）
│   │   ├── AnimatedBackground.ets      # 动态背景 - 全屏渐变动画背景
│   │   ├── LiquidGlass.ets             # 玻璃态组件 - 毛玻璃/玻璃拟态效果，支持模糊度/透明度/流光动画
│   │   ├── MineSidebar.ets             # 侧边栏 - "我的"页面侧边导航栏
│   │   ├── PageHeader.ets              # 页面头部 - 通用标题栏组件
│   │   ├── PublishMenu.ets             # 发布菜单 - 浮动发布按钮及菜单
│   │   └── SliderCaptcha.ets            # 滑块验证 - 拖动滑块完成验证
│   ├── dialogs/                        # 对话框组件
│   │   ├── AgreementDialog.ets          # 协议对话框 - 用户协议/隐私政策展示
│   │   ├── SliderCaptchaDialog.ets      # 滑块验证对话框 - 验证弹窗
│   │   └── VoiceInputDialog.ets         # 语音输入对话框 - 语音转文字输入
│   ├── discover/                       # 发现页组件
│   │   └── DiscoverComponent.ets        # 发现页主体 - 内容推荐/话题广场入口
│   ├── home/                           # 首页组件
│   │   └── HomeComponent.ets            # 首页主体 - 底部Tab首页
│   ├── message/                        # 消息组件
│   │   ├── AccountSettingsPanel.ets    # 账户设置面板 - 账户相关设置
│   │   └── MessageComponent.ets         # 消息列表 - 通知/评论/点赞消息
│   ├── mine/                           # "我的"页面组件
│   │   ├── DarkModeSettingsPanel.ets   # 深色模式设置 - 主题切换
│   │   ├── MineComponent.ets           # "我的"页面主体
│   │   ├── MyDraftsPanel.ets           # 我的草稿 - 帖子草稿管理
│   │   ├── MyHistoryPanel.ets          # 浏览历史 - 足迹记录
│   │   ├── MyLikesPanel.ets            # 点赞收藏 - 我点赞的内容
│   │   └── StorageCleanPanel.ets       # 存储清理 - 缓存清理
│   ├── search/                         # 搜索组件
│   │   ├── SearchPage.ets              # 搜索页 - 搜索入口及热门推荐
│   │   └── search_result/              # 搜索结果子组件
│   │       ├── AllResultsView.ets       # 全部结果 - 综合搜索结果
│   │       ├── KeplerResultView.ets     # 凯勒结果 - 特定来源搜索结果
│   │       ├── PostWaterFlow.ets       # 瀑布流 - 帖子瀑布流展示
│   │       ├── SearchLoadingSkeleton.ets # 骨架屏 - 加载占位动画
│   │       └── UserResultsView.ets      # 用户结果 - 搜索到的用户列表
│   └── settings/                       # 设置相关组件
│       ├── EditProfilePanel.ets        # 编辑资料 - 头像/昵称/简介编辑
│       ├── LiquidGlassSettingsPanel.ets # 玻璃设置 - 玻璃态效果参数配置
│       ├── NotificationPanels.ets      # 通知设置 - 推送/消息通知
│       ├── PrivacySettingsPanel.ets     # 隐私设置 - 可见性/黑名单
│       ├── SecurityPanels.ets           # 安全设置 - 密码/手机号/邮箱
│       └── SettingItemBuilders.ets     # 设置项构建器 - 通用设置项UI
│
├── entryability/                       # 应用入口Ability
│   └── EntryAbility.ets                # 主入口Ability - 应用启动入口
│
├── entrybackupability/                  # 备份Ability
│   └── EntryBackupAbility.ets          # 数据备份/恢复能力
│
├── model/                              # 数据模型层
│   ├── AppStatistics.ets               # 应用统计 - 启动次数/使用时长
│   ├── Post.ets                        # 帖子模型 - id/内容/作者/图片/点赞数
│   ├── SearchData.ets                  # 搜索数据 - 搜索历史/热门搜索
│   ├── SidebarItemModel.ets            # 侧边栏项 - 导航菜单数据模型
│   ├── User.ets                        # 用户模型 - id/用户名/头像/简介/性别
│   ├── UserModel.ets                   # 用户管理 - 用户状态管理
│   ├── commentGenerator.ets            # 评论生成器 - AI辅助评论
│   └── commentTemplates.ets             # 评论模板 - 预设评论内容
│
├── pages/                              # 页面
│   ├── AIChatPage.ets                  # AI聊天主页 - DeepSeek/Tavily对话
│   ├── ChatDetailPage.ets               # 聊天详情 - 私聊消息
│   ├── ChatSplitPage.ets               # 分屏聊天 - 多窗口聊天
│   ├── CreatePostPage.ets              # 创建帖子 - 发布图文内容
│   ├── Index.ets                        # 首页 - 底部Tab主入口
│   ├── LoginPage.ets                   # 登录页 - 手机号/验证码登录
│   ├── PostDetailPage.ets              # 帖子详情 - 帖子内容/评论
│   ├── RegisterPage.ets                 # 注册页 - 用户注册
│   ├── SearchResultPage.ets            # 搜索结果页 - 展示搜索结果
│   ├── SettingsPage.ets                 # 设置页 - 应用设置
│   ├── aichat/                         # AI聊天子模块
│   │   ├── ApiKeyDialog.ets            # API Key配置对话框 - 配置DeepSeek/Tavily密钥
│   │   ├── ChatHeaderBar.ets           # 聊天头部 - 返回/标题/更多按钮
│   │   ├── ChatInputBar.ets            # 聊天输入栏 - 文本/语音输入切换
│   │   ├── MessageBubble.ets            # 消息气泡 - 对话消息展示
│   │   ├── SuggestionCards.ets         # 建议卡片 - AI推荐问题
│   │   ├── deepseek.ets                # DeepSeek服务 - AI对话能力封装
│   │   ├── tavily.ets                  # Tavily搜索 - AI增强搜索
│   │   └── types.ets                   # 类型定义 - 聊天消息/状态类型
│   ├── discover/                       # 发现子模块
│   │   ├── DailyPicksPage.ets         # 每日精选 - 优质内容推荐
│   │   └── TopicSquarePage.ets         # 话题广场 - 话题列表/热门话题
│   └── mine/                           # "我的"子模块
│       └── EditProfilePage.ets         # 编辑资料页 - 个人信息编辑
│
├── types/                              # 类型定义
│   └── SettingsTypes.ets               # 设置相关类型 - 设置项/配置类型
│
└── utils/                              # 工具服务层
    ├── AISummaryService.ets           # AI摘要服务 - 文章/内容AI总结
    ├── AliyunSMSService.ets           # 阿里云短信 - 短信验证码发送
    ├── BreakpointSystem.ets            # 断点系统 - 响应式布局断点管理
    ├── ContentGenerator.ets           # 内容生成器 - AI辅助内容创作
    ├── DraftManager.ets               # 草稿管理 - 本地草稿存取
    ├── HistoryManager.ets              # 历史管理 - 浏览历史记录
    ├── HoldingHandManager.ets         # 牵手服务 - 配对/社交功能
    ├── LikeManager.ets                 # 点赞管理 - 点赞状态同步
    ├── PhotoPickerService.ets         # 图片选择 - 相册/相机图片选取
    ├── PreferencesStorage.ets         # 偏好存储 - 轻量级本地存储
    ├── SMSService.ets                  # 短信服务 - 验证码发送抽象
    ├── ScanCodeService.ets             # 扫码服务 - 扫描二维码/条码
    ├── SpeechRecognitionService.ets    # 语音识别 - 语音转文字(单例模式)
    └── VerifyCodeManager.ets           # 验证码管理 - 倒计时/校验逻辑
```

## 功能模块

| 模块 | 说明 |
|-----|-----|
| 首页 (Index) | 应用主入口 |
| 发现 (Discover) | 内容发现、话题广场 |
| 消息 (Message) | 消息通知 |
| 我的 (Mine) | 个人中心、设置 |
| AI 聊天 (AIChat) | DeepSeek / Tavily AI 对话 |
| 搜索 (Search) | 搜索结果、用户、帖子 |

## 技术栈

- **框架**: HarmonyOS SDK
- **语言**: ArkTS (TypeScript)
- **UI**: 自定义组件 + 玻璃态效果 (LiquidGlass)
- **AI 服务**: DeepSeek API / Tavily Search API
- **存储**: PreferencesStorage / 草稿箱

## 代码统计

| 类型 | 数量 |
|-----|-----|
| ETS 文件 | 95 个 |
| 代码行数 | ~20,135 行 |

## License

MIT
