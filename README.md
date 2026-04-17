# Haihai

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: HarmonyOS](https://img.shields.io/badge/Platform-HarmonyOS-282c37.svg)](https://www.harmonyos.com/)
[![Language: ArkTS](https://img.shields.io/badge/Language-ArkTS-4B9EE5.svg)](https://developer.huawei.com/consumer/cn/arkts/)
[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-6BA44E.svg)](https://gitee.com/haihai-app/haihai/releases)

一款基于 HarmonyOS / ArkTS 构建的社交分享应用，支持玻璃态视觉效果、AI 智能对话、多设备响应式适配。

## ✨ 特性亮点

### 🎨 视觉设计

- **玻璃态效果 (LiquidGlass)** - 毛玻璃拟物组件，支持可调模糊度、自动流光动画、触摸光效反馈、3D物理反馈倾斜效果
- **动态渐变背景** - 柔和的紫色系渐变动画，Lissajous 曲线光效漂浮
- **深色/浅色模式自适应** - 主题自动切换，全局颜色方案统一管理
- **AnimatedBackground** - 动态背景组件，提供沉浸式视觉体验
- **脉冲动画动画** - 话题引导区的呼吸光晕 + 浮动粒子效果（多层嵌套动画）
- **拖拽交互效果** - 支持拖拽偏移、缩放回弹的弹性动画（PanGesture + 动画回调）

### 📱 响应式适配

- BreakpointSystem 断点系统 - sm/md/lg/xl 四档适配
- 握持手势检测（HoldingHandManager）- 左手/右手/双手握持状态
- 多设备支持 - 手机、平板、二合一设备、可穿戴设备
- 沉浸式安全区域处理（expandSafeArea）
- 自适应布局 - 底部导航（手机）与侧边导航（平板）
- **多布局自适应** - PhoneLayout / MediumTabletLayout / LargeTabletLayout 三种布局模式
- **弹性面板系统** - 话题选择器、圈子面板、帖子详情等侧滑面板，支持平滑过渡动画

### 👥 发现模块

- **话题系统** - 话题广场、每日精选、兴趣圈子
- **热门排序** - 根据点赞 + 评论数智能排序热门话题
- **兴趣圈子** - 6 大主题圈子（科技圈/美食圈/旅行圈/摄影圈/读书圈/音乐圈）
- **圈子详情面板** - 展示成员数、帖子数、今日活跃度统计
- **圈子帖子流** - 根据圈子 ID 筛选相关帖子，支持点赞 + 详情浏览
- **话题标签筛选** - #今日灵魂拷问、#附近的人、#我的年度总结、#周末去哪儿等热门标签
- **空状态引导** - 未添加话题时展示脉冲动画 + 拖拽交互引导
- **帖子详情页** - 支持图片展示、AI 摘要生成、点赞动画、评论展示
- **AI 摘要生成** - 帖子详情页内生成智能摘要，支持加载/成功/错误状态切换
- **帖子详情面板** - 支持手机/平板两种面板样式（底部弹出 / 右侧滑入）

### 📝 内容发布

- 图文内容发布，支持相册/相机图片选择（PhotoPickerService）
- 本地草稿自动保存（DraftManager）
- 发布菜单组件（PublishMenu）

### 🔍 智能搜索

- 综合搜索 - 全部/用户/分类筛选
- Kepler AI 总结 - 搜索结果智能摘要（基于 DeepSeek）
- 瀑布流展示 + 骨架屏加载（SearchLoadingSkeleton）
- 搜索历史/热搜/搜索发现
- 语音搜索输入（VoiceInputDialog + SpeechRecognitionService）
- 搜索建议（实时联想）

### 🤖 AI 聊天

- DeepSeek 对话 - AI 智能对话（支持推理模式）
- Tavily 搜索增强 - 实时网络搜索
- 语音输入 + 对话建议卡片
- AI Summary 服务（AISummaryService）
- API Key 配置管理
- 聊天记录持久化存储

### 👤 用户中心

- 个人资料管理（EditProfilePage）
- 浏览历史（HistoryManager）
- 我的草稿（MyDraftsPanel）
- 我的收藏/点赞（MyLikesPanel、LikeManager）
- 深色模式切换（DarkModeSettingsPanel）
- 存储清理（StorageCleanPanel）
- 账户设置（AccountSettingsPanel）

### ⚙️ 设置系统

- 隐私设置（PrivacySettingsPanel）
- 安全设置（SecurityPanels）
- 通知设置（NotificationPanels）
- 通知偏好设置（LiquidGlassSettingsPanel）
- 个人资料编辑面板（EditProfilePanel）

### 🔐 认证系统

- 手机号 + 验证码登录 / 手机号 + 密码登录
- 滑块验证码 - 注册/敏感操作防护（SliderCaptcha）
- 开发者模式 - 快速进入应用（密码 `114514`）
- 用户协议与隐私政策弹窗（AgreementDialog）

## 📦 安装

### 环境要求

- HarmonyOS SDK 4.0+
- DevEco Studio 4.0+
- Node.js 18+

### 构建步骤

```bash
# 1. 克隆项目
git clone https://gitee.com/haihai-app/haihai.git
cd haihai

# 2. 使用 DevEco Studio 打开项目

# 3. 同步依赖
# DevEco Studio 会自动同步依赖，等待同步完成

# 4. 运行应用
# - 连接设备或启动模拟器
# - 点击 Run 按钮或使用快捷键 Shift + F10
```

### 构建 APK

```bash
# 在 DevEco Studio 中
# Build -> Build Hap(s) -> All Modules
# 生成的 APK 文件位于 build/outputs/hap/ 目录
```

## 🏗️ 项目结构

```
entry/src/main/ets/
├── components/                         # UI 组件库
│   ├── common/                        # 通用组件
│   │   ├── AnimatedBackground.ets     # 动态背景
│   │   ├── LiquidGlass.ets           # 玻璃态组件
│   │   ├── MineSidebar.ets           # 侧边栏
│   │   ├── PageHeader.ets            # 页面头部
│   │   ├── PublishMenu.ets           # 发布菜单
│   │   └── SliderCaptcha.ets         # 滑块验证
│   ├── dialogs/                       # 对话框组件
│   │   ├── AgreementDialog.ets       # 协议对话框
│   │   ├── SliderCaptchaDialog.ets  # 滑块验证对话框
│   │   └── VoiceInputDialog.ets     # 语音输入对话框
│   ├── discover/                      # 发现页组件
│   │   └── DiscoverComponent.ets
│   ├── home/                          # 首页组件
│   │   └── HomeComponent.ets
│   ├── message/                       # 消息组件
│   │   ├── AccountSettingsPanel.ets  # 账户设置面板
│   │   └── MessageComponent.ets
│   ├── mine/                          # "我的"页面组件
│   │   ├── DarkModeSettingsPanel.ets # 深色模式设置
│   │   ├── MineComponent.ets
│   │   ├── MyDraftsPanel.ets         # 我的草稿
│   │   ├── MyHistoryPanel.ets        # 浏览历史
│   │   ├── MyLikesPanel.ets          # 我的收藏
│   │   └── StorageCleanPanel.ets     # 存储清理
│   ├── search/                        # 搜索组件
│   │   ├── SearchPage.ets            # 搜索主页
│   │   └── search_result/            # 搜索结果视图
│   │       ├── AllResultsView.ets     # 全部结果
│   │       ├── KeplerResultView.ets  # Kepler总结
│   │       ├── PostWaterFlow.ets     # 瀑布流
│   │       ├── SearchLoadingSkeleton.ets # 骨架屏
│   │       └── UserResultsView.ets    # 用户结果
│   └── settings/                      # 设置相关组件
│       ├── EditProfilePanel.ets       # 编辑资料
│       ├── LiquidGlassSettingsPanel.ets # 玻璃设置
│       ├── NotificationPanels.ets     # 通知设置
│       ├── PrivacySettingsPanel.ets   # 隐私设置
│       ├── SecurityPanels.ets         # 安全设置
│       └── SettingItemBuilders.ets   # 设置项构建器
│
├── entryability/                      # 应用入口 Ability
│   └── EntryAbility.ets
├── entrybackupability/                # 备份能力
│   └── EntryBackupAbility.ets
├── model/                             # 数据模型层
│   ├── AppStatistics.ets             # 应用统计
│   ├── Post.ets                      # 帖子模型（含评论生成器）
│   ├── SearchData.ets                # 搜索数据
│   ├── SidebarItemModel.ets          # 侧边栏模型
│   ├── User.ets                      # 用户模型
│   ├── UserModel.ets                 # 用户管理（基于 preferences）
│   ├── commentGenerator.ets          # 评论生成器（API 响应接口）
│   └── commentTemplates.ets          # 评论模板（预设评论内容）
├── pages/                             # 页面
│   ├── AIChatPage.ets                # AI 聊天主页
│   ├── ChatDetailPage.ets           # 聊天详情
│   ├── ChatSplitPage.ets             # 分屏聊天
│   ├── CreatePostPage.ets           # 创建帖子
│   ├── Index.ets                     # 首页
│   ├── LoginPage.ets                 # 登录页
│   ├── PostDetailPage.ets           # 帖子详情
│   ├── RegisterPage.ets              # 注册页
│   ├── SearchResultPage.ets         # 搜索结果页
│   ├── SettingsPage.ets              # 设置页
│   ├── aichat/                       # AI 聊天子模块
│   │   ├── ApiKeyDialog.ets         # API密钥对话框
│   │   ├── ChatHeaderBar.ets        # 聊天头部
│   │   ├── ChatInputBar.ets         # 聊天输入栏
│   │   ├── MessageBubble.ets        # 消息气泡
│   │   ├── SuggestionCards.ets      # 建议卡片
│   │   ├── deepseek.ets             # DeepSeek服务
│   │   ├── storage.ets               # 聊天存储
│   │   ├── tavily.ets               # Tavily搜索
│   │   └── types.ets                # 类型定义
│   ├── discover/                      # 发现子模块
│   │   ├── DailyPicksPage.ets       # 每日精选
│   │   └── TopicSquarePage.ets       # 话题广场
│   └── mine/                          # "我的"子模块
│       └── EditProfilePage.ets       # 编辑资料页
│
├── types/                             # 类型定义
│   └── SettingsTypes.ets
└── utils/                             # 工具服务层
    ├── AISummaryService.ets          # AI摘要服务
    ├── AliyunSMSService.ets          # 阿里云短信
    ├── BreakpointSystem.ets           # 断点系统
    ├── ContentGenerator.ets          # 内容生成器
    ├── DraftManager.ets              # 草稿管理
    ├── HistoryManager.ets            # 历史管理
    ├── HoldingHandManager.ets        # 握持管理
    ├── LikeManager.ets               # 点赞管理
    ├── PhotoPickerService.ets        # 图片选择器
    ├── PreferencesStorage.ets         # 偏好存储
    ├── SMSService.ets                # 短信服务
    ├── ScanCodeService.ets           # 扫码服务
    ├── SpeechRecognitionService.ets   # 语音识别
    └── VerifyCodeManager.ets          # 验证码管理
```

## 🧩 功能模块

| 模块 | 说明 |
|-----|------|
| 首页 (Index) | 底部 Tab 主入口，响应式布局，支持手机/平板自适应 |
| 发现 (Discover) | 内容发现、话题广场、每日精选、兴趣圈子、帖子详情、AI 摘要 |
| 消息 (Message) | 通知、评论、点赞消息、账户设置 |
| 我的 (Mine) | 个人中心、浏览历史、草稿箱、收藏、存储清理、侧边栏导航 |
| AI 聊天 (AIChat) | DeepSeek/Tavily AI 对话、语音输入、API 配置、分屏聊天 |
| 搜索 (Search) | 综合搜索、分类展示、Kepler AI 总结、语音搜索、搜索结果瀑布流 |
| 设置 (Settings) | 隐私设置、安全设置、通知设置、资料编辑 |
| 登录/注册 | 手机号登录、滑块验证码、用户协议、开发者模式 |

## 🔧 技术栈

| 分类 | 技术 |
|-----|------|
| 框架 | HarmonyOS SDK |
| 语言 | ArkTS (TypeScript) |
| UI | 自定义组件 + 玻璃态效果 (LiquidGlass) |
| AI 服务 | DeepSeek API / Tavily Search API / AISummaryService |
| 存储 | PreferencesStorage / 本地草稿箱 / 聊天记录存储 |
| 响应式 | BreakpointSystem 多设备适配 (sm/md/lg/xl) |
| 手势 | HoldingHandManager 握持检测 / PanGesture 拖拽手势 |
| 动画 | ArkUI 动画系统 + 曲线动画 + 脉冲动画 + 弹性回弹 |
| 安全 | 滑块验证码、短信验证码、密码验证 |
| 图片 | PhotoPickerService 图片选择器 |
| 语音 | SpeechRecognitionService 语音识别 |

## 🔑 权限说明

| 权限 | 用途 |
|-----|------|
| `ohos.permission.INTERNET` | 网络访问 |
| `ohos.permission.MICROPHONE` | 麦克风（语音输入） |
| `ohos.permission.CAMERA` | 相机（拍照发布） |
| `ohos.permission.DETECT_GESTURE` | 手势检测（握持状态） |

## 🛠️ 开发者模式

为方便开发调试，应用提供了临时开发者模式：

### 启用方法

1. 打开 `entry/src/main/ets/pages/LoginPage.ets`
2. 找到第 10-15 行：
   ```typescript
   // ==================== 开发者模式入口 ====================
   const DEV_MODE_ENABLED = true;
   const DEV_MODE_HIDDEN_PASSWORD = '114514';
   // =====================================================
   ```
3. 将 `DEV_MODE_ENABLED` 改为 `true`

### 使用方法

1. 启用开发者模式后，重启应用
2. 在登录页面切换到**密码登录**模式
3. 在密码框输入 `114514`
4. 点击登录，直接进入应用

### 特性

- **临时有效**：重启应用后需重新输入密码
- **不影响正式用户**：正常登录流程不变
- **模拟用户数据**：以"开发者"身份（等级 99）进入应用

## 📊 代码统计

| 目录 | 文件数 | 说明 |
|-----|-------|------|
| 组件 (components) | 31 | 包含通用、对话框、各业务模块组件 |
| 页面 (pages) | 22 | 主页面及子模块页面（含 AI 聊天/发现/我的子模块） |
| 模型 (model) | 8 | 数据模型层、评论生成器、用户管理 |
| 工具 (utils) | 14 | 服务层工具类（AI/语音/图片/历史/草稿等） |
| 类型 (types) | 1 | TypeScript 类型定义 |
| 其他 | 2 | 入口Ability、备份Ability |
| **总计** | **78** | **核心业务代码模块** |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 提交 Issue

- 🐛 发现 Bug？请提交 [Issue](https://gitee.com/haihai-app/haihai/issues)
- 💡 有新功能建议？请提交 [Issue](https://gitee.com/haihai-app/haihai/issues)
- ❓ 有问题需要帮助？请提交 [Issue](https://gitee.com/haihai-app/haihai/issues)

### 提交 Pull Request

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 🔒 安全政策

如果您发现任何安全漏洞，请通过以下方式联系：

- 📧 发送邮件至：chr114514chr@gmail.com
- 🐞 请勿在公开的 Issue 中提交安全漏洞

## 📧 联系我们

- 🌐 网站：https://www.haihai.app(待定)
- 📮 邮箱：chr114514chr@gmail.com
- 🐞 问题反馈：[Issues](https://gitee.com/haihai-app/haihai/issues)

## 📝 应用信息

| 属性 | 值 |
|-----|-----|
| 包名 | com.haihai.app |
| 版本 | 1.0.0 |
| 平台 | HarmonyOS |
| 设备支持 | 手机、平板、二合一设备、可穿戴设备 |
