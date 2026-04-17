# Haihai 代码维基 (Code Wiki)

## 目录

- [项目概述](#项目概述)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [核心模块说明](#核心模块说明)
  - [入口模块](#入口模块)
  - [组件库](#组件库)
  - [页面模块](#页面模块)
  - [数据模型](#数据模型)
  - [工具服务](#工具服务)
- [核心功能详解](#核心功能详解)
  - [响应式布局系统](#响应式布局系统)
  - [玻璃态组件 (LiquidGlass)](#玻璃态组件-liquidglass)
  - [AI聊天系统](#ai聊天系统)
  - [用户认证系统](#用户认证系统)
  - [内容发布系统](#内容发布系统)
- [运行指南](#运行指南)

---

## 项目概述

Haihai 是一款基于 HarmonyOS / ArkTS 构建的社交分享应用，提供玻璃态视觉效果、AI 智能对话、多设备响应式适配等特性。

**主要特性：**
- 🎨 玻璃态视觉设计 (LiquidGlass)
- 🤖 DeepSeek / Tavily AI 对话
- 📱 多设备响应式适配 (BreakpointSystem)
- 🔐 安全认证系统 (短信验证码、滑块验证码)
- 📝 内容发布与管理
- 🔍 智能搜索与 AI 总结
- 👤 用户中心与设置系统

---

## 技术栈

| 分类 | 技术 |
|-----|------|
| 框架 | HarmonyOS SDK 6.0+ |
| 语言 | ArkTS (TypeScript) |
| UI | 自定义组件 + 玻璃态效果 (LiquidGlass) |
| AI 服务 | DeepSeek API / Tavily Search API |
| 存储 | PreferencesStorage / 本地草稿箱 |
| 响应式 | BreakpointSystem 多设备适配 |
| 手势 | HoldingHandManager 握持检测 |
| 动画 | ArkUI 动画系统 + 曲线动画 |

---

## 项目结构

```
Openhm-Haihai/
├── AppScope/                          # 应用级配置
│   ├── app.json5                      # 应用配置文件
│   └── resources/                     # 应用级资源
├── entry/                              # 主模块
│   ├── src/main/ets/
│   │   ├── components/                 # UI 组件库
│   │   │   ├── common/                # 通用组件
│   │   │   ├── dialogs/               # 对话框组件
│   │   │   ├── discover/              # 发现页组件
│   │   │   ├── home/                  # 首页组件
│   │   │   ├── message/               # 消息组件
│   │   │   ├── mine/                  # "我的"页面组件
│   │   │   ├── search/                # 搜索组件
│   │   │   └── settings/              # 设置相关组件
│   │   ├── entryability/              # 应用入口 Ability
│   │   ├── model/                     # 数据模型层
│   │   ├── pages/                     # 页面
│   │   ├── types/                     # 类型定义
│   │   └── utils/                     # 工具服务层
│   └── build-profile.json5            # 模块构建配置
├── hvigor/                             # 构建工具配置
├── oh-package.json5                    # 项目依赖
└── build-profile.json5                 # 项目构建配置
```

---

## 核心模块说明

### 入口模块

#### [EntryAbility.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/entryability/EntryAbility.ets)
应用入口 Ability，负责：
- 沉浸式效果实现 (setWindowLayoutFullScreen)
- 系统栏隐藏/显示控制
- 安全区域获取与存储
- 颜色模式初始化
- 断点系统初始化

**关键方法：**
- `setupImmersiveMode()`: 设置沉浸式全屏效果
- `updateSafeAreaInsets()`: 更新安全区域信息
- `hideSystemBars()` / `showSystemBars()`: 控制系统栏显示
- `getInitialBreakpoint()`: 获取初始响应式断点

### 组件库

#### [LiquidGlass.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/components/common/LiquidGlass.ets)
玻璃态视觉组件，提供：
- 可调模糊度的毛玻璃效果
- 自动流光动画
- 触摸光效反馈
- 3D 物理反馈倾斜效果

**主要属性：**
- `glassOpacity`: 玻璃透明度 (0.2-0.6)
- `blurRadius`: 模糊半径
- `glassRadius`: 圆角半径
- `showBorder`: 是否显示边框

**交互特性：**
- 触摸时显示跟随手指的光源
- 3D 倾斜效果
- 闲置时光源自动做椭圆运动

#### [BreakpointSystem.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/utils/BreakpointSystem.ets)
响应式断点系统，定义四个断点：

| 断点 | 宽度范围 | 设备类型 |
|-----|----------|---------|
| sm | 320vp ≤ width < 600vp | 手机 (小屏) |
| md | 600vp ≤ width < 840vp | 手机 (大屏) / 小平板 |
| lg | 840vp ≤ width < 1200vp | 平板 |
| xl | 1200vp ≤ width | 大屏平板 / 二合一设备 |

**使用方式：**
```typescript
const breakpointSystem = new BreakpointSystem();
breakpointSystem.register(); // 注册监听
// 通过 @StorageProp('currentBreakpoint') 获取当前断点
```

### 页面模块

#### [Index.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/pages/Index.ets)
应用主页面，包含：
- 底部导航 (手机模式) / 侧边导航 (平板模式)
- 动态渐变背景
- 握持手势浮动面板
- 发布菜单

**响应式布局：**
- 断点 ≤ sm: 手机模式 (底部导航)
- 断点 ≥ md: 平板模式 (侧边导航)

#### [AIChatPage.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/pages/AIChatPage.ets)
AI 聊天主页面，集成：
- DeepSeek 对话服务
- Tavily 搜索增强
- 语音输入
- API Key 配置

#### [LoginPage.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/pages/LoginPage.ets)
登录页面，支持：
- 手机号 + 验证码登录
- 手机号 + 密码登录
- 开发者模式 (密码 `114514`)

### 数据模型

#### [User.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/model/User.ets)
用户数据模型

```typescript
class User {
  id: string;
  username: string;
  avatar: string;
  bgImage: string;
  bio: string;
  gender: string;
  birthday: string;
}
```

#### [Post.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/model/Post.ets)
帖子数据模型

```typescript
class Post {
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
}
```

### 工具服务

#### [PreferencesStorage.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/utils/PreferencesStorage.ets)
偏好存储单例类，使用 `@ohos.data.preferences` 实现持久化存储。

**存储内容：**
- `color_mode`: 颜色模式 (深色/浅色/跟随系统)
- `grayscale_mode`: 灰度模式
- `current_user_phone`: 当前登录用户手机号

**使用方式：**
```typescript
const prefs = PreferencesStorage.getInstance();
await prefs.init(context);
await prefs.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
```

#### [DeepSeekService.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/pages/aichat/deepseek.ets)
DeepSeek AI 对话服务

**主要方法：**
- `setApiKey()`: 设置 API Key
- `sendMessage()`: 发送消息并获取回复
- `parseMessageContent()`: 解析 Markdown 格式回复

**支持的模型：**
- `deepseek-chat`: 普通对话模型
- `deepseek-reasoner`: 推理模型

---

## 核心功能详解

### 响应式布局系统

基于 BreakpointSystem 和设备类型实现多设备适配：

```
手机模式 (sm)：
┌─────────────────┐
│   内容区域      │
│                 │
│                 │
│                 │
└─────────────────┘
┌─────────────────┐
│  底部导航栏     │
└─────────────────┘

平板模式 (md/lg/xl)：
┌────┬──────────────┐
│    │              │
│侧  │   内容区域   │
│边  │              │
│导  │              │
│航  │              │
└────┴──────────────┘
```

### 玻璃态组件 (LiquidGlass)

玻璃态效果的实现原理：
1. **毛玻璃基底**: 使用 `backdropBlur` 实现背景模糊
2. **动态光源**: 使用 `radialGradient` 模拟光源跟随
3. **边缘光**: 使用半透明边框
4. **3D 物理反馈**: 使用 `rotate` 和 `scale` 实现倾斜和缩放

### AI聊天系统

架构：
```
AIChatPage
    ├── ChatHeaderBar
    ├── MessageBubble (消息列表)
    ├── ChatInputBar
    │   ├── 语音输入
    │   ├── 文本输入
    │   └── 发送按钮
    ├── SuggestionCards (建议卡片)
    └── ApiKeyDialog (API Key 配置)
```

**服务层：**
- `DeepSeekService`: DeepSeek API 调用
- `TavilyService`: 网络搜索增强
- `ChatStorage`: 聊天记录持久化

### 用户认证系统

认证流程：
1. 滑块验证码验证 (注册/敏感操作)
2. 短信验证码发送 (AliyunSMSService)
3. 用户信息保存 (UserModel)
4. 登录状态持久化 (PreferencesStorage)

### 内容发布系统

功能：
- 图文内容编辑
- 相册/相机图片选择 (PhotoPickerService)
- 本地草稿自动保存 (DraftManager)
- 帖子发布

---

## 运行指南

### 环境要求

- HarmonyOS SDK 6.0+
- DevEco Studio 4.0+
- Node.js 18+

### 构建步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/WSks-ui/Openhm-Haihai.git
   cd Openhm-Haihai
   ```

2. **打开项目**
   使用 DevEco Studio 打开项目

3. **同步依赖**
   DevEco Studio 会自动同步依赖

4. **配置签名**
   在 `build-profile.json5` 中配置签名信息

5. **运行应用**
   - 连接设备或启动模拟器
   - 点击 Run 按钮或使用快捷键 Shift + F10

### 开发者模式

为方便开发调试，应用提供开发者模式：

1. 打开 [LoginPage.ets](file:///workspace/Openhm-Haihai/entry/src/main/ets/pages/LoginPage.ets)
2. 找到 `DEV_MODE_ENABLED` 常量并设置为 `true`
3. 在登录页面切换到密码登录模式
4. 输入密码 `114514` 即可直接进入应用

---

## 许可证

MIT License
