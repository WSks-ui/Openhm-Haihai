# Haihai

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: HarmonyOS](https://img.shields.io/badge/Platform-HarmonyOS-282c37.svg)](https://www.harmonyos.com/)
[![Language: ArkTS](https://img.shields.io/badge/Language-ArkTS-4B9EE5.svg)](https://developer.huawei.com/consumer/cn/arkts/)
[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-6BA44E.svg)](https://gitee.com/haihai-app/haihai/releases)

一款基于 HarmonyOS / ArkTS 构建的社交分享应用，支持玻璃态视觉效果、AI 智能对话、多设备响应式适配。

## ✨ 特性亮点

### 🎨 视觉设计
- **玻璃态效果 (LiquidGlass)** - 毛玻璃拟物组件，支持可调模糊度、自动流光动画、触摸光效反馈
- **动态渐变背景** - 柔和的紫色系渐变动画
- **深色/浅色模式自适应** - 主题自动切换

### 🔐 认证系统
- 手机号 + 验证码登录 / 手机号 + 密码登录
- 滑块验证码 - 注册/敏感操作防护
- 开发者模式 - 快速进入应用（临时会话）

### 📝 内容发布
- 图文内容发布，支持相册/相机图片选择
- 本地草稿自动保存

### 🔍 智能搜索
- 综合搜索 - 全部/用户/内容分类
- Kepler AI 总结 - 搜索结果智能摘要
- 瀑布流展示 + 骨架屏加载

### 🤖 AI 聊天
- DeepSeek 对话 - AI 智能对话
- Tavily 搜索增强 - 实时网络搜索
- 语音输入 + 对话建议卡片

### 👤 用户中心
- 个人资料管理、浏览历史、我的草稿、我的收藏
- 深色模式切换、存储清理

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
│   ├── common/                         # 通用组件
│   │   ├── AnimatedBackground.ets     # 动态背景
│   │   ├── LiquidGlass.ets            # 玻璃态组件
│   │   ├── MineSidebar.ets            # 侧边栏
│   │   ├── PageHeader.ets             # 页面头部
│   │   ├── PublishMenu.ets            # 发布菜单
│   │   └── SliderCaptcha.ets           # 滑块验证
│   ├── dialogs/                        # 对话框组件
│   │   ├── AgreementDialog.ets         # 协议对话框
│   │   ├── SliderCaptchaDialog.ets    # 滑块验证对话框
│   │   └── VoiceInputDialog.ets       # 语音输入对话框
│   ├── discover/                       # 发现页组件
│   ├── home/                           # 首页组件
│   ├── message/                        # 消息组件
│   ├── mine/                           # "我的"页面组件
│   ├── search/                         # 搜索组件
│   └── settings/                       # 设置相关组件
│
├── entryability/                       # 应用入口 Ability
├── model/                              # 数据模型层
├── pages/                              # 页面
│   ├── AIChatPage.ets                  # AI 聊天主页
│   ├── ChatDetailPage.ets             # 聊天详情
│   ├── CreatePostPage.ets             # 创建帖子
│   ├── Index.ets                       # 首页
│   ├── LoginPage.ets                   # 登录页
│   ├── PostDetailPage.ets             # 帖子详情
│   ├── RegisterPage.ets                # 注册页
│   ├── SearchResultPage.ets           # 搜索结果页
│   ├── SettingsPage.ets                # 设置页
│   ├── aichat/                         # AI 聊天子模块
│   ├── discover/                       # 发现子模块
│   └── mine/                           # "我的"子模块
│
├── types/                              # 类型定义
└── utils/                              # 工具服务层
```

## 🧩 功能模块

| 模块 | 说明 |
|-----|-----|
| 首页 (Index) | 底部 Tab 主入口，响应式布局 |
| 发现 (Discover) | 内容发现、话题广场、每日精选 |
| 消息 (Message) | 通知、评论、点赞消息 |
| 我的 (Mine) | 个人中心、设置、草稿箱、历史、收藏 |
| AI 聊天 (AIChat) | DeepSeek / Tavily AI 对话 |
| 搜索 (Search) | 综合搜索、分类展示、Kepler AI 总结 |

## 🔧 技术栈

| 分类 | 技术 |
|-----|-----|
| 框架 | HarmonyOS SDK |
| 语言 | ArkTS (TypeScript) |
| UI | 自定义组件 + 玻璃态效果 (LiquidGlass) |
| AI 服务 | DeepSeek API / Tavily Search API |
| 存储 | PreferencesStorage / 本地草稿箱 |
| 响应式 | BreakpointSystem 多设备适配 |

## 🔑 权限说明

| 权限 | 用途 |
|-----|-----|
| `ohos.permission.INTERNET` | 网络访问 |
| `ohos.permission.MICROPHONE` | 麦克风（语音输入） |
| `ohos.permission.CAMERA` | 相机（拍照发布） |
| `ohos.permission.DETECT_GESTURE` | 手势检测 |

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

| 目录 | 文件数 | 行数 |
|-----|-------|-----|
| 组件 (components) | 31 | 8,564 |
| 页面 (pages) | 22 | 10,000+ |
| 模型 (model) | 8 | ~1,000 |
| 工具 (utils) | 14 | ~2,500 |
| 其他 | 4 | ~300 |
| **总计** | **78** | **20,367** |

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

- 📧 发送邮件至：chr114614chr@gmail.com
- 🐞 请勿在公开的 Issue 中提交安全漏洞

## 📧 联系我们

- 🌐 网站：https://www.haihai.app(待定)
- 📮 邮箱：chr114614chr@gmail.com
- 🐞 问题反馈：[Issues](https://gitee.com/haihai-app/haihai/issues)

## 📝 应用信息

| 属性 | 值 |
|-----|-----|
| 包名 | com.haihai.app |
| 版本 | 1.0.0 |
| 平台 | HarmonyOS |
| 设备支持 | 手机、平板、二合一设备、可穿戴设备 |
