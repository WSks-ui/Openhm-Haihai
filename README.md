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
├── components/                    # UI 组件库
│   ├── common/                    # 通用组件
│   │   ├── AnimatedBackground.ets # 动态背景
│   │   ├── LiquidGlass.ets        # 玻璃态效果
│   │   ├── MineSidebar.ets        # 侧边栏
│   │   ├── PageHeader.ets         # 页面头部
│   │   ├── PublishMenu.ets        # 发布菜单
│   │   └── SliderCaptcha.ets       # 滑块验证
│   ├── dialogs/                   # 对话框
│   │   ├── AgreementDialog.ets    # 协议对话框
│   │   ├── SliderCaptchaDialog.ets
│   │   └── VoiceInputDialog.ets   # 语音输入
│   ├── discover/                  # 发现页
│   │   └── DiscoverComponent.ets
│   ├── home/                      # 首页
│   │   └── HomeComponent.ets
│   ├── message/                   # 消息
│   │   ├── AccountSettingsPanel.ets
│   │   └── MessageComponent.ets
│   ├── mine/                      # 我的
│   │   ├── DarkModeSettingsPanel.ets
│   │   ├── MineComponent.ets
│   │   ├── MyDraftsPanel.ets
│   │   ├── MyHistoryPanel.ets
│   │   ├── MyLikesPanel.ets
│   │   └── StorageCleanPanel.ets
│   ├── search/                    # 搜索
│   │   ├── SearchPage.ets
│   │   └── search_result/
│   │       ├── AllResultsView.ets
│   │       ├── KeplerResultView.ets
│   │       ├── PostWaterFlow.ets
│   │       ├── SearchLoadingSkeleton.ets
│   │       └── UserResultsView.ets
│   └── settings/                  # 设置
│       ├── EditProfilePanel.ets
│       ├── LiquidGlassSettingsPanel.ets
│       ├── NotificationPanels.ets
│       ├── PrivacySettingsPanel.ets
│       ├── SecurityPanels.ets
│       └── SettingItemBuilders.ets
│
├── entryability/                  # 应用入口
│   └── EntryAbility.ets
│
├── entrybackupability/            # 备份能力
│   └── EntryBackupAbility.ets
│
├── model/                         # 数据模型
│   ├── AppStatistics.ets
│   ├── Post.ets
│   ├── SearchData.ets
│   ├── SidebarItemModel.ets
│   ├── User.ets
│   ├── UserModel.ets
│   ├── commentGenerator.ets
│   └── commentTemplates.ets
│
├── pages/                         # 页面
│   ├── AIChatPage.ets             # AI 聊天
│   ├── ChatDetailPage.ets
│   ├── ChatSplitPage.ets
│   ├── CreatePostPage.ets         # 创建帖子
│   ├── Index.ets                  # 首页
│   ├── LoginPage.ets              # 登录
│   ├── PostDetailPage.ets         # 帖子详情
│   ├── RegisterPage.ets            # 注册
│   ├── SearchResultPage.ets
│   ├── SettingsPage.ets           # 设置
│   ├── aichat/                    # AI 聊天子模块
│   │   ├── ApiKeyDialog.ets
│   │   ├── ChatHeaderBar.ets
│   │   ├── ChatInputBar.ets
│   │   ├── MessageBubble.ets
│   │   ├── SuggestionCards.ets
│   │   ├── deepseek.ets
│   │   ├── tavily.ets
│   │   └── types.ets
│   ├── discover/
│   │   ├── DailyPicksPage.ets
│   │   └── TopicSquarePage.ets
│   └── mine/
│       └── EditProfilePage.ets
│
├── types/                         # 类型定义
│   └── SettingsTypes.ets
│
└── utils/                         # 工具服务
    ├── AISummaryService.ets       # AI 摘要
    ├── AliyunSMSService.ets        # 阿里云短信
    ├── BreakpointSystem.ets       # 响应式断点
    ├── ContentGenerator.ets
    ├── DraftManager.ets           # 草稿管理
    ├── HistoryManager.ets         # 历史记录
    ├── HoldingHandManager.ets
    ├── LikeManager.ets            # 点赞管理
    ├── PhotoPickerService.ets
    ├── PreferencesStorage.ets
    ├── SMSService.ets
    ├── ScanCodeService.ets
    ├── SpeechRecognitionService.ets
    └── VerifyCodeManager.ets
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
